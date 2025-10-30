# SQLite Expert Inference Runner Script for Windows (PowerShell)
# This script simplifies running the inference tests on RTX 4090

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "SQLite Expert Inference Test Runner" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Docker is available
try {
    $dockerVersion = docker --version 2>$null
    if (-not $dockerVersion) { throw }
} catch {
    Write-Host "ERROR: Docker not found. Please install Docker Desktop for Windows." -ForegroundColor Red
    Write-Host "Download from: https://www.docker.com/products/docker-desktop" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# Check if Docker Desktop is running
try {
    docker ps 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) { throw }
} catch {
    Write-Host "ERROR: Docker Desktop is not running." -ForegroundColor Red
    Write-Host "Please start Docker Desktop and try again." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# Check if NVIDIA GPU is available
Write-Host "Checking NVIDIA GPU availability..." -ForegroundColor Yellow
try {
    docker run --rm --gpus all nvidia/cuda:12.1.0-base-ubuntu22.04 nvidia-smi 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) { throw }
    Write-Host "✓ GPU detected and accessible" -ForegroundColor Green
} catch {
    Write-Host "ERROR: NVIDIA GPU not accessible in Docker." -ForegroundColor Red
    Write-Host ""
    Write-Host "Make sure you have:" -ForegroundColor Yellow
    Write-Host "1. Docker Desktop with WSL2 backend enabled" -ForegroundColor Yellow
    Write-Host "2. NVIDIA drivers installed" -ForegroundColor Yellow
    Write-Host "3. GPU support enabled in Docker Desktop settings" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "See WINDOWS_SETUP.md for detailed instructions." -ForegroundColor Cyan
    Read-Host "Press Enter to exit"
    exit 1
}

# Get GPU info
$gpuInfo = docker run --rm --gpus all nvidia/cuda:12.1.0-base-ubuntu22.04 nvidia-smi --query-gpu=name,memory.total --format=csv,noheader 2>$null
Write-Host $gpuInfo -ForegroundColor Green
Write-Host ""

# Create outputs directory if it doesn't exist
if (-not (Test-Path "outputs")) {
    New-Item -ItemType Directory -Path "outputs" | Out-Null
}

# Check if user wants to build
$buildFlag = ""
if ($args -contains "--build" -or $args -contains "-b") {
    Write-Host "Building Docker image..." -ForegroundColor Yellow
    $buildFlag = "--build"
}

# Run with docker-compose
Write-Host "Starting inference tests..." -ForegroundColor Cyan
Write-Host ""
docker compose up $buildFlag

# Show results
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Test Complete!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Find and display the latest result file
$latestResult = Get-ChildItem -Path "outputs" -Filter "inference_results_*.json" -ErrorAction SilentlyContinue |
                Sort-Object LastWriteTime -Descending |
                Select-Object -First 1

if ($latestResult) {
    Write-Host "Results saved to: $($latestResult.FullName)" -ForegroundColor Green
    Write-Host ""

    # Try to show summary if available
    try {
        $json = Get-Content $latestResult.FullName | ConvertFrom-Json
        Write-Host "Summary:" -ForegroundColor Cyan
        Write-Host "  Average Score: $($json.summary.avg_score)%" -ForegroundColor Yellow
        Write-Host "  Total Tests: $($json.summary.total_tests)" -ForegroundColor Yellow
        Write-Host "  Perfect Scores (100%): $($json.summary.perfect_scores)" -ForegroundColor Yellow
        Write-Host "  High Scores (80%+): $($json.summary.high_scores)" -ForegroundColor Yellow
    } catch {
        Write-Host "View results: Get-Content $($latestResult.FullName) | ConvertFrom-Json" -ForegroundColor Yellow
    }
} else {
    Write-Host "No results file found. Check docker logs for errors." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "To rebuild image: .\run_inference.ps1 --build" -ForegroundColor Cyan
Read-Host "Press Enter to exit"
