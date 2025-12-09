# Developer Guide

This guide covers the development workflow for the Aerie Helm chart, including signing releases.

## Prerequisites

### Required Tools

| Tool                                         | Installation           | Purpose                           |
| -------------------------------------------- | ---------------------- | --------------------------------- |
| [Helm](https://helm.sh/) 3.8+                | `brew install helm`    | Chart packaging and deployment    |
| [Task](https://taskfile.dev/)                | `brew install go-task` | Task runner                       |
| [Cosign](https://github.com/sigstore/cosign) | `brew install cosign`  | Artifact signing and verification |

### Registry Access

You need push access to the OCI registry:

```bash
helm registry login registry.platform.intelligent.space
```

## Development Workflow

### Making Changes

1. Make your changes to the chart
2. Lint to catch errors:
   ```bash
   task lint
   ```
3. Test template rendering:
   ```bash
   task template
   ```

### Releasing Snapshots

Snapshot releases can be created from any branch at any time:

```bash
task release
```

This creates a version like `0.1.0-SNAPSHOT.abc1234` (with git short SHA) and pushes to the registry. Snapshots are **not signed** and can be overwritten.

### Official Releases

Official releases require:
- Clean working directory (no uncommitted changes)
- Being on the `main` branch
- Cosign signing key (`cosign.key`)

```bash
task release OFFICIAL=true
```

This will:
1. Validate branch and working directory
2. Package the chart
3. Push to the OCI registry
4. Sign the artifact with cosign (key-based)
5. Create a git tag

## Artifact Signing with Cosign

We use [Sigstore Cosign](https://github.com/sigstore/cosign) with **key-based signing** to sign official releases. This provides supply chain security by cryptographically verifying that artifacts came from trusted sources.

### Setting Up Signing Keys

1. Install cosign:
   ```bash
   brew install cosign
   ```

2. Generate a key pair:
   ```bash
   task cosign-keygen
   ```

   This creates:
   - `cosign.key` - Private key (keep secret, never commit!)
   - `cosign.pub` - Public key (commit to repo for verification)

3. You'll be prompted to create a password for the private key. Store this securely.

4. The private key is already in `.gitignore`. The public key should be committed so others can verify signatures.

### How Key-Based Signing Works

1. During official release, the chart is signed using your private key (`cosign.key`)
2. The signature is stored in the OCI registry alongside the artifact
3. Anyone with the public key (`cosign.pub`) can verify the signature

### Signing Workflow

```bash
# Generate keys (one-time setup)
task cosign-keygen

# Make an official release (will prompt for key password)
task release OFFICIAL=true
```

### Verifying Signatures

Verify that an artifact was signed with the project's key:

```bash
# Verify using the public key in the repo
task verify VERSION=0.1.0

# Or manually
cosign verify --key cosign.pub registry.platform.intelligent.space/aerie/aerie-helm:0.1.0
```

### Manual Signing

If you need to sign an artifact manually:

```bash
# Sign with the private key
cosign sign --key cosign.key registry.platform.intelligent.space/aerie/aerie-helm@sha256:...

# Verify with the public key
cosign verify --key cosign.pub registry.platform.intelligent.space/aerie/aerie-helm:0.1.0
```

### Key Management Best Practices

- **Never commit `cosign.key`** - It's in `.gitignore` for a reason
- **Back up your private key** - Store it in a secure location (password manager, vault)
- **Use a strong password** - The key is encrypted with this password
- **Rotate keys periodically** - Generate new keys and re-sign if compromised
- **CI/CD**: Store the private key as a secret and pass via `COSIGN_KEY` variable

### Using a Custom Key Path

You can specify a different key location:

```bash
task release OFFICIAL=true COSIGN_KEY=/path/to/my.key
task verify VERSION=0.1.0 COSIGN_PUB=/path/to/my.pub
```

### Troubleshooting

**"Signing key not found" error**
- Run `task cosign-keygen` to generate keys
- Or specify path with `COSIGN_KEY=/path/to/key`

**"incorrect password" error**
- The password for the private key is incorrect
- Cosign will prompt for the password interactively

**"no matching signatures" error**
- The artifact may not be signed
- The signature may have been made with a different key
- Check if it's a snapshot (snapshots are not signed)

**Registry authentication issues**
- Ensure you're logged in: `helm registry login registry.platform.intelligent.space`
- Cosign uses the same Docker credential store

## Version Management

### Bumping Versions

```bash
task bump-patch   # 0.1.0 -> 0.1.1
task bump-minor   # 0.1.0 -> 0.2.0
task bump-major   # 0.1.0 -> 1.0.0
```

### Version Scheme

- **Chart version** (`version` in Chart.yaml): The Helm chart version
- **App version** (`appVersion` in Chart.yaml): The Aerie release version this chart deploys

When updating for a new Aerie release, update `appVersion`. When making chart changes, bump the chart `version`.

## Task Reference

| Task                          | Description                          |
| ----------------------------- | ------------------------------------ |
| `task lint`                   | Validate chart syntax                |
| `task template`               | Render templates locally             |
| `task package`                | Build chart to `dist/`               |
| `task release`                | Create snapshot release              |
| `task release OFFICIAL=true`  | Create signed official release       |
| `task verify`                 | Verify signature of current version  |
| `task verify VERSION=x.y.z`   | Verify signature of specific version |
| `task cosign-keygen`          | Generate new signing key pair        |
| `task clean`                  | Remove build artifacts               |
| `task version`                | Show current versions                |
| `task bump-patch/minor/major` | Increment version                    |

## CI/CD

For automated releases in CI, you can use cosign with key-based signing:

1. Store `cosign.key` as a CI secret
2. Set `COSIGN_PASSWORD` environment variable with the key password
3. Run the release task

Example GitHub Actions snippet:
```yaml
- name: Release
  env:
    COSIGN_PASSWORD: ${{ secrets.COSIGN_PASSWORD }}
  run: |
    echo "${{ secrets.COSIGN_KEY }}" > cosign.key
    task release OFFICIAL=true
    rm cosign.key
```

See the [Cosign documentation](https://docs.sigstore.dev/cosign/key_management/signing_with_self-managed_keys/) for more details.
