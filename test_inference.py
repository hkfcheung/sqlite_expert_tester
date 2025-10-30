"""
SQLite Expert Model Inference Testing Script
Tests the eeezeecee/sqlite-expert-v1 model for SQLite query generation
"""

from unsloth import FastLanguageModel
import torch
import json
import os
from datetime import datetime

# Configuration
MODEL_NAME = "eeezeecee/sqlite-expert-v1"
MAX_SEQ_LENGTH = 2048
DTYPE = None  # Auto-detect
LOAD_IN_4BIT = True  # Use 4-bit quantization for faster inference

def print_gpu_info():
    """Print GPU information"""
    print("=" * 80)
    print("GPU Information")
    print("=" * 80)
    if torch.cuda.is_available():
        print(f"CUDA Available: Yes")
        print(f"CUDA Version: {torch.version.cuda}")
        print(f"Number of GPUs: {torch.cuda.device_count()}")
        for i in range(torch.cuda.device_count()):
            print(f"\nGPU {i}: {torch.cuda.get_device_name(i)}")
            print(f"  Memory Allocated: {torch.cuda.memory_allocated(i) / 1024**3:.2f} GB")
            print(f"  Memory Reserved: {torch.cuda.memory_reserved(i) / 1024**3:.2f} GB")
            print(f"  Total Memory: {torch.cuda.get_device_properties(i).total_memory / 1024**3:.2f} GB")
    else:
        print("CUDA Available: No")
        print("WARNING: Running on CPU - this will be very slow!")
    print("=" * 80)
    print()

def load_model():
    """Load the fine-tuned model from Hugging Face"""
    print(f"Loading model: {MODEL_NAME}")
    print("This may take a few minutes on first run (downloading model)...\n")

    model, tokenizer = FastLanguageModel.from_pretrained(
        model_name=MODEL_NAME,
        max_seq_length=MAX_SEQ_LENGTH,
        dtype=DTYPE,
        load_in_4bit=LOAD_IN_4BIT,
    )

    # Set model to inference mode
    FastLanguageModel.for_inference(model)
    print("Model loaded successfully!\n")

    # Print memory usage after loading
    if torch.cuda.is_available():
        print(f"GPU Memory after model load: {torch.cuda.memory_allocated(0) / 1024**3:.2f} GB")
        print()

    return model, tokenizer

def run_inference(model, tokenizer, prompt, max_new_tokens=512, temperature=0.7):
    """Run inference on a single prompt"""
    inputs = tokenizer(prompt, return_tensors="pt").to(model.device)

    with torch.no_grad():
        outputs = model.generate(
            **inputs,
            max_new_tokens=max_new_tokens,
            temperature=temperature,
            do_sample=True,
            top_p=0.9,
            repetition_penalty=1.1,
            pad_token_id=tokenizer.eos_token_id,
        )

    response = tokenizer.decode(outputs[0], skip_special_tokens=True)
    # Remove the prompt from the response
    response = response[len(prompt):].strip()

    return response

# Test cases for SQLite queries
TEST_CASES = [
    {
        "name": "Basic SELECT with JOIN",
        "prompt": "Write a SQLite query to select all customers and their orders, joining the customers and orders tables.",
        "expected_features": ["SELECT", "JOIN", "customers", "orders"]
    },
    {
        "name": "Complex aggregation with GROUP BY",
        "prompt": "Create a SQLite query to find the total sales amount per customer, grouped by customer_id, and show only customers with total sales over $1000.",
        "expected_features": ["SELECT", "SUM", "GROUP BY", "HAVING"]
    },
    {
        "name": "Window function",
        "prompt": "Write a SQLite query using window functions to rank products by sales within each category.",
        "expected_features": ["RANK()", "PARTITION BY", "OVER", "ORDER BY"]
    },
    {
        "name": "Common Table Expression (CTE)",
        "prompt": "Create a SQLite query using a CTE to find employees who earn more than the average salary in their department.",
        "expected_features": ["WITH", "AS", "SELECT", "AVG"]
    },
    {
        "name": "Subquery with EXISTS",
        "prompt": "Write a SQLite query to find all products that have at least one order, using EXISTS clause.",
        "expected_features": ["SELECT", "EXISTS", "WHERE"]
    },
    {
        "name": "Complex JOIN with multiple tables",
        "prompt": "Create a SQLite query to show customer names, their orders, and product details by joining customers, orders, and products tables.",
        "expected_features": ["SELECT", "JOIN", "customers", "orders", "products"]
    },
    {
        "name": "Date/Time operations",
        "prompt": "Write a SQLite query to find all orders placed in the last 30 days using date functions.",
        "expected_features": ["SELECT", "date", "datetime", "WHERE"]
    },
    {
        "name": "String manipulation",
        "prompt": "Create a SQLite query to concatenate first_name and last_name, and convert to uppercase.",
        "expected_features": ["SELECT", "||", "UPPER"]
    },
    {
        "name": "CASE statement",
        "prompt": "Write a SQLite query to categorize products as 'Expensive', 'Moderate', or 'Cheap' based on price using CASE.",
        "expected_features": ["SELECT", "CASE", "WHEN", "THEN", "END"]
    },
    {
        "name": "Recursive CTE",
        "prompt": "Create a recursive SQLite query to show employee hierarchy (manager-employee relationships).",
        "expected_features": ["WITH RECURSIVE", "UNION", "SELECT"]
    },
]

