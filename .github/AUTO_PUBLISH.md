# Auto-Publish Setup

This repository has automated NPM publishing configured for every commit to the `main` branch using **Trusted Publishing (OIDC)** for enhanced security.

## Required Configuration

### 1. NPM Trusted Publishing Setup
Configure trusted publishing on npm (no tokens needed):

1. Go to [npmjs.com](https://www.npmjs.com) and login
2. Navigate to your package settings or profile
3. Find **"Publishing access"** or **"Trusted publishers"** section
4. Click **"Add trusted publisher"**
5. Configure:
   - **Provider**: `GitHub Actions`
   - **Repository owner**: `EVVM-org`
   - **Repository name**: `Testnet-Contracts`
   - **Workflow filename**: `auto-publish.yml`
   - **Environment** (optional): `npm-publish` (if using environment protection)

### 2. Repository Permissions
The workflow is configured with the necessary permissions to:
- Write to the repository (automatic commits)
- Create releases
- Access packages
- Use OIDC authentication (`id-token: write`)

## How It Works

1. **Trigger**: Executes on every push to `main` (except changes only in README, docs, or .github)
2. **Authentication**: Uses GitHub's OIDC (trusted publishing) - no long-lived tokens needed
3. **Versioning**: Automatically increments version based on commit message prefix
4. **Publishing**: 
   - Copies files from `src/` to root
   - Publishes to NPM with provenance attestation
   - Cleans up copied files
5. **Git**: Commits the new version with `[skip-publish]` to avoid loops
6. **Release**: Creates a GitHub release with the new version

### Security Features
- **No NPM Tokens**: Uses temporary OIDC credentials instead of long-lived tokens
- **Provenance Attestation**: Each package includes cryptographic proof of its build process
- **Enhanced Security**: Compliant with npm's 2025 security requirements

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

## Trusted Publishing Setup Guide

### Step-by-Step Configuration

#### On npmjs.com:
1. Login to your npm account
2. Go to your package or profile settings
3. Navigate to **"Publishing access"** or **"Trusted publishers"**
4. Click **"Add trusted publisher"**
5. Fill in the details:
   ```
   Provider: GitHub Actions
   Repository owner: EVVM-org
   Repository name: Testnet-Contracts
   Workflow filename: auto-publish.yml
   Environment: npm-publish (optional)
   ```

#### On GitHub:
1. **Remove old NPM_TOKEN secret** (if it exists):
   - Go to Settings → Secrets and variables → Actions
   - Delete the `NPM_TOKEN` secret
2. **Verify repository permissions**:
   - Settings → Actions → General
   - Ensure "Read and write permissions" is enabled
3. **(Optional) Create environment protection**:
   - Settings → Environments
   - Create `npm-publish` environment with protection rules

### Benefits of Trusted Publishing
- 🔒 **Enhanced Security**: No long-lived tokens to manage or compromise
- 🔍 **Provenance Attestation**: Automatic cryptographic proof of package origin
- ⚡ **Simplified Workflow**: No token rotation or management needed
- 🛡️ **Phishing Resistant**: OIDC tokens are temporary and scope-limited
- 📈 **Better Audit Trail**: Clear visibility into publishing source and process

### Troubleshooting

- **Failed Publication**: 
  - Verify trusted publisher is configured correctly on npm
  - Check that repository name and workflow filename match exactly
  - Ensure `id-token: write` permission is present in workflow
- **OIDC Authentication Issues**: 
  - Confirm GitHub Actions has permission to use OIDC
  - Verify the trusted publisher configuration on npmjs.com
- **Version Conflicts**: Ensure no manual version changes conflict with auto-versioning
- **Workflow Loops**: The `[skip-publish]` flag prevents infinite loops from version commits
- **File Structure**: The workflow temporarily flattens `src/` structure for NPM compatibility

### Migration Notes (November 2025)
This workflow has been updated to comply with npm's new security requirements:
- ✅ **No more NPM tokens needed** - uses trusted publishing (OIDC)
- ✅ **Enhanced security** - temporary credentials only
- ✅ **Automatic provenance** - cryptographic proof of build process
- ✅ **Future-proof** - compliant with npm's security roadmap

### Monitoring

- Check GitHub Actions tab for workflow execution status
- Monitor NPM package page for successful publications
- Review GitHub Releases for version history
- Check commit history for automatic version bump commits