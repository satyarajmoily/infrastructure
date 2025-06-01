# Infrastructure Scripts - Essential Toolkit

This directory contains the **essential scripts** for managing the AI Agent Team Platform with the new **instant deployment architecture**.

## 🚀 **Deployment Scripts (New Architecture)**

### **`deploy-code-changes.sh` ⚡**
**Instant code deployment - no building required!**

```bash
# Deploy code changes instantly (2-3 seconds)
./scripts/deploy-code-changes.sh [service|all]

# Examples
./scripts/deploy-code-changes.sh all                # All services
./scripts/deploy-code-changes.sh devops-ai-agent   # Single service
```

**Use For:**
- Python source code changes in `/src` directories
- API endpoint modifications  
- Business logic updates
- Bug fixes

**How It Works:**
- Source code mounted as volumes (not copied into images)
- Just restarts containers with new code
- Zero cache issues possible!

---

### **`deploy-dependencies.sh` 🔧**
**Dependency deployment - rebuilds base images**

```bash
# Deploy dependency changes (30-60 seconds)
./scripts/deploy-dependencies.sh [service|all]

# Examples  
./scripts/deploy-dependencies.sh market-predictor  # Single service
./scripts/deploy-dependencies.sh all               # All services
```

**Use For:**
- Changes to `requirements.txt`
- Dockerfile modifications
- System dependency updates
- Python version changes

**How It Works:**
- Rebuilds base images with `--no-cache`
- Source code remains mounted as volumes
- Only rebuilds what's needed

## 🏗️ **Platform Management Scripts**

### **`start-platform.sh` 🚀**
**Start the complete platform**

```bash
./scripts/start-platform.sh
```

**Features:**
- Starts all services in correct order
- Health checks and status monitoring  
- Service dependency management
- Monitoring stack initialization

---

### **`stop-platform.sh` 🛑**
**Stop all platform services**

```bash
./scripts/stop-platform.sh
```

**Features:**
- Graceful shutdown of all containers
- Preserves data volumes
- Clean stop without data loss

---

### **`restart-platform.sh` 🔄**
**Restart with configuration reload**

```bash
./scripts/restart-platform.sh [service|all|monitoring|ai]

# Examples
./scripts/restart-platform.sh all           # Complete restart
./scripts/restart-platform.sh monitoring    # Monitoring stack only
./scripts/restart-platform.sh ai            # AI agents only
./scripts/restart-platform.sh prometheus    # Single service
```

**Use For:**
- Configuration file changes (`.env`, `docker-compose.yml`)
- Service become unresponsive
- Force configuration reload
- Monitoring stack updates

## 🧪 **Testing & Validation**

### **`test-infrastructure.sh` 🔍**
**Test platform architecture and configuration**

```bash
./scripts/test-infrastructure.sh
```

**Validates:**
- Dockerfile architecture (multi-stage pattern)
- Volume mount configuration
- Service `.env` files
- Script permissions
- Docker Compose syntax

## 📋 **Script Usage Guide**

### **For Code Changes (Most Common)**
```bash
# 1. Edit source code in any service's src/ directory
# 2. Deploy instantly
./scripts/deploy-code-changes.sh service-name
# 3. Test changes (2-3 seconds later)
```

### **For Dependency Changes**
```bash
# 1. Edit requirements.txt or Dockerfile
# 2. Rebuild base image
./scripts/deploy-dependencies.sh service-name  
# 3. Wait for rebuild (30-60 seconds)
```

### **For Configuration Changes**
```bash
# 1. Edit .env files or docker-compose.yml
# 2. Restart with config reload
./scripts/restart-platform.sh all
# 3. Verify services are healthy
```

### **For Platform Management**
```bash
# Start platform
./scripts/start-platform.sh

# Stop platform
./scripts/stop-platform.sh

# Test everything is working
./scripts/test-infrastructure.sh
```

## 🎯 **Architecture Benefits**

### **Instant Code Deployment**
- ✅ **Zero Cache Issues**: Source code never cached in images
- ✅ **2-3 Second Deployment**: Just restart containers
- ✅ **No Build Required**: For source code changes
- ✅ **Live Updates**: Changes reflected immediately

### **Efficient Dependency Management**  
- ✅ **Smart Rebuilds**: Only when dependencies change
- ✅ **No Cache Problems**: Force rebuild with `--no-cache`
- ✅ **Separate Concerns**: Dependencies vs source code
- ✅ **Faster Development**: Most changes don't require rebuilds

### **Production Ready**
- ✅ **Same Architecture**: Development and production identical
- ✅ **Git-Based Rollbacks**: Instant rollbacks via container restart
- ✅ **Resource Efficient**: Minimal image sizes
- ✅ **Scalable Pattern**: Easy to add new services

## 🗑️ **Removed Scripts (Obsolete)**

The following scripts were removed during cleanup as they're no longer needed:

- `deploy-single-source-truth.sh` - One-time migration script
- `deploy-config-fix.sh` - One-time configuration fix  
- `setup-centralized-config.sh` - One-time setup script
- `create-shared-config-lib.sh` - Complex shared config (replaced by simple `.env`)
- `start_coding_agent.py` - Individual service starter (replaced by orchestration)
- `list-repositories.sh` - Old repository management (obsolete)
- `validate-config.sh` - Old config validation (obsolete)

## 💡 **Best Practices**

1. **Use instant deployment for code changes**: `deploy-code-changes.sh`
2. **Use dependency deployment sparingly**: Only when `requirements.txt` changes
3. **Test your changes**: Run `test-infrastructure.sh` after major modifications
4. **Platform restart for config**: Use `restart-platform.sh` for `.env` or compose changes
5. **Monitor logs**: `docker logs service-name` if issues arise

---

**The scripts directory is now clean, efficient, and focused on the new instant deployment architecture!** 🎉 