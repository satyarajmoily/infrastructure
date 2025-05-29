# Repository Management Guide

## 🎯 Version-Controlled Repository Configuration

For production environments and team collaboration, all repository configurations should be version controlled and reviewed through git.

## 📝 Adding Repositories (Manual Configuration)

### Step 1: Edit Configuration File
```bash
# Edit the repositories configuration file
vim config/repositories.yml
# or
code config/repositories.yml
```

### Step 2: Add Repository Configuration
```yaml
target_repositories:
  # Add your new repository here
  my-new-repo:
    github_url: "https://github.com/myorg/my-new-repo.git"
    type: "react"  # fastapi, react, nodejs, python
    port: 3001
    health_endpoint: "/health"
    metrics_endpoint: "/metrics"  # Optional
    coding_enabled: true
    monitoring_enabled: true
    auto_recovery: true
    test_command: "npm test"
    description: "My new repository description"
    added_date: "2024-01-20"
    added_by: "your-username"
```

### Step 3: Commit Changes
```bash
# Stage the configuration changes
git add config/repositories.yml

# Commit with descriptive message
git commit -m "feat: Add my-new-repo repository

- Repository: my-new-repo
- Type: react
- Port: 3001
- Features: coding + monitoring enabled"

# Push to remote
git push origin main
```

### Step 4: Apply Changes
```bash
# Restart agents to load new configuration
docker-compose restart coding-ai-agent devops-ai-agent

# Verify repository is loaded
./scripts/list-repositories.sh
```

## 🔍 Repository Configuration Options

### Repository Types
- **`fastapi`** - Python FastAPI services (port: 8000)
- **`react`** - React frontend applications (port: 3000)
- **`nodejs`** - Node.js applications (port: 3000)
- **`python`** - Generic Python applications (port: 8080)

### Required Fields
```yaml
repository-name:
  github_url: "https://github.com/org/repo.git"  # Required
  type: "fastapi"                                # Required
  port: 8000                                     # Required
  health_endpoint: "/health"                     # Required
```

### Optional Fields
```yaml
  metrics_endpoint: "/metrics"    # Prometheus metrics endpoint
  coding_enabled: true           # Allow coding-ai-agent to work on this repo
  monitoring_enabled: true       # Enable monitoring by devops-ai-agent  
  auto_recovery: true           # Enable automatic recovery actions
  test_command: "pytest"        # Command to run tests
  description: "Service desc"   # Human readable description
  added_date: "2024-01-20"     # When repository was added
  added_by: "username"         # Who added the repository
```

## 🔄 Repository Lifecycle

### Adding a Repository
1. Edit `config/repositories.yml`
2. Commit changes to git
3. Restart agents: `docker-compose restart coding-ai-agent devops-ai-agent`

### Modifying a Repository
1. Edit configuration in `config/repositories.yml`
2. Commit changes to git
3. Restart agents to apply changes

### Removing a Repository
1. Delete repository section from `config/repositories.yml`
2. Commit changes to git
3. Restart agents to apply changes

## 🎯 Best Practices

### ✅ DO:
- Always commit configuration changes to git
- Use descriptive commit messages
- Test configuration changes in development first
- Document repository purpose and requirements
- Use pull requests for team review

### ❌ DON'T:
- Add repositories without version control
- Make direct production changes without review
- Forget to restart agents after configuration changes
- Use hardcoded values instead of configuration

## 🚨 Team Workflow

### For Production Environments:
1. **Create feature branch**: `git checkout -b add-new-repository`
2. **Edit configuration**: Modify `config/repositories.yml`
3. **Test locally**: Restart agents and verify
4. **Create pull request**: Submit for team review
5. **Merge after approval**: Deploy to production
6. **Apply to production**: Restart agents in production

### For Development:
1. **Edit configuration**: Direct changes to `config/repositories.yml`
2. **Commit immediately**: `git commit -m "Add development repository"`
3. **Apply changes**: `docker-compose restart coding-ai-agent devops-ai-agent`

## 📊 Verification Commands

```bash
# List all configured repositories
./scripts/list-repositories.sh

# Validate configuration
./scripts/validate-config.sh

# Check agent status
docker-compose ps

# View agent logs
docker-compose logs coding-ai-agent
docker-compose logs devops-ai-agent
``` 