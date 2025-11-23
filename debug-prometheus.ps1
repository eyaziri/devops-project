Write-Host "=== 🔧 DÉPANNAGE PROMETHEUS ===" -ForegroundColor Red

Write-Host "`n1. Arrêt de toutes les instances..." -ForegroundColor Yellow
$processes = Get-Process -Name "python" -ErrorAction SilentlyContinue
if ($processes) {
    $processes | Stop-Process -Force
    Write-Host "✅ Processes arrêtés: $($processes.Count)" -ForegroundColor Green
} else {
    Write-Host "ℹ️ Aucun processus Python en cours" -ForegroundColor Gray
}

Start-Sleep 3

Write-Host "`n2. Vérification du code source..." -ForegroundColor Yellow
if (Test-Path "app.py") {
    $hasPrometheus = Select-String -Path "app.py" -Pattern "prometheus_client" -Quiet
    $hasRoute = Select-String -Path "app.py" -Pattern "metrics/prometheus" -Quiet
    $hasVersion = Select-String -Path "app.py" -Pattern 'version.*2.0.0' -Quiet
    
    Write-Host "📁 app.py existe" -ForegroundColor Green
    Write-Host "🔍 Prometheus import: $hasPrometheus" -ForegroundColor $(if($hasPrometheus){"Green"}else{"Red"})
    Write-Host "🔍 Route /metrics/prometheus: $hasRoute" -ForegroundColor $(if($hasRoute){"Green"}else{"Red"})
    Write-Host "🔍 Version 2.0.0: $hasVersion" -ForegroundColor $(if($hasVersion){"Green"}else{"Red"})
} else {
    Write-Host "❌ app.py n'existe pas!" -ForegroundColor Red
    exit
}

Write-Host "`n3. Démarrage de l'API..." -ForegroundColor Yellow
$apiProcess = Start-Process -NoNewWindow -PassThru -FilePath "python" -ArgumentList "app.py"
Start-Sleep 5

Write-Host "`n4. Test de la version..." -ForegroundColor Yellow
try {
    $root = Invoke-RestMethod -Uri "http://localhost:5000/" -Method Get -TimeoutSec 5
    Write-Host "🌐 API accessible" -ForegroundColor Green
    Write-Host "📋 Version: $($root.version)" -ForegroundColor Cyan
    Write-Host "🔗 Endpoints disponibles:" -ForegroundColor Cyan
    $root.endpoints.PSObject.Properties | ForEach-Object {
        Write-Host "   - $($_.Name): $($_.Value)" -ForegroundColor Gray
    }
} catch {
    Write-Host "❌ API non accessible: $($_.Exception.Message)" -ForegroundColor Red
    exit
}

Write-Host "`n5. Test Prometheus..." -ForegroundColor Yellow
try {
    $prometheus = Invoke-WebRequest -Uri "http://localhost:5000/metrics/prometheus" -Method Get -TimeoutSec 5
    Write-Host "✅ PROMETHEUS FONCTIONNE !" -ForegroundColor Green
    Write-Host "📊 Métriques: $($prometheus.Content.Length) bytes" -ForegroundColor Cyan
    
    # Affiche les premières métriques
    Write-Host "`n📈 Exemple de métriques:" -ForegroundColor Yellow
    $prometheus.Content -split "`n" | Where-Object { $_ -match "^[^#]"} | Select-Object -First 5 | ForEach-Object {
        Write-Host "   $_" -ForegroundColor Gray
    }
} catch {
    Write-Host "❌ Prometheus échoue: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== 🔧 DÉPANNAGE TERMINÉ ===" -ForegroundColor Green