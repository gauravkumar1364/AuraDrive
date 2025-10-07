# AuraDrive BLE Fix - Quick Rebuild Script
# Run this script to apply the BLE permission fixes

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  AuraDrive BLE Auto-Connect Fix" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Clean build
Write-Host "[1/5] Cleaning previous build..." -ForegroundColor Yellow
flutter clean
Write-Host "✓ Clean complete" -ForegroundColor Green
Write-Host ""

# Step 2: Get dependencies
Write-Host "[2/5] Getting dependencies..." -ForegroundColor Yellow
flutter pub get
Write-Host "✓ Dependencies downloaded" -ForegroundColor Green
Write-Host ""

# Step 3: Uninstall old app
Write-Host "[3/5] Uninstalling old app..." -ForegroundColor Yellow
adb uninstall com.example.project 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Old app uninstalled" -ForegroundColor Green
} else {
    Write-Host "! App not found (this is OK if first install)" -ForegroundColor Yellow
}
Write-Host ""

# Step 4: Build new APK
Write-Host "[4/5] Building debug APK..." -ForegroundColor Yellow
Write-Host "This may take a few minutes..." -ForegroundColor Gray
flutter build apk --debug
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Build successful" -ForegroundColor Green
} else {
    Write-Host "✗ Build failed" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Step 5: Install and run
Write-Host "[5/5] Installing and running..." -ForegroundColor Yellow
flutter run
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ App installed and running" -ForegroundColor Green
} else {
    Write-Host "✗ Installation failed" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "IMPORTANT: Grant ALL permissions when prompted:" -ForegroundColor Yellow
Write-Host "  ✓ Location → Allow all the time" -ForegroundColor White
Write-Host "  ✓ Bluetooth → Allow" -ForegroundColor White
Write-Host "  ✓ Nearby devices → Allow" -ForegroundColor White
Write-Host "  ✓ Notifications → Allow" -ForegroundColor White
Write-Host ""
Write-Host "Then enable:" -ForegroundColor Yellow
Write-Host "  ✓ Bluetooth in Quick Settings" -ForegroundColor White
Write-Host "  ✓ Location/GPS in Quick Settings" -ForegroundColor White
Write-Host ""
Write-Host "Check logs for:" -ForegroundColor Yellow
Write-Host '  "BLE Auto Connect: Service initialized successfully"' -ForegroundColor Green
Write-Host ""
