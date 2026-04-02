#!/usr/bin/env python3
"""
Simple verification script to check if .env file contains the real API key.
Run this script from the backend directory to see what's in the .env file.

Usage: python3 verify_env.py
"""

import os
import sys
from pathlib import Path


def mask_key(key: str) -> str:
    """Mask API key for security - show only first 4 and last 4 characters."""
    if not key or len(key) < 12:
        return "***"
    return f"{key[:4]}...{key[-4:]}"


def main():
    backend_dir = Path(__file__).parent
    env_file_path = backend_dir / ".env"
    
    print("=" * 60)
    print("MindPal Backend - Environment Variable Verification")
    print("=" * 60)
    
    print(f"\n.env file path: {env_file_path}")
    print(f"File exists: {env_file_path.exists()}")
    
    if not env_file_path.exists():
        print("\n❌ ERROR: .env file not found!")
        print("   Copy .env.example to .env and add your API key")
        return 1
    
    # Read and show the GROQ_API_KEY line
    api_key = None
    print("\n" + "-" * 60)
    print("Raw .env file content (GROQ_API_KEY line):")
    print("-" * 60)
    
    with open(env_file_path, "r") as f:
        for line in f:
            if line.strip().startswith("GROQ_API_KEY="):
                print(f"   {line.strip()}")
                api_key = line.split("=", 1)[1].strip()
                break
    
    if api_key is None:
        print("\n❌ ERROR: GROQ_API_KEY not found in .env file!")
        return 1
    
    print(f"\nLoaded GROQ_API_KEY: {mask_key(api_key)}")
    print(f"Key length: {len(api_key)}")
    print(f"Key starts with 'gsk_': {api_key.lower().startswith('gsk_')}")
    
    # Validate
    placeholder_values = {
        "",
        "your_groq_api_key_here",
        "your-api-key-here",
        "your_groq_key_here",
        "replace_with_your_groq_api_key",
        "gsk_xxx",
    }
    
    print("\n" + "-" * 60)
    print("Validation Result:")
    print("-" * 60)
    
    if api_key.lower() in {v.lower() for v in placeholder_values}:
        print("❌ FAILED: API key is still a placeholder value!")
        print(f"   Current value: '{api_key}'")
        print("\n" + "=" * 60)
        print("ACTION REQUIRED:")
        print("=" * 60)
        print("1. Open backend/.env in your editor")
        print("2. Replace 'your_groq_api_key_here' with your actual Groq API key")
        print("3. Save the file")
        print("4. RESTART the uvicorn server (Ctrl+C and run the server again)")
        print("\nThe server needs to be restarted to pick up new .env values!")
        return 1
    else:
        print("✓ SUCCESS: Valid API key is loaded!")
        print("\nIf you're still seeing errors, restart the server.")
        return 0


if __name__ == "__main__":
    sys.exit(main())
