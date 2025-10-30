@echo off
REM SQLite Expert Inference Runner Script for Windows
REM This script simplifies running the inference tests on RTX 4090

echo ==========================================
echo SQLite Expert Inference Test Runner
echo ==========================================
echo.

REM Check if Docker is available
where docker >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo ERROR: Docker not found. Please install Docker Desktop for Windows.
    echo Download from: https://www.docker.com/products/docker-desktop
    pause
    exit /b 1
)

REM Check if Docker Desktop is running
docker ps >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo ERROR: Docker Desktop is not running.
    echo Please start Docker Desktop and try again.
    pause
    exit /b 1
)

REM Check if NVIDIA GPU is available
echo Checking NVIDIA GPU availability...
docker run --rm --gpus all nvidia/cuda:12.1.0-base-ubuntu22.04 nvidia-smi >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo ERROR: NVIDIA GPU not accessible in Docker.
    echo.
    echo Make sure you have:
    echo 1. Docker Desktop with WSL2 backend enabled
    echo 2. NVIDIA drivers installed
    echo 3. GPU support enabled in Docker Desktop settings
    echo.
    echo See WINDOWS_SETUP.md for detailed instructions.
    pause
    exit /b 1
)

echo GPU detected and accessible
echo.

REM Create outputs directory if it doesn't exist
if not exist "outputs" mkdir outputs

REM Check if user wants to build
set BUILD_FLAG=
if "%1"=="--build" set BUILD_FLAG=--build
if "%1"=="-b" set BUILD_FLAG=--build

if "%BUILD_FLAG%"=="--build" (
    echo Building Docker image...
    echo.
)

REM Run with docker-compose
echo Starting inference tests...
echo.
docker compose up %BUILD_FLAG%

REM Show results
echo.
echo ==========================================
echo Test Complete!
echo ==========================================
echo.

REM Find and display the latest result file
for /f "delims=" %%i in ('dir /b /o-d outputs\inference_results_*.json 2^>nul') do (
    set LATEST_RESULT=outputs\%%i
    goto :found
)

:found
if defined LATEST_RESULT (
    echo Results saved to: %LATEST_RESULT%
    echo.
    echo View results: type %LATEST_RESULT%
    echo.
    echo To view formatted results, install jq or use a JSON viewer.
) else (
    echo No results file found. Check docker logs for errors.
)

echo.
echo To rebuild image: %~nx0 --build
pause
