#!/usr/bin/env python3
"""
Start script for the Coding AI Agent development environment.

This script provides an easy way to start the Coding AI Agent service
for development and testing.
"""

import subprocess
import sys
import os
import time
import signal
from pathlib import Path


def main():
    """Main startup script for the Coding AI Agent."""
    
    print("🤖 Starting Coding AI Agent - Autonomous Software Engineer")
    print("=" * 60)
    
    # Change to coding-ai-agent directory
    coding_agent_dir = Path(__file__).parent / "coding-ai-agent"
    os.chdir(coding_agent_dir)
    
    # Check if virtual environment exists
    venv_path = coding_agent_dir / "venv"
    if not venv_path.exists():
        print("📦 Creating virtual environment...")
        subprocess.run([sys.executable, "-m", "venv", "venv"], check=True)
        print("✅ Virtual environment created")
    
    # Determine the activation script based on the platform
    if sys.platform == "win32":
        activate_script = venv_path / "Scripts" / "activate"
        python_exe = venv_path / "Scripts" / "python"
        pip_exe = venv_path / "Scripts" / "pip"
    else:
        activate_script = venv_path / "bin" / "activate"
        python_exe = venv_path / "bin" / "python"
        pip_exe = venv_path / "bin" / "pip"
    
    # Install dependencies
    print("📋 Installing dependencies...")
    subprocess.run([str(pip_exe), "install", "-r", "requirements.txt"], check=True)
    print("✅ Dependencies installed")
    
    # Check for .env file
    env_file = coding_agent_dir / ".env"
    if not env_file.exists():
        print("⚠️  Warning: .env file not found!")
        print("📝 Creating .env from example...")
        
        example_env = coding_agent_dir / ".env.example"
        if example_env.exists():
            with open(example_env, 'r') as src, open(env_file, 'w') as dst:
                dst.write(src.read())
            
            print("✅ .env file created from example")
            print("\n🔧 Please edit .env and add your API keys:")
            print("   - OPENAI_API_KEY (required)")
            print("   - GITHUB_TOKEN (required)")
            print("   - GITHUB_REPOSITORY (required)")
            print("\nThen run this script again.")
            return
        else:
            print("❌ No .env.example file found")
            return
    
    # Check for required environment variables
    print("🔍 Validating environment configuration...")
    
    # Load environment variables
    try:
        from dotenv import load_dotenv
        load_dotenv(env_file)
    except ImportError:
        print("⚠️  python-dotenv not installed, using system environment")
    
    required_vars = ["OPENAI_API_KEY", "GITHUB_TOKEN", "GITHUB_REPOSITORY"]
    missing_vars = []
    
    for var in required_vars:
        if not os.getenv(var):
            missing_vars.append(var)
    
    if missing_vars:
        print(f"❌ Missing required environment variables: {', '.join(missing_vars)}")
        print("\n🔧 Please edit .env and add the missing variables:")
        for var in missing_vars:
            print(f"   - {var}")
        return
    
    print("✅ Environment configuration valid")
    
    # Run basic tests
    print("🧪 Running basic tests...")
    try:
        result = subprocess.run([
            str(python_exe), "-m", "pytest", "tests/test_main.py", "-v", "--tb=short"
        ], cwd=coding_agent_dir, capture_output=True, text=True, timeout=60)
        
        if result.returncode == 0:
            print("✅ Basic tests passed")
        else:
            print("⚠️  Some tests failed, but continuing startup...")
            print("Test output:", result.stdout[-500:] if result.stdout else "No output")
    except subprocess.TimeoutExpired:
        print("⚠️  Tests timed out, but continuing startup...")
    except Exception as e:
        print(f"⚠️  Could not run tests: {e}")
    
    # Start the service
    print("\n🚀 Starting Coding AI Agent service...")
    print("📍 Service will be available at: http://localhost:8002")
    print("📖 API documentation at: http://localhost:8002/docs")
    print("\n🛑 Press Ctrl+C to stop the service")
    print("=" * 60)
    
    try:
        # Start uvicorn with the FastAPI app
        cmd = [
            str(python_exe), "-m", "uvicorn",
            "src.coding_agent.main:app",
            "--reload",
            "--host", "0.0.0.0",
            "--port", "8002",
            "--log-level", "info"
        ]
        
        process = subprocess.Popen(cmd, cwd=coding_agent_dir)
        
        # Wait for startup
        time.sleep(3)
        
        # Test if service is running
        import requests
        try:
            response = requests.get("http://localhost:8002/health", timeout=5)
            if response.status_code == 200:
                print("✅ Coding AI Agent started successfully!")
                print("\n🎯 Ready to transform requirements into code!")
                print("\n📝 Example usage:")
                print('curl -X POST http://localhost:8002/api/v1/code \\')
                print('  -H "Content-Type: application/json" \\')
                print('  -d \'{"requirements": "Add a status endpoint", "target_service": "market-predictor"}\'')
            else:
                print(f"⚠️  Service responding with status {response.status_code}")
        except requests.RequestException as e:
            print(f"⚠️  Could not verify service startup: {e}")
        
        # Wait for the process to complete
        process.wait()
        
    except KeyboardInterrupt:
        print("\n\n🛑 Shutting down Coding AI Agent...")
        try:
            process.terminate()
            process.wait(timeout=5)
        except:
            process.kill()
        print("✅ Service stopped")
    
    except Exception as e:
        print(f"❌ Error starting service: {e}")
        return 1
    
    return 0


if __name__ == "__main__":
    exit(main())