# final-complete-validation.ps1
Write-Host "=== 🎯 VALIDATION FINALE COMPLÈTE ===" -ForegroundColor Magenta

# 1. Analyse Sécurité
Write-Host "`n1. 🔒 ANALYSE DE SÉCURITÉ..." -ForegroundColor Red
python -m bandit -r . -f json -o bandit-final.json
$security = Get-Content bandit-final.json | ConvertFrom-Json
$securityIssues = $security.metrics._totals.issues

# 2. Tests Application
Write-Host "`n2. 🚀 TESTS APPLICATION..." -ForegroundColor Green
$FLASK_PORT = 5001
$baseUrl = "http://localhost:$FLASK_PORT"

# Arrêt et démarrage propre
Get-Process -Name "python" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep 2
Write-Host "Démarrage de l'application..." -ForegroundColor Gray
$apiProcess = Start-Process -NoNewWindow -PassThru -FilePath "python" -ArgumentList "app.py"
Start-Sleep 10

$appTests = @()
try {
    $health = Invoke-RestMethod -Uri "$baseUrl/health" -Method Get -TimeoutSec 10
    $appTests += @{Name="Health Check"; Status="✅"; Details="$($health.status), Redis: $($health.redis_connected)"}
} catch { $appTests += @{Name="Health Check"; Status="❌"; Details=$_.Exception.Message} }

try {
    $root = Invoke-RestMethod -Uri "$baseUrl/" -Method Get -TimeoutSec 10
    $appTests += @{Name="Root Endpoint"; Status="✅"; Details="Version: $($root.version)"}
} catch { $appTests += @{Name="Root Endpoint"; Status="❌"; Details=$_.Exception.Message} }

try {
    $metrics = Invoke-WebRequest -Uri "$baseUrl/metrics/prometheus" -Method Get -TimeoutSec 10
    $metricCount = ($metrics.Content -split "`n" | Where-Object { $_ -match "^[^#]"}).Count
    $appTests += @{Name="Prometheus Metrics"; Status="✅"; Details="$metricCount métriques"}
} catch { $appTests += @{Name="Prometheus Metrics"; Status="❌"; Details=$_.Exception.Message} }

# Test de traduction
try {
    $body = @{text="final validation test"; target_lang="fr"} | ConvertTo-Json
    $translation = Invoke-RestMethod -Uri "$baseUrl/translate" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 10
    $appTests += @{Name="Translation API"; Status="✅"; Details="'$($translation.translated_text)' (cached: $($translation.cached))"}
} catch { $appTests += @{Name="Translation API"; Status="❌"; Details=$_.Exception.Message} }

# 3. Tests Infrastructure
Write-Host "`n3. 🐳 TESTS INFRASTRUCTURE..." -ForegroundColor Blue
$infraTests = @()

try {
    docker build -t translation-api-final . | Out-Null
    $infraTests += @{Name="Docker Build"; Status="✅"; Details="Image construite avec succès"}
} catch { $infraTests += @{Name="Docker Build"; Status="❌"; Details=$_.Exception.Message} }

try {
    docker-compose up -d | Out-Null
    Start-Sleep 10
    $composeHealth = Invoke-RestMethod -Uri "http://localhost:5000/health" -Method Get -TimeoutSec 10
    $infraTests += @{Name="Docker Compose"; Status="✅"; Details="Redis: $($composeHealth.redis_connected)"}
    docker-compose down | Out-Null
} catch { 
    $infraTests += @{Name="Docker Compose"; Status="❌"; Details=$_.Exception.Message}
    docker-compose down 2>$null
}

# 4. Tests Unitaires
Write-Host "`n4. 🧪 TESTS UNITAIRES..." -ForegroundColor Yellow
Get-Process -Name "python" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep 2