def evaluate_response(response, expected_features):
    """Simple evaluation based on expected SQL features"""
    response_upper = response.upper()
    found_features = []
    missing_features = []

    for feature in expected_features:
        if feature.upper() in response_upper:
            found_features.append(feature)
        else:
            missing_features.append(feature)

    score = len(found_features) / len(expected_features) * 100 if expected_features else 0

    return {
        "score": score,
        "found": found_features,
        "missing": missing_features
    }

def save_results(results, output_dir="outputs"):
    """Save results to JSON file"""
    os.makedirs(output_dir, exist_ok=True)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"{output_dir}/inference_results_{timestamp}.json"

    output_data = {
        "timestamp": timestamp,
        "model": MODEL_NAME,
        "config": {
            "max_seq_length": MAX_SEQ_LENGTH,
            "load_in_4bit": LOAD_IN_4BIT,
        },
        "results": results,
        "summary": {
            "avg_score": sum(r['evaluation']['score'] for r in results) / len(results),
            "total_tests": len(results),
            "perfect_scores": sum(1 for r in results if r['evaluation']['score'] == 100),
            "high_scores": sum(1 for r in results if r['evaluation']['score'] >= 80),
        }
    }

    with open(filename, 'w') as f:
        json.dump(output_data, f, indent=2)

    print(f"\nResults saved to: {filename}")

def main():
    """Main testing function"""
    print("=" * 80)
    print("SQLite Expert Model Inference Test")
    print("=" * 80)
    print()

    # Print GPU info
    print_gpu_info()

    # Load model
    model, tokenizer = load_model()

    # Run tests
    results = []
    for i, test_case in enumerate(TEST_CASES, 1):
        print(f"\n{'=' * 80}")
        print(f"Test {i}/{len(TEST_CASES)}: {test_case['name']}")
        print(f"{'=' * 80}")
        print(f"\nPrompt: {test_case['prompt']}")
        print(f"\n{'-' * 80}")
        print("Generated SQL:")
        print(f"{'-' * 80}")

        # Run inference
        response = run_inference(model, tokenizer, test_case['prompt'])
        print(response)

        # Evaluate
        evaluation = evaluate_response(response, test_case['expected_features'])
        print(f"\n{'-' * 80}")
        print("Evaluation:")
        print(f"{'-' * 80}")
        print(f"Score: {evaluation['score']:.1f}%")
        print(f"Found features: {', '.join(evaluation['found']) if evaluation['found'] else 'None'}")
        print(f"Missing features: {', '.join(evaluation['missing']) if evaluation['missing'] else 'None'}")

        results.append({
            "test": test_case['name'],
            "prompt": test_case['prompt'],
            "response": response,
            "evaluation": evaluation
        })

    # Print summary
    print(f"\n\n{'=' * 80}")
    print("SUMMARY")
    print(f"{'=' * 80}")
    avg_score = sum(r['evaluation']['score'] for r in results) / len(results)
    print(f"\nAverage Score: {avg_score:.1f}%")
    print(f"Total Tests: {len(results)}")
    print(f"Tests with 100% score: {sum(1 for r in results if r['evaluation']['score'] == 100)}")
    print(f"Tests with 80%+ score: {sum(1 for r in results if r['evaluation']['score'] >= 80)}")

    # Save results
    save_results(results)

    return results

if __name__ == "__main__":
    results = main()
