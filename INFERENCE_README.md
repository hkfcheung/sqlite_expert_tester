# SQLite Expert Model - Inference Testing

This guide helps you test the `eeezeecee/sqlite-expert-v1` model for SQLite query generation.

## Installation

Install the required dependencies:

```bash
pip install -r requirements_inference.txt
```

Or install individually:

```bash
pip install "unsloth[colab-new] @ git+https://github.com/unslothai/unsloth.git"
pip install torch transformers trl accelerate bitsandbytes
```

## Usage

Run the inference test script:

```bash
python test_inference.py
```

## What the Script Does

The script tests your fine-tuned model on 10 different SQLite query scenarios:

1. **Basic SELECT with JOIN** - Tests simple join operations
2. **Complex aggregation with GROUP BY** - Tests aggregation functions
3. **Window functions** - Tests advanced analytics features
4. **Common Table Expressions (CTE)** - Tests WITH clause usage
5. **Subquery with EXISTS** - Tests subquery patterns
6. **Complex multi-table JOINs** - Tests multiple table joins
7. **Date/Time operations** - Tests temporal functions
8. **String manipulation** - Tests string functions
9. **CASE statements** - Tests conditional logic
10. **Recursive CTEs** - Tests recursive queries

## Evaluation Metrics

Each test is evaluated based on:
- **Score**: Percentage of expected SQL features found in the response
- **Found features**: SQL keywords/patterns successfully generated
- **Missing features**: Expected features not present in the output

The script provides:
- Individual test results
- Overall average score
- Summary statistics

## Customization

### Modify Test Cases

Edit the `TEST_CASES` list in `test_inference.py`:

```python
TEST_CASES = [
    {
        "name": "Your test name",
        "prompt": "Your custom prompt",
        "expected_features": ["SELECT", "WHERE", ...]
    },
    # Add more test cases...
]
```

### Adjust Inference Parameters

Modify these parameters in the `run_inference()` function:

```python
max_new_tokens=512,  # Maximum length of generated response
temperature=0.7,      # Creativity (0.0 = deterministic, 1.0 = creative)
top_p=0.9,           # Nucleus sampling threshold
repetition_penalty=1.1,  # Penalty for repeated tokens
```

### Model Configuration

Adjust loading parameters in the script:

```python
MAX_SEQ_LENGTH = 2048  # Maximum sequence length
LOAD_IN_4BIT = True    # Use 4-bit quantization (faster, less memory)
```

## Testing Your Own Queries

You can also test individual queries interactively:

```python
from test_inference import load_model, run_inference

model, tokenizer = load_model()
prompt = "Write a SQLite query to find all users who signed up in 2024"
result = run_inference(model, tokenizer, prompt)
print(result)
```

## Troubleshooting

**Out of Memory Error:**
- Set `LOAD_IN_4BIT = True` (already default)
- Reduce `MAX_SEQ_LENGTH`
- Reduce `max_new_tokens` in `run_inference()`

**Model Not Loading:**
- Ensure your Hugging Face model is public or you're authenticated
- Run `huggingface-cli login` if needed

**Poor Results:**
- Adjust `temperature` (lower = more deterministic)
- Try different prompts or add more context
- Check if your fine-tuning prompt format matches the inference format

## Output Format

The script outputs:
```
====================
Test 1/10: Basic SELECT with JOIN
====================

Prompt: [Your prompt]

--------------------
Generated SQL:
--------------------
[Model's SQL query]

--------------------
Evaluation:
--------------------
Score: 100.0%
Found features: SELECT, JOIN, customers, orders
Missing features: None
```

## Next Steps

After running tests:
1. Review individual query outputs for correctness
2. Test queries on actual SQLite databases
3. Add custom test cases specific to your use case
4. Adjust model parameters if needed
5. Consider additional fine-tuning for weak areas
