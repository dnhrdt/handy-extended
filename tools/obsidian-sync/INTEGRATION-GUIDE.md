# Cline Integration Guide: Git-Obsidian-Sync

A plug-and-play system for automatic synchronization of your `memory-bank` with an Obsidian Vault after every Git commit.

## 🎯 What does this tool do?

- **Automatic**: After every `git commit`, your `memory-bank/` is synchronized with your Obsidian Vault
- **Robust**: "Sync All" strategy - synchronizes all `.md` files from `memory-bank/`
- **Cross-platform**: Bash-based, works on Windows (Git Bash), Linux and macOS
- **Zero-Config**: Minimal configuration required

## 🚀 Quick Setup (4 Steps)

### 1. Create Configuration

Create a `.git-obsidian-sync.json` in your project's root directory:

```json
{
  "targetVault": "C:/Eigene Dateien/Obsidian Vault",
  "mappings": [
    {
      "source": "memory-bank/",
      "target": "Projects/PROJECTNAME/memory-bank/"
    }
  ],
  "options": {
    "addMetadata": false,
    "transformations": { "enabled": false }
  }
}
```

**Important**:

- `targetVault` must be an **absolute path** (default: `"C:/Eigene Dateien/Obsidian Vault"`)
- `source` should always be `"memory-bank/"`
- `target` follows the schema `"Projects/PROJECTNAME/memory-bank/"` - **replace PROJECTNAME!**
- `addMetadata: false` = no frontmatter headers (tested default)
- Template available: `tools/obsidian-sync/bin/config/cline-init-template.json`

### 2. Install Git Hook

```bash
# In your project's root directory
./tools/obsidian-sync/scripts/install-git-hook.sh
```

### 3. Test

```bash
# Manual test
./tools/obsidian-sync/scripts/sync-repository.sh

# Or simply make a commit
git add .
git commit -m "Test Obsidian Sync"
```

### 4. Pre-commit Integration (Optional)

For projects using pre-commit framework, add Obsidian sync to your `.pre-commit-config.yaml`:

```yaml
# .pre-commit-config.yaml - Correct configuration
repos:
  - repo: local
    hooks:
      - id: obsidian-sync
        name: Sync Memory Bank to Obsidian
        entry: python tools/obsidian_sync.py
        language: system # IMPORTANT: system, not python!
        files: ^memory-bank/
        pass_filenames: false
        always_run: false
```

**Important Notes**:

- Use `language: system` (not `python`) to avoid environment issues
- Exclude sync scripts from linting: `exclude: ^(tools/obsidian_sync.py)`
- Based on WhisperClient project feedback and testing

## 📋 Prerequisites

- **Git Bash** (Windows) or **Bash 4.0+** (Linux/macOS)
- **jq** (JSON processor)
  - Windows: Usually included in Git Bash
  - Linux: `sudo apt-get install jq`
  - macOS: `brew install jq`

## 🔧 Configuration Details

### Tested Standard Configuration (RECOMMENDED)

```json
{
  "targetVault": "C:/Eigene Dateien/Obsidian Vault",
  "mappings": [
    {
      "source": "memory-bank/",
      "target": "Projects/PROJECTNAME/memory-bank/"
    }
  ],
  "options": {
    "addMetadata": false,
    "transformations": { "enabled": false }
  }
}
```

### With Metadata (Optional)

```json
{
  "targetVault": "C:/Eigene Dateien/Obsidian Vault",
  "mappings": [
    {
      "source": "memory-bank/",
      "target": "Projects/PROJECTNAME/memory-bank/"
    }
  ],
  "options": {
    "addMetadata": true,
    "metadataTemplate": {
      "addGitMetadata": true,
      "addSyncTimestamp": true
    },
    "transformations": { "enabled": false }
  }
}
```

**⚠️ IMPORTANT**: Only replace `PROJECTNAME` with the actual project name!

## 🛠️ Troubleshooting

### Problem: "jq: command not found"

```bash
# Windows (Git Bash)
# jq is usually pre-installed, check:
which jq

# Linux
sudo apt-get install jq

# macOS
brew install jq
```

### Problem: "Configuration file not found"

- Ensure `.git-obsidian-sync.json` is in the root directory
- Use absolute paths for `targetVault`

### Problem: "Synchronization fails"

```bash
# Verbose mode for debugging
./tools/obsidian-sync/scripts/sync-repository.sh --verbose

# Check log file
cat .git-obsidian-sync.error.log
```

### Problem: Windows Paths

```json
// ✅ Correct
"targetVault": "C:/Users/Name/Documents/Obsidian/Vault"

// ❌ Wrong
"targetVault": "C:\\Users\\Name\\Documents\\Obsidian\\Vault"
```

## 📁 File Structure After Installation

```
your-project/
├── .git-obsidian-sync.json          # Your configuration
├── .git/
│   └── hooks/
│       └── post-commit               # Automatically installed
├── memory-bank/                      # Gets synchronized
│   ├── activeContext.md
│   ├── techContext.md
│   └── systemPatterns.md
└── tools/
    └── obsidian-sync/                # This tool
        ├── bin/git-obsidian-sync.sh
        ├── scripts/install-git-hook.sh
        └── scripts/sync-repository.sh
```

## 🔄 How it works

1. **Commit**: You make a `git commit`
2. **Hook**: The `post-commit` hook is automatically executed
3. **Sync**: All `.md` files from `memory-bank/` are copied to your Obsidian Vault
4. **Metadata**: Optionally, Git commit information is added

## 📝 Best Practices

### Memory Bank Structure

```
memory-bank/
├── activeContext.md      # Current session info
├── techContext.md        # Technical details
├── systemPatterns.md     # Development patterns
└── archive/              # Also synchronized
    └── old-sessions/
```

### Obsidian Vault Organization

```
MyVault/
├── Projects/
│   ├── project1/         # Mapping target
│   │   └── memory-bank/
│   │       ├── activeContext.md
│   │       ├── techContext.md
│   │       └── systemPatterns.md
│   └── project2/
└── Templates/
```

## 🚨 Important Notes

- **Memory Bank (default)**: By default, the example synchronizes ONLY `memory-bank/`. You can add additional mappings in `.git-obsidian-sync.json` if needed.
- **Overwrites Files**: Existing files in the vault will be overwritten
- **Absolute Path**: `targetVault` must always be absolute
- **Git Bash**: On Windows, use Git Bash, not PowerShell

## 📞 Support

For issues:

1. Check prerequisites (jq, Bash)
2. Use `--verbose` for detailed logs
3. Check `.git-obsidian-sync.error.log`
4. Ensure all paths are absolute

---

**Version**: 2.1
**Compatibility**: Windows (Git Bash), Linux, macOS
**License**: MIT
