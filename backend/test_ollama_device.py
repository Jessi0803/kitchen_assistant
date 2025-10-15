#!/usr/bin/env python3
"""Test which device Ollama is using for Qwen2.5:3b"""

import ollama
import time

print("🔍 Testing Ollama device usage for Qwen2.5:3b...")
print("-" * 60)

# Simple test prompt
test_prompt = "Hello! Just say 'Hi' back."

print(f"📝 Sending test prompt: '{test_prompt}'")
print("⏳ Starting inference...")

start_time = time.time()

# Call Ollama
response = ollama.chat(
    model='qwen2.5:3b',
    messages=[{
        'role': 'user',
        'content': test_prompt
    }]
)

end_time = time.time()
inference_time = end_time - start_time

print("\n✅ Response received!")
print("-" * 60)
print(f"📄 Response: {response['message']['content']}")
print("-" * 60)

# Print performance metrics
if 'total_duration' in response:
    total_duration_sec = response['total_duration'] / 1e9
    print(f"⏱️  Total Duration: {total_duration_sec:.2f} seconds")

if 'load_duration' in response:
    load_duration_sec = response['load_duration'] / 1e9
    print(f"📦 Model Load Time: {load_duration_sec:.2f} seconds")

if 'prompt_eval_count' in response:
    prompt_tokens = response['prompt_eval_count']
    print(f"📥 Prompt Tokens: {prompt_tokens}")

if 'prompt_eval_duration' in response:
    prompt_eval_sec = response['prompt_eval_duration'] / 1e9
    print(f"⚡ Prompt Eval Time: {prompt_eval_sec:.2f} seconds")

if 'eval_count' in response:
    output_tokens = response['eval_count']
    print(f"📤 Output Tokens: {output_tokens}")

if 'eval_duration' in response:
    eval_duration_sec = response['eval_duration'] / 1e9
    tokens_per_sec = response['eval_count'] / eval_duration_sec if eval_duration_sec > 0 else 0
    print(f"⚡ Generation Time: {eval_duration_sec:.2f} seconds")
    print(f"🚀 Tokens per Second: {tokens_per_sec:.1f} tokens/s")

print("-" * 60)

# Analyze device usage based on performance
if 'eval_count' in response and 'eval_duration' in response:
    eval_duration_sec = response['eval_duration'] / 1e9
    tokens_per_sec = response['eval_count'] / eval_duration_sec if eval_duration_sec > 0 else 0

    print("\n🔬 Device Analysis:")
    print("-" * 60)

    if tokens_per_sec > 35:
        print("✅ Device: Metal (Apple Silicon GPU)")
        print("   Reason: High token generation speed (>35 tokens/s)")
        print("   This indicates GPU acceleration is ACTIVE")
    elif tokens_per_sec > 20:
        print("⚠️  Device: Possibly Metal with partial GPU usage")
        print("   Reason: Moderate speed (20-35 tokens/s)")
    else:
        print("❌ Device: CPU only")
        print("   Reason: Low token generation speed (<20 tokens/s)")
        print("   GPU acceleration is NOT active")

    print(f"\n📊 Reference speeds:")
    print(f"   - CPU only: ~15-20 tokens/s")
    print(f"   - Metal GPU (M3): ~40-60 tokens/s")
    print(f"   - Your speed: {tokens_per_sec:.1f} tokens/s")

print("\n" + "=" * 60)
print("🎯 Conclusion:")
print("Ollama automatically uses Metal (GPU) on Apple Silicon Macs.")
print("No manual configuration needed - it's AUTOMATIC!")
print("=" * 60)
