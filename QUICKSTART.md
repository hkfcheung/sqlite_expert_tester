# Quick Start Guide - RTX 4090

Get your SQLite Expert model inference running in 3 steps.

## Choose Your Platform

- **Windows users**: See [Windows Setup](#windows-quick-start) below
- **Linux users**: See [Linux Setup](#linux-quick-start) below

## Windows Quick Start

### Prerequisites
- RTX 4090 with NVIDIA drivers installed
- Docker Desktop for Windows (with WSL2)
- Git for Windows

**Detailed setup**: See [WINDOWS_SETUP.md](WINDOWS_SETUP.md)

### Step 1: Verify GPU Access

Open Command Prompt or PowerShell:
```cmd
nvidia-smi
```

Should show your RTX 4090.

### Step 2: Clone and Run

```cmd
git clone https://github.com/hkfcheung/sqlite_expert_tester.git
cd sqlite_expert_tester

# Option A: Using batch script (Command Prompt)
run_inference.bat --build

# Option B: Using PowerShell script
.\run_inference.ps1 --build

# Option C: Using docker compose directly
docker compose up --build
```

### Step 3: View Results

```cmd
type outputs\inference_results_*.json
```

Or open the JSON file in VS Code, Notepad++, or your browser.

---

## Linux Quick Start

### Prerequisites
- RTX 4090 with NVIDIA drivers installed
- Docker installed
- NVIDIA Container Toolkit installed

### Step 1: Verify GPU Access

```bash
nvidia-smi
```

Should show your RTX 4090.

### Step 2: Clone and Run

```bash
git clone https://github.com/hkfcheung/sqlite_expert_tester.git
cd sqlite_expert_tester

# Make script executable
chmod +x run_inference.sh

# Run inference tests
./run_inference.sh --build
```

That's it! The script will:
1. Check GPU availability
2. Build the Docker image
3. Download the model (first run only, ~10-30 GB)
4. Run all inference tests
5. Save results to `outputs/`

## Step 3: View Results

```bash
# Latest results summary
cat outputs/inference_results_*.json | jq '.summary'

# Full results
cat outputs/inference_results_*.json | jq '.'
```

## What You'll See

```
GPU Information
================================================================================
CUDA Available: Yes
CUDA Version: 12.1
Number of GPUs: 1

GPU 0: NVIDIA GeForce RTX 4090
  Memory Allocated: 0.00 GB
  Memory Reserved: 0.00 GB
  Total Memory: 24.00 GB
================================================================================

Loading model: eeezeecee/sqlite-expert-v1
...

Test 1/10: Basic SELECT with JOIN
...
Generated SQL:
...

Score: 100.0%
Found features: SELECT, JOIN, customers, orders
Missing features: None

================================================================================
SUMMARY
================================================================================

Average Score: 85.5%
Total Tests: 10
Tests with 100% score: 6
Tests with 80%+ score: 8
```

## Next Steps

- **Customize tests**: Edit `test_inference.py` and add your own test cases
- **Run interactively**: See DEPLOYMENT.md for interactive mode
- **Production deployment**: See DEPLOYMENT.md for API server setup

## Troubleshooting

### First run is slow
The model needs to download (10-30 GB). Subsequent runs are much faster.

### Out of memory
Edit `test_inference.py`:
- Set `MAX_SEQ_LENGTH = 1024` (line 14)
- Set `max_new_tokens=256` (line 38)

Then rebuild: `./run_inference.sh --build`

### Can't access GPU
Install NVIDIA Container Toolkit:
```bash
sudo apt-get install -y nvidia-container-toolkit
sudo systemctl restart docker
```

## File Structure

```
.
├── test_inference.py          # Main inference script
├── requirements_inference.txt # Python dependencies
├── Dockerfile                 # Container definition
├── docker-compose.yml         # Easy deployment
├── run_inference.sh          # Convenience script
├── outputs/                   # Results saved here
│   └── inference_results_*.json
└── DEPLOYMENT.md             # Detailed deployment guide
```

## What Gets Tested

Your model is tested on 10 different SQLite scenarios:
1. Basic SELECT with JOIN
2. Complex aggregation with GROUP BY
3. Window functions (RANK, PARTITION BY)
4. Common Table Expressions (CTEs)
5. Subqueries with EXISTS
6. Multi-table JOINs
7. Date/Time operations
8. String manipulation
9. CASE statements
10. Recursive CTEs

Each test checks if your model generates the expected SQL features and provides a score.

## Performance Expectations

On RTX 4090:
- First run: 5-15 minutes (includes model download)
- Subsequent runs: 5-10 minutes
- VRAM usage: 4-8 GB
- Per-query inference: 5-15 seconds

## Cost Savings

Running locally vs cloud:
- **Local RTX 4090**: Free after hardware purchase
- **AWS g5.2xlarge**: ~$1.21/hour
- **Lambda Labs**: ~$0.50/hour

For regular testing, local is far more economical!