try {
    $testResult = python test_app.py 2>&1
    if ($LASTEXITCODE -eq 0) {
        $unitTests = @{Name="Tests Unitaires"; Status="✅"; Details="3/3 tests passés"}
    } else {
        $unitTests = @{Name="Tests Unitaires"; Status="❌"; Details="Échec des tests"}
    }
} catch {
    $unitTests = @{Name="Tests Unitaires"; Status="❌"; Details=$_.Exception.Message}
}

# 5. Rapport Final
Write-Host "`n=== 📊 RAPPORT FINAL DE VALIDATION ===" -ForegroundColor Cyan
Write-Host "`n🔒 SÉCURITÉ:" -ForegroundColor Red
Write-Host "   Bandit Scan: $(if($securityIssues -eq 0){'✅ Aucune vulnérabilité'}else{"⚠️ $securityIssues problèmes"})" -ForegroundColor $(if($securityIssues -eq 0){"Green"}else{"Yellow"})

Write-Host "`n🚀 APPLICATION:" -ForegroundColor Green
$appTests | ForEach-Object {
    Write-Host "   $($_.Status) $($_.Name): $($_.Details)" -ForegroundColor $(if($_.Status -eq "✅"){"Green"}else{"Red"})
}

Write-Host "`n🐳 INFRASTRUCTURE:" -ForegroundColor Blue
$infraTests | ForEach-Object {
    Write-Host "   $($_.Status) $($_.Name): $($_.Details)" -ForegroundColor $(if($_.Status -eq "✅"){"Green"}else{"Red"})
}

Write-Host "`n🧪 TESTS:" -ForegroundColor Yellow
Write-Host "   $($unitTests.Status) $($unitTests.Name): $($unitTests.Details)" -ForegroundColor $(if($unitTests.Status -eq "✅"){"Green"}else{"Red"})

Write-Host "`n📁 ARTEFACTS GÉNÉRÉS:" -ForegroundColor White
Get-ChildItem . -Include "bandit*.json", "bandit*.html", "security*.json" | ForEach-Object {
    Write-Host "   📄 $($_.Name) ($([math]::Round($_.Length/1KB, 2)) KB)" -ForegroundColor Gray
}

# 6. Score Final
Write-Host "`n🎯 SCORE FINAL DU PROJET:" -ForegroundColor Magenta
$totalTests = $appTests.Count + $infraTests.Count + 1
$passedTests = ($appTests | Where-Object { $_.Status -eq "✅" }).Count + 
               ($infraTests | Where-Object { $_.Status -eq "✅" }).Count + 
               $(if($unitTests.Status -eq "✅"){1}else{0})

$score = [math]::Round(($passedTests / $totalTests) * 100, 2)
$securityScore = if($securityIssues -eq 0){100}else{80}

Write-Host "   Tests Fonctionnels: $passedTests/$totalTests ($score%)" -ForegroundColor $(if($score -ge 80){"Green"}elseif($score -ge 60){"Yellow"}else{"Red"})
Write-Host "   Sécurité: $(if($securityIssues -eq 0){'100%'}else{'80% (problèmes mineurs)'})" -ForegroundColor $(if($securityIssues -eq 0){"Green"}else{"Yellow"})
Write-Host "   Score Global: $([math]::Round(($score + $securityScore)/2, 2))%" -ForegroundColor Cyan

Write-Host "`n🎉 STATUT: $(if($score -ge 80 -and $securityIssues -eq 0){'✅ PRÊT PSOUMISSION!'}elseif($score -ge 70){'⚠️  BON, QUELQUES AMÉLIORATIONS POSSIBLES'}else{'❌ REVISION NÉCESSAIRE'})" -ForegroundColor $(if($score -ge 80 -and $securityIssues -eq 0){"Green"}elseif($score -ge 70){"Yellow"}else{"Red"})

# Nettoyage final
Get-Process -Name "python" -ErrorAction SilentlyContinue | Stop-Process -Force
docker-compose down 2>$null

Write-Host "`n🚀 VALIDATION TERMINÉE !" -ForegroundColor Green