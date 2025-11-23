Write-Host "=== CORRECTION OBSERVABILITÉ ===" -ForegroundColor Red

Write-Host "`n1. Arrêt de toutes les instances Python..." -ForegroundColor Yellow
Get-Process -Name "python" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep 3

Write-Host "`n2. Vérification du code..." -ForegroundColor Yellow
if (Select-String -Path "app.py" -Pattern "prometheus_client" -Quiet) {
    Write-Host "✅ Code avec Prometheus détecté" -ForegroundColor Green
} else {
    Write-Host "❌ Ancien code détecté - besoin de mise à jour" -ForegroundColor Red
    exit
}

Write-Host "`n3. Installation des dépendances..." -ForegroundColor Yellow
pip install prometheus-client==0.20.0

Write-Host "`n4. Démarrage de l'API..." -ForegroundColor Yellow
$process = Start-Process -NoNewWindow -PassThru -FilePath "python" -ArgumentList "app.py"
Start-Sleep 5

Write-Host "`n5. Test des endpoints..." -ForegroundColor Yellow

# Test 1 - Version
try {
    $root = Invoke-RestMethod -Uri "http://localhost:5000/" -Method Get -TimeoutSec 5
    Write-Host "✅ API démarrée - Version: $($root.version)" -ForegroundColor Green
} catch {
    Write-Host "❌ API non accessible" -ForegroundColor Red
    exit
}

# Test 2 - Prometheus
try {
    $prometheus = Invoke-WebRequest -Uri "http://localhost:5000/metrics/prometheus" -Method Get -TimeoutSec 5
    Write-Host "✅ Prometheus: DISPONIBLE ($($prometheus.Content.Length) bytes)" -ForegroundColor Green
} catch {
    Write-Host "❌ Prometheus: NON DISPONIBLE" -ForegroundColor Red
}

# Test 3 - Detailed
try {
    $detailed = Invoke-RestMethod -Uri "http://localhost:5000/metrics/detailed" -Method Get -TimeoutSec 5
    Write-Host "✅ Detailed Metrics: DISPONIBLE" -ForegroundColor Green
} catch {
    Write-Host "❌ Detailed Metrics: NON DISPONIBLE" -ForegroundColor Red
}

Write-Host "`n=== CORRECTION TERMINÉE ===" -ForegroundColor Green
Write-Host "`nSi Prometheus n'est pas disponible, vérifie que:" -ForegroundColor Yellow
Write-Host "1. Le fichier app.py contient le code avec Prometheus" -ForegroundColor Yellow
Write-Host "2. Aucune erreur dans la console Python" -ForegroundColor Yellow