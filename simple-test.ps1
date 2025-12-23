# Simple test for CSV parsing
Write-Host "Testing CSV parsing..." -ForegroundColor Green

# Check if CSV file exists
if (Test-Path "config\customer.csv") {
    Write-Host "✓ CSV file found" -ForegroundColor Green
    
    # Show CSV content
    Write-Host "`nCSV Content:" -ForegroundColor Yellow
    Import-Csv "config\customer.csv" | Format-Table -AutoSize
    
    # Test PowerShell CSV parsing
    Write-Host "`nRunning PowerShell CSV parser..." -ForegroundColor Yellow
    try {
        & ".\scripts\parse-csv.ps1" -CsvFile "config\customer.csv" -Environment "dev"
        Write-Host "✓ CSV parsing completed successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "✗ CSV parsing failed: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Check generated files
    Write-Host "`nGenerated files:" -ForegroundColor Yellow
    if (Test-Path "generated-params") {
        Get-ChildItem "generated-params" | ForEach-Object {
            Write-Host "  ✓ $($_.Name)" -ForegroundColor Green
        }
    } else {
        Write-Host "  No generated-params directory found" -ForegroundColor Red
    }
} else {
    Write-Host "✗ CSV file not found" -ForegroundColor Red
}

Write-Host "`nTest completed!" -ForegroundColor Green