# Auto-Publish Setup

This repository has automated NPM publishing configured for every commit to the `main` branch.

## Required Configuration

### 1. NPM Token
Create an NPM token and add it as a GitHub secret:

1. Go to [npmjs.com](https://www.npmjs.com) and login
2. Navigate to your profile → Access Tokens
3. Create a new token with "Automation" permissions
4. In GitHub, go to Settings → Secrets and variables → Actions
5. Add a new secret named `NPM_TOKEN` with the token value

### 2. Repository Permissions
The workflow is already configured with the necessary permissions to:
- Write to the repository (automatic commits)
- Create releases
- Access packages

## How It Works

1. **Trigger**: Executes on every push to `main` (except changes only in README, docs, or .github)
2. **Versioning**: Automatically increments version based on commit message prefix
3. **Publishing**: 
   - Copies files from `src/` to root
   - Publishes to NPM
   - Cleans up copied files
4. **Git**: Commits the new version with `[skip-publish]` to avoid loops
5. **Release**: Creates a GitHub release with the new version

## Skip Automatic Publishing

To commit without publishing, include `[skip-publish]` in your commit message:

```bash
git commit -m "fix: minor bug [skip-publish]"
```

## Published Package Structure

```
@evvm/testnet-contracts/
├── contracts/
├── interfaces/
├── library/
├── LICENSE
├── README.md
└── package.json
```

## Automatic Versioning System

The workflow automatically determines the version increment type based on your commit message:

### Version Increment Rules

- **PATCH (default)**: Any regular commit → `1.0.4` → `1.0.5`
- **MINOR**: Commits starting with `MINOR:` → `1.0.4` → `1.1.0`
- **MAJOR**: Commits starting with `MAJOR:` → `1.0.4` → `2.0.0`

### Commit Message Examples

```bash
# PATCH increment (default behavior)
git commit -m "fix: resolve contract bug"
git commit -m "docs: update README"
git commit -m "chore: cleanup code"

# MINOR increment (new features, backward compatible)
git commit -m "MINOR: add new utility functions"
git commit -m "MINOR: implement additional contract methods"

# MAJOR increment (breaking changes)
git commit -m "MAJOR: refactor contract interface"
git commit -m "MAJOR: remove deprecated functions"
```

### Version Detection Flow

1. **Commit Analysis**: Workflow checks commit message prefix
2. **Type Determination**: 
   - Starts with `MAJOR:` → Major version bump
   - Starts with `MINOR:` → Minor version bump  
   - Everything else → Patch version bump
3. **NPM Version**: Executes `npm version [patch|minor|major]`
4. **Publication**: Publishes to NPM with new version
5. **Git Commit**: Creates version bump commit with `[skip-publish]`
6. **GitHub Release**: Creates release noting the version type

## Development Workflow

### For Regular Development (PATCH)
```bash
# Make your changes
git add .
git commit -m "fix: resolve issue with contract validation"
git push origin main
# → Auto-publishes as patch version (e.g., 1.2.3 → 1.2.4)
```

### For New Features (MINOR)
```bash
# Add new functionality
git add .
git commit -m "MINOR: add new utility functions for token management"
git push origin main
# → Auto-publishes as minor version (e.g., 1.2.3 → 1.3.0)
```

### For Breaking Changes (MAJOR)
```bash
# Make breaking changes
git add .
git commit -m "MAJOR: refactor interface to use new signature format"
git push origin main
# → Auto-publishes as major version (e.g., 1.2.3 → 2.0.0)
```

### Best Practices

1. **Clear Commit Messages**: Use descriptive messages that explain the change
2. **Semantic Versioning**: Follow SemVer principles when choosing version types
3. **Breaking Changes**: Always use `MAJOR:` for incompatible API changes
4. **New Features**: Use `MINOR:` for backward-compatible functionality additions
5. **Bug Fixes**: Use regular commits (PATCH) for backward-compatible bug fixes
6. **Documentation**: Regular commits for documentation updates (PATCH)

### Troubleshooting

- **Failed Publication**: Check NPM_TOKEN secret is valid and has publish permissions
- **Version Conflicts**: Ensure no manual version changes conflict with auto-versioning
- **Workflow Loops**: The `[skip-publish]` flag prevents infinite loops from version commits
- **File Structure**: The workflow temporarily flattens `src/` structure for NPM compatibility

### Monitoring

- Check GitHub Actions tab for workflow execution status
- Monitor NPM package page for successful publications
- Review GitHub Releases for version history
- Check commit history for automatic version bump commits