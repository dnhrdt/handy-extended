# Cline Integration Guide for Linting System
Version: 2.00
Timestamp: 2025-07-27 21:36 CET

## Overview

This guide explains how Cline can deploy the proven Linting System (Code Quality Score: 10.00/10) across different projects. **No setup script required** - Cline can apply configurations flexibly and intelligently.

## Available Configurations

### 1. Python Projects
**Path**: `tools/linting-system/configs/python/`
**Files**:
- `.editorconfig` - Editor settings
- `.flake8` - Style checking configuration
- `.pylintrc` - Comprehensive code analysis
- `pyproject.toml` - Tool configurations (black, isort, mypy)
- `.pre-commit-config.yaml` - Git hook configuration

**Linting Tools**: black, isort, flake8, mypy, pylint, docformatter

### 2. JavaScript Projects
**Path**: `tools/linting-system/configs/javascript/`
**Files**:
- `.editorconfig` - Editor settings
- `.eslintrc.js` - ESLint configuration
- `.prettierrc` - Prettier configuration

**Linting Tools**: ESLint, Prettier

### 3. General Projects
**Path**: `tools/linting-system/configs/general/`
**Files**:
- `.editorconfig` - Universal editor settings

## Cline Integration Workflow

### Step 1: Identify Project Type
```markdown
- Python: requirements.txt, setup.py, main.py, src/ with .py files
- JavaScript: package.json, node_modules/, src/ with .js/.ts files
- General: Markdown, documentation, mixed files
```

### Step 2: Copy Configuration Files
```bash
# Example for Python project
cp tools/linting-system/configs/python/* . 2>/dev/null || true

# Example for JavaScript project
cp tools/linting-system/configs/javascript/* . 2>/dev/null || true

# Example for General project
cp tools/linting-system/configs/general/* . 2>/dev/null || true
```

### Step 3: Copy Linting Script
```bash
# Create scripts directory if not present
mkdir -p scripts

# Copy linting script
cp tools/linting-system/scripts/lint.sh scripts/
chmod +x scripts/lint.sh
```

### Step 4: Pre-commit Hooks (Recommended)

#### Option A: Git Hook Installation (Recommended)
```bash
# Install pre-commit hook that blocks commits with linting issues
echo '#!/bin/bash
./scripts/lint.sh --shellcheck --bash-lint --files "scripts tools"
LINT_EXIT_CODE=$?

if [[ "$LINT_ALLOW_COMMIT" == "1" ]]; then
    echo "LINT_ALLOW_COMMIT=1 set - allowing commit despite linting issues"
    exit 0
else
    exit $LINT_EXIT_CODE
fi' > .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit
```

**Usage**:
- **Normal commits**: Blocked if linting issues found (production-safe)
- **Emergency bypass**: `LINT_ALLOW_COMMIT=1 git commit -m "message"`

#### Option B: Pre-commit Framework (Alternative)
```bash
# Only if pre-commit framework is preferred
pre-commit install
```

**Note**: Git hooks provide more direct control and don't require additional dependencies.

### Step 5: VS Code Extensions (Recommended)

Install these extensions for real-time linting feedback:

```bash
# Install VS Code extensions (if using VS Code)
code --install-extension timonwong.shellcheck
code --install-extension foxundermoon.shell-format
code --install-extension davidanson.vscode-markdownlint
```

**Extensions provide**:
- **Real-time feedback**: Immediate error highlighting
- **Auto-formatting**: Format on save capabilities
- **Integrated linting**: No need to run scripts manually during development

### Step 6: Shellcheck Installation (For Bash Projects)

#### Windows (Git Bash)
```bash
# Direct download approach (no package manager required)
cd ~
mkdir -p bin
curl -L https://github.com/koalaman/shellcheck/releases/download/v0.10.0/shellcheck-v0.10.0.zip -o shellcheck.zip
unzip shellcheck.zip
cp shellcheck-v0.10.0/shellcheck.exe bin/
rm -rf shellcheck.zip shellcheck-v0.10.0/

# Add to PATH (add to ~/.bashrc for persistence)
export PATH="$HOME/bin:$PATH"
```

#### Linux/macOS
```bash
# Package manager installation
# Ubuntu/Debian
sudo apt-get install shellcheck

# macOS
brew install shellcheck
```

## Practical Application

### For New Projects
1. Identify project type
2. Copy corresponding configuration files
3. Install linting script
4. Ready to use immediately!

### For Existing Projects
1. Check existing linting configuration
2. Replace with proven configuration if needed
3. Add linting script
4. First linting run with `./scripts/lint.sh --all`

## Customizations

### Project-Specific Adjustments
- **Path adjustments**: Adapt paths in pyproject.toml or .flake8 to project structure
- **Add exclusions**: Exclude special folders or files
- **Tool versions**: Update tool versions in pyproject.toml if needed

### Common Adjustments
```toml
# pyproject.toml - Path adjustments
[tool.black]
include = '\.pyi?$'
exclude = '''
/(
    \.git
  | \.venv
  | build
  | dist
  | your_specific_folder
)/
'''

# .flake8 - Additional exclusions
[flake8]
exclude = 
    .git,
    __pycache__,
    .venv,
    your_specific_folder
```

## Advantages of This Method

### ✅ **Flexibility**
- No rigid scripts that fail in unexpected situations
- Cline can intelligently react to project specifics
- Easy adaptation to special requirements

### ✅ **Proven Quality**
- Configurations from project with 10.00/10 Code Quality Score
- All tools are coordinated
- Windows-optimized and tested

### ✅ **Easy Maintenance**
- Central configurations in cline-init
- Updates can be easily transferred to all projects
- No duplication of configuration files

## Troubleshooting

### Common Issues
1. **Tool not found**: `pip install black isort flake8 mypy pylint docformatter`
2. **Pre-commit errors**: `pip install pre-commit`
3. **Path problems**: Adapt paths in configuration files to project structure

### Obsidian-Sync Integration
Based on WhisperClient feedback:
```yaml
# .pre-commit-config.yaml - Correct configuration
-   repo: local
    hooks:
    -   id: obsidian-sync
        name: Sync Memory Bank to Obsidian
        entry: python tools/obsidian_sync.py
        language: system  # IMPORTANT: system, not python!
        files: ^memory-bank/
        pass_filenames: false
        always_run: false
```

## Memory Bank Integration

### Quality Tracking
```markdown
# activeContext.md - Example entry
## Recent Changes
- **Linting System**: Integrated with Code Quality Score 10.00/10
- **Tools**: black, isort, flake8, mypy, pylint configured
- **Pre-commit**: Automatic quality checks on commits
```

### Development Standards
```markdown
# systemPatterns.md - Example entry
## Code Quality Standards
- **Linting**: All commits must pass linting checks
- **Formatting**: Automatic formatting with black/prettier
- **Type Checking**: mypy for Python, TypeScript for JS projects
```

---

**Conclusion**: This method gives Cline maximum flexibility when integrating the proven linting system, without the constraints of rigid setup scripts.
