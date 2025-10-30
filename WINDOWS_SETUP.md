# Windows Setup Guide for RTX 4090

Complete guide to running SQLite Expert inference on Windows with RTX 4090.

## Prerequisites

### 1. Install NVIDIA Drivers

Download and install the latest drivers for RTX 4090:
- Go to: https://www.nvidia.com/Download/index.aspx
- Select: GeForce RTX 40 Series > RTX 4090
- Install the driver and restart

Verify installation:
```cmd
nvidia-smi
```

### 2. Install Docker Desktop for Windows

Download from: https://www.docker.com/products/docker-desktop

**Important Settings:**
1. During installation, ensure "Use WSL 2 instead of Hyper-V" is selected
2. After installation, open Docker Desktop
3. Go to Settings > General
   - Enable "Use the WSL 2 based engine"
4. Go to Settings > Resources > WSL Integration
   - Enable integration with your WSL distro (if you have one)

### 3. Enable GPU Support in Docker

Docker Desktop 4.16+ includes GPU support by default on Windows with WSL2.

Test GPU access:
```cmd
docker run --rm --gpus all nvidia/cuda:12.1.0-base-ubuntu22.04 nvidia-smi
```

If this works, you're all set!

## Quick Start

### Option 1: Using Batch Script (Easiest)

```cmd
# Clone the repository
git clone https://github.com/hkfcheung/sqlite_expert_tester.git
cd sqlite_expert_tester

# Run the tests (builds automatically on first run)
run_inference.bat --build
```

### Option 2: Using PowerShell Script

```powershell
# Clone the repository
git clone https://github.com/hkfcheung/sqlite_expert_tester.git
cd sqlite_expert_tester

# Run the tests
.\run_inference.ps1 --build
```

### Option 3: Using Docker Commands Directly

```cmd
# Build the image
docker compose build

# Run the tests
docker compose up

# Or run both in one command
docker compose up --build
```

## What Happens

The scripts will:
1. Check if Docker Desktop is running
2. Verify GPU access
3. Build the Docker container (first run only, takes 5-10 minutes)
4. Download your model from Hugging Face (~10-30 GB, first run only)
5. Run all 10 inference tests
6. Save results to `outputs\` folder

## Viewing Results

Results are saved as JSON files in the `outputs\` folder.

### Using PowerShell (Formatted)
```powershell
Get-Content outputs\inference_results_*.json | ConvertFrom-Json | ConvertTo-Json -Depth 10
```

### Using Command Prompt (Raw)
```cmd
type outputs\inference_results_*.json
```

### Using a JSON Viewer
Right-click the JSON file and open with:
- VS Code
- Notepad++
- Browser (drag and drop into Chrome/Edge)

## Troubleshooting

### Error: "Docker Desktop is not running"

**Solution:** Start Docker Desktop from the Start menu and wait for it to fully start (whale icon should be solid).

### Error: "NVIDIA GPU not accessible"

**Common causes:**

1. **WSL2 not enabled**
   - Open PowerShell as Administrator:
     ```powershell
     wsl --install
     wsl --set-default-version 2
     ```
   - Restart computer

2. **GPU support not enabled in Docker**
   - Open Docker Desktop
   - Settings > Resources > WSL Integration
   - Enable your default WSL distro
   - Apply & Restart

3. **Outdated Docker Desktop**
   - Update to Docker Desktop 4.16 or later
   - GPU support was added in 4.16+

4. **NVIDIA driver issues**
   - Update to latest NVIDIA drivers
   - Restart computer
   - Run `nvidia-smi` to verify

### Error: "docker: command not found"

**Solution:**
- Make sure Docker Desktop is installed
- Restart your terminal/command prompt
- Add Docker to PATH: `C:\Program Files\Docker\Docker\resources\bin`

### Out of Memory Error

Edit `test_inference.py`:
```python
MAX_SEQ_LENGTH = 1024  # Reduce from 2048
```

And in `run_inference()`:
```python
max_new_tokens=256  # Reduce from 512
```

Then rebuild:
```cmd
docker compose build
```

### First Run is Very Slow

This is normal! First run needs to:
1. Build Docker image (5-10 minutes)
2. Download model from Hugging Face (10-30 GB, 10-30 minutes depending on internet)

Subsequent runs are much faster (5-10 minutes total).

## Performance Expectations

On RTX 4090 with Windows + Docker + WSL2:
- **First build**: 5-10 minutes
- **Model download**: 10-30 minutes (first run only)
- **Test suite**: 5-10 minutes
- **VRAM usage**: 4-8 GB
- **Per-query inference**: 5-15 seconds

Performance is nearly identical to native Linux!

## File Locations

- **Code**: `C:\Users\YourName\path\to\sqlite_expert_tester\`
- **Results**: `C:\Users\YourName\path\to\sqlite_expert_tester\outputs\`
- **Model cache**: Inside WSL2 at `/root/.cache/huggingface/`

## Alternative: WSL2 Terminal

For a more Linux-like experience:

```bash
# Open WSL2 terminal (Ubuntu on Windows)
wsl

# Navigate to your project (from Windows filesystem)
cd /mnt/c/Users/YourName/path/to/sqlite_expert_tester

# Use Linux script
chmod +x run_inference.sh
./run_inference.sh --build
```

## Interactive Mode (Advanced)

To experiment with custom queries:

```cmd
docker run --gpus all -it ^
  -v %cd%\outputs:/app/outputs ^
  sqlite-expert-inference bash

# Inside container
python
>>> from test_inference import load_model, run_inference
>>> model, tokenizer = load_model()
>>> result = run_inference(model, tokenizer, "Your custom SQLite query prompt")
>>> print(result)
```

## Running on Different GPU

If you have multiple GPUs, specify which one:

Edit `docker-compose.yml`:
```yaml
environment:
  - CUDA_VISIBLE_DEVICES=0  # Change to 0, 1, 2, etc.
```

## Monitoring GPU Usage

While tests are running, open another terminal:

```cmd
# Watch GPU usage in real-time
nvidia-smi -l 1
```

Or use Task Manager:
- Open Task Manager (Ctrl+Shift+Esc)
- Go to Performance tab
- Select "GPU 0" to see CUDA usage

## Next Steps

After successful test run:
- Review results in `outputs\` folder
- Customize test cases in `test_inference.py`
- Add your own SQL scenarios
- Deploy as API server (see DEPLOYMENT.md)

## Common Docker Commands

```cmd
# Stop running container
docker compose down

# Rebuild after code changes
docker compose build

# View logs
docker compose logs

# Remove everything and start fresh
docker compose down --rmi all
docker system prune -a
```

## Getting Help

If you encounter issues:
1. Check Docker Desktop is running
2. Run `nvidia-smi` to verify GPU
3. Check logs: `docker compose logs`
4. Try rebuilding: `docker compose build --no-cache`

## System Requirements

- Windows 10/11 (64-bit, version 1903+)
- WSL 2
- 32 GB RAM recommended
- RTX 4090 with latest drivers
- ~50 GB free disk space (for Docker, model, and cache)
