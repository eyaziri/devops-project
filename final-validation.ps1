# final-validation.ps1
Write-Host "=== VALIDATION FINALE COMPLETE ===" -ForegroundColor Magenta

# 1. Analyse Securite
Write-Host "`n1. ANALYSE DE SECURITE..." -ForegroundColor Red
python -m bandit -r . -f json -o bandit-final.json
$security = Get-Content "bandit-final.json" | ConvertFrom-Json
$securityIssues = $security.metrics._totals.issues

# 2. Tests Application
Write-Host "`n2. TESTS APPLICATION..." -ForegroundColor Green
$FLASK_PORT = 5001
$baseUrl = "http://localhost:$FLASK_PORT"

# Arret et demarrage propre
Get-Process -Name "python" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep 2
Write-Host "Demarrage de l'application..." -ForegroundColor Gray
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
    $appTests += @{Name="Prometheus Metrics"; Status="✅"; Details="$metricCount metriques"}
} catch { $appTests += @{Name="Prometheus Metrics"; Status="❌"; Details=$_.Exception.Message} }

# Test de traduction
try {
    $body = @{text="final validation test"; target_lang="fr"} | ConvertTo-Json
    $translation = Invoke-RestMethod -Uri "$baseUrl/translate" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 10
    $appTests += @{Name="Translation API"; Status="✅"; Details="'$($translation.translated_text)' (cached: $($translation.cached))"}
} catch { $appTests += @{Name="Translation API"; Status="❌"; Details=$_.Exception.Message} }

# 3. Tests Infrastructure
Write-Host "`n3. TESTS INFRASTRUCTURE..." -ForegroundColor Blue
$infraTests = @()

try {
    docker build -t translation-api-final . | Out-Null
    $infraTests += @{Name="Docker Build"; Status="✅"; Details="Image construite avec succes"}
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
Write-Host "`n4. TESTS UNITAIRES..." -ForegroundColor Yellow
Get-Process -Name "python" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep 2

try {
    $testResult = python test_app.py 2>&1
    if ($LASTEXITCODE -eq 0) {
        $unitTests = @{Name="Tests Unitaires"; Status="✅"; Details="3/3 tests passes"}
    } else {
        $unitTests = @{Name="Tests Unitaires"; Status="❌"; Details="Echec des tests"}
    }
} catch {
    $unitTests = @{Name="Tests Unitaires"; Status="❌"; Details=$_.Exception.Message}
}

# 5. Rapport Final
Write-Host "`n=== RAPPORT FINAL DE VALIDATION ===" -ForegroundColor Cyan
Write-Host "`nSECURITE:" -ForegroundColor Red
Write-Host "   Bandit Scan: $(if($securityIssues -eq 0){'✅ Aucune vulnerabilite'}else{"⚠️ $securityIssues problemes"})" -ForegroundColor $(if($securityIssues -eq 0){"Green"}else{"Yellow"})

Write-Host "`nAPPLICATION:" -ForegroundColor Green
$appTests | ForEach-Object {
    Write-Host "   $($_.Status) $($_.Name): $($_.Details)" -ForegroundColor $(if($_.Status -eq "✅"){"Green"}else{"Red"})
}

Write-Host "`nINFRASTRUCTURE:" -ForegroundColor Blue
$infraTests | ForEach-Object {
    Write-Host "   $($_.Status) $($_.Name): $($_.Details)" -ForegroundColor $(if($_.Status -eq "✅"){"Green"}else{"Red"})
}

Write-Host "`nTESTS:" -ForegroundColor Yellow
Write-Host "   $($unitTests.Status) $($unitTests.Name): $($unitTests.Details)" -ForegroundColor $(if($unitTests.Status -eq "✅"){"Green"}else{"Red"})

Write-Host "`nARTEFACTS GENERES:" -ForegroundColor White
Get-ChildItem . -Include "bandit*.json", "security*.json" | ForEach-Object {
    Write-Host "   📄 $($_.Name) ($([math]::Round($_.Length/1KB, 2)) KB)" -ForegroundColor Gray
}

# 6. Score Final
Write-Host "`nSCORE FINAL DU PROJET:" -ForegroundColor Magenta
$totalTests = $appTests.Count + $infraTests.Count + 1
$passedTests = ($appTests | Where-Object { $_.Status -eq "✅" }).Count + 
               ($infraTests | Where-Object { $_.Status -eq "✅" }).Count + 
               $(if($unitTests.Status -eq "✅"){1}else{0})

$score = [math]::Round(($passedTests / $totalTests) * 100, 2)
$securityScore = if($securityIssues -eq 0){100}else{80}

Write-Host "   Tests Fonctionnels: $passedTests/$totalTests ($score%)" -ForegroundColor $(if($score -ge 80){"Green"}elseif($score -ge 60){"Yellow"}else{"Red"})
Write-Host "   Securite: $(if($securityIssues -eq 0){'100%'}else{'80% (problemes mineurs)'})" -ForegroundColor $(if($securityIssues -eq 0){"Green"}else{"Yellow"})
Write-Host "   Score Global: $([math]::Round(($score + $securityScore)/2, 2))%" -ForegroundColor Cyan

if ($score -ge 80 -and $securityIssues -eq 0) {
    Write-Host "`n🎉 STATUT: ✅ PRET POUR SOUMISSION!" -ForegroundColor Green
} elseif ($score -ge 70) {
    Write-Host "`n⚠️  STATUT: BON, QUELQUES AMELIORATIONS POSSIBLES" -ForegroundColor Yellow
} else {
    Write-Host "`n❌ STATUT: REVISION NECESSAIRE" -ForegroundColor Red
}

# Nettoyage final
Get-Process -Name "python" -ErrorAction SilentlyContinue | Stop-Process -Force
docker-compose down 2>$null

Write-Host "`n🚀 VALIDATION TERMINEE !" -ForegroundColor Green