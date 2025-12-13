# analyze-bandit.ps1
Write-Host "=== ANALYSE RAPPORT BANDIT ===" -ForegroundColor Cyan

if (-not (Test-Path "bandit-test.json")) {
    Write-Host "❌ Fichier bandit-test.json non trouve" -ForegroundColor Red
    exit
}

$report = Get-Content "bandit-test.json" | ConvertFrom-Json

Write-Host "`nSTATISTIQUES GLOBALES:" -ForegroundColor Yellow
$totals = $report.metrics._totals
Write-Host "✅ Lignes analysees: $($totals.loc)" -ForegroundColor Green
Write-Host "✅ Fichiers analyses: $($totals.files)" -ForegroundColor Green
Write-Host "🔍 Problemes trouves: $($totals.issues)" -ForegroundColor $(if($totals.issues -eq 0){"Green"}else{"Yellow"})

if ($totals.issues -gt 0) {
    Write-Host "`n⚠️  PROBLEMES IDENTIFIES:" -ForegroundColor Red
    
    $report.results | Group-Object issue_severity | ForEach-Object {
        $severity = $_.Name
        $count = $_.Count
        
        # Correction ici : variable $color définie proprement
        if ($severity -eq "HIGH") {
            $color = "Red"
        } elseif ($severity -eq "MEDIUM") {
            $color = "Yellow"
        } else {
            $color = "Gray"
        }
        
        # Correction ici : utilisation de la variable correctement
        Write-Host "   $($severity): $count" -ForegroundColor $color
    }
    
    Write-Host "`nDETAILS DES PROBLEMES:" -ForegroundColor Yellow
    $report.results | Select-Object -First 3 | ForEach-Object {
        Write-Host "   - $($_.issue_text)" -ForegroundColor Yellow
        Write-Host "     Fichier: $($_.filename):$($_.line_number)" -ForegroundColor Gray
        Write-Host "     Severite: $($_.issue_severity)" -ForegroundColor Gray
        Write-Host "     Confiance: $($_.issue_confidence)" -ForegroundColor Gray
        Write-Host ""
    }
} else {
    Write-Host "`n🎉 AUCUNE VULNERABILITE TROUVEE !" -ForegroundColor Green
}

Write-Host "Rapport complet: bandit-test.json" -ForegroundColor Cyan