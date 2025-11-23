Write-Host "=== 🔒 SCAN DE SÉCURITÉ COMPLET ===" -ForegroundColor Red

Write-Host "`n1. Scan SAST avec Bandit..." -ForegroundColor Yellow
try {
    python -m bandit -r . -f html -o security-report.html
    Write-Host "✅ Rapport Bandit généré: security-report.html" -ForegroundColor Green
} catch {
    Write-Host "❌ Bandit a échoué" -ForegroundColor Red
}

Write-Host "`n2. Vérification des dépendances..." -ForegroundColor Yellow
pip list --outdated

Write-Host "`n3. Analyse de code statique..." -ForegroundColor Yellow
# Vérifie les imports dangereux
Select-String -Path "app.py" -Pattern "eval|exec|pickle|os.system" | ForEach-Object {
    Write-Host "⚠️  Pattern potentiellement dangereux: $($_.Line)" -ForegroundColor Yellow
}

Write-Host "`n4. Vérification des permissions..." -ForegroundColor Yellow
Get-ChildItem . -Recurse | Where-Object { $_.Name -match "\.(py|yml|yaml|json)$" } | ForEach-Object {
    $isReadOnly = $_.Attributes -band [System.IO.FileAttributes]::ReadOnly
    if ($isReadOnly) {
        Write-Host "🔒 $($_.Name) est en lecture seule" -ForegroundColor Green
    }
}

Write-Host "`n=== ✅ SCAN TERMINÉ ===" -ForegroundColor Green