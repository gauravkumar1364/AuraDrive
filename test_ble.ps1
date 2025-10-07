# BLE Test Script for AuraDrive
# This script will rebuild your app and prepare it for testing

Write-Host "================================" -ForegroundColor Cyan
Write-Host "  AuraDrive BLE Test Script" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Clean the project
Write-Host "[1/5] Cleaning project..." -ForegroundColor Yellow
flutter clean
if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Flutter clean failed!" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Project cleaned successfully" -ForegroundColor Green
Write-Host ""

# Step 2: Get dependencies
Write-Host "[2/5] Getting dependencies..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Pub get failed!" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Dependencies downloaded successfully" -ForegroundColor Green
Write-Host ""

# Step 3: Analyze code
Write-Host "[3/5] Analyzing code..." -ForegroundColor Yellow
flutter analyze --no-fatal-infos
Write-Host "✓ Code analysis completed" -ForegroundColor Green
Write-Host ""

# Step 4: Check connected devices
Write-Host "[4/5] Checking connected devices..." -ForegroundColor Yellow
flutter devices
Write-Host ""

# Step 5: Build and run
Write-Host "[5/5] Building and running app..." -ForegroundColor Yellow
Write-Host ""
Write-Host "IMPORTANT REMINDERS:" -ForegroundColor Cyan
Write-Host "  1. ✓ Enable Bluetooth on your device" -ForegroundColor White
Write-Host "  2. ✓ Enable Location/GPS on your device" -ForegroundColor White
Write-Host "  3. ✓ Grant ALL permissions when app starts" -ForegroundColor White
Write-Host "  4. ✓ Check BLE debug screen in the app" -ForegroundColor White
Write-Host ""

$response = Read-Host "Ready to run? (Y/n)"
if ($response -eq "" -or $response -eq "y" -or $response -eq "Y") {
    Write-Host "Starting app..." -ForegroundColor Yellow
    flutter run --verbose
} else {
    Write-Host "Skipping app run. Use 'flutter run' to start manually." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "================================" -ForegroundColor Cyan
Write-Host "  Testing Complete" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
