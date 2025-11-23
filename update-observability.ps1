Write-Host "=== MISE À JOUR OBSERVABILITÉ ===" -ForegroundColor Cyan

Write-Host "`n1. Installation de Prometheus Client..." -ForegroundColor Yellow
pip install prometheus-client==0.20.0

Write-Host "`n2. Vérification des dépendances..." -ForegroundColor Yellow
python -c "import prometheus_client; print('✅ Prometheus client installé')"

Write-Host "`n3. Arrêt de l'API en cours..." -ForegroundColor Yellow
Get-Process -Name "python" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep 2

Write-Host "`n4. Démarrage de la nouvelle API..." -ForegroundColor Yellow
Start-Process -NoNewWindow -FilePath "python" -ArgumentList "app.py"

Write-Host "`n5. Attente du démarrage..." -ForegroundColor Yellow
Start-Sleep 5

Write-Host "`n6. Test des nouveaux endpoints..." -ForegroundColor Yellow
try {
    $health = Invoke-RestMethod -Uri "http://localhost:5000/health" -Method Get
    Write-Host "✅ Health Check: $($health.status)" -ForegroundColor Green
    
    $prometheus = Invoke-WebRequest -Uri "http://localhost:5000/metrics/prometheus" -Method Get
    Write-Host "✅ Prometheus Metrics: Disponible ($($prometheus.Content.Length) bytes)" -ForegroundColor Green
    
    $detailed = Invoke-RestMethod -Uri "http://localhost:5000/metrics/detailed" -Method Get
    Write-Host "✅ Detailed Metrics: Disponible" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Erreur: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== MISE À JOUR TERMINÉE ===" -ForegroundColor Cyan