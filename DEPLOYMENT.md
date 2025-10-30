# Docker Deployment Guide for RTX 4090

This guide explains how to run the SQLite Expert inference tests on your RTX 4090 GPU using Docker.

## Prerequisites

### 1. Install NVIDIA Drivers

Make sure you have NVIDIA drivers installed (version 525.x or higher):

```bash
nvidia-smi
```

You should see your RTX 4090 listed with CUDA Version 12.x or higher.

### 2. Install Docker

```bash
# Ubuntu/Debian
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
```

Log out and back in for group changes to take effect.

### 3. Install NVIDIA Container Toolkit

```bash
# Add the package repositories
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

# Install the toolkit
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit

# Configure Docker to use NVIDIA runtime
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

# Verify installation
docker run --rm --gpus all nvidia/cuda:12.1.0-base-ubuntu22.04 nvidia-smi
```

## Building and Running

### Option 1: Using Docker Compose (Recommended)

```bash
# Build the image
docker compose build

# Run the inference test
docker compose up

# View logs
docker compose logs -f

# Clean up
docker compose down
```

### Option 2: Using Docker CLI

```bash
# Build the image
docker build -t sqlite-expert-inference .

# Run the container
docker run --gpus all \
  --rm \
  -v $(pwd)/outputs:/app/outputs \
  -v ~/.cache/huggingface:/root/.cache/huggingface \
  sqlite-expert-inference

# For interactive mode (to run custom tests)
docker run --gpus all \
  --rm \
  -it \
  -v $(pwd)/outputs:/app/outputs \
  -v ~/.cache/huggingface:/root/.cache/huggingface \
  sqlite-expert-inference \
  bash
```

## Understanding the Setup

### Volume Mounts

1. **outputs**: Results are saved to `./outputs/` on your host machine
2. **huggingface cache**: Model is cached to avoid re-downloading (typically saves ~10-30 GB download)

### GPU Configuration

The container is configured to:
- Use all available NVIDIA GPUs
- Automatically detect CUDA 12.1
- Use 4-bit quantization for efficient memory usage (~4-6 GB VRAM)

## Expected Performance

On RTX 4090 (24GB VRAM):
- **Model loading**: 1-2 minutes (first run), ~30 seconds (subsequent runs)
- **Inference per query**: 5-15 seconds depending on complexity
- **Total test suite**: ~5-10 minutes
- **VRAM usage**: 4-8 GB with 4-bit quantization

## Viewing Results

Results are automatically saved to `outputs/inference_results_[timestamp].json`:

```bash
# View latest results
cat outputs/inference_results_*.json | jq '.summary'

# List all result files
ls -lh outputs/

# View specific test result
cat outputs/inference_results_*.json | jq '.results[0]'
```

## Troubleshooting

### GPU Not Detected

```bash
# Check if NVIDIA runtime is configured
docker run --rm --gpus all nvidia/cuda:12.1.0-base-ubuntu22.04 nvidia-smi

# If this fails, reinstall nvidia-container-toolkit
sudo apt-get install --reinstall nvidia-container-toolkit
sudo systemctl restart docker
```

### Out of Memory

If you get CUDA OOM errors, edit `test_inference.py`:

```python
# Reduce sequence length
MAX_SEQ_LENGTH = 1024  # Default: 2048

# Or in run_inference function
max_new_tokens=256  # Default: 512
```

Then rebuild:
```bash
docker compose build
```

### Slow First Run

First run downloads the model (~10-30 GB depending on base model). Subsequent runs use cached model.

To pre-download:
```bash
docker run --gpus all \
  -v ~/.cache/huggingface:/root/.cache/huggingface \
  sqlite-expert-inference \
  python -c "from unsloth import FastLanguageModel; FastLanguageModel.from_pretrained('eeezeecee/sqlite-expert-v1', load_in_4bit=True)"
```

### Permission Denied on outputs/

```bash
chmod 777 outputs/
```

## Running Custom Tests

### Interactive Mode

```bash
# Start container in interactive mode
docker run --gpus all -it \
  -v $(pwd)/outputs:/app/outputs \
  -v ~/.cache/huggingface:/root/.cache/huggingface \
  sqlite-expert-inference bash

# Inside container
python
>>> from test_inference import load_model, run_inference
>>> model, tokenizer = load_model()
>>> result = run_inference(model, tokenizer, "Your custom prompt here")
>>> print(result)
```

### Modify Test Cases

1. Edit `test_inference.py` on your host machine
2. Rebuild: `docker compose build`
3. Run: `docker compose up`

## Monitoring GPU Usage

While container is running:

```bash
# Watch GPU in real-time
watch -n 1 nvidia-smi

# Or use this one-liner
nvidia-smi dmon -s u
```

## Cleaning Up

```bash
# Remove container and images
docker compose down --rmi all

# Clean up old results
rm -rf outputs/inference_results_*.json

# Clear model cache (frees disk space)
rm -rf ~/.cache/huggingface/hub/models--eeezeecee--sqlite-expert-v1
```

## Production Deployment

For production inference server, consider:

1. **API Server**: Wrap inference in FastAPI/Flask
2. **Batch Processing**: Process multiple queries in batches
3. **Model Optimization**: Use TensorRT or vLLM for faster inference
4. **Load Balancing**: Use multiple containers behind nginx

Example API server addition to Dockerfile:
```dockerfile
RUN pip install fastapi uvicorn
COPY api_server.py .
CMD ["uvicorn", "api_server:app", "--host", "0.0.0.0", "--port", "8000"]
```

## Cost Comparison

Running on RTX 4090 vs Cloud:
- **RTX 4090**: One-time cost, full control, ~5 sec/query
- **AWS g5.2xlarge (A10G)**: ~$1.21/hour, similar performance
- **Lambda Labs (RTX 4090)**: ~$0.50/hour

For development and testing, local RTX 4090 is most cost-effective.
