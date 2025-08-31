# caddy-cloudflare

This repository provides tools and automation for building Caddy with the Cloudflare DNS plugin.

## Quick Installation

Use the installation script to build and install Caddy with the Cloudflare DNS plugin:

```bash
curl -fsSL https://raw.githubusercontent.com/openmindw/caddy-cloudflare/main/install_caddy_github.sh | sudo bash
```

## Pre-built Binaries

Pre-built binaries are available from the [Releases](../../releases) page. These binaries include Caddy with the Cloudflare DNS plugin pre-compiled for various platforms.

### Automated Builds

This repository includes a GitHub Actions workflow that automatically builds Caddy with the Cloudflare DNS plugin for multiple platforms:

- Linux (amd64, arm64, armv7, armv6)
- Windows (amd64, arm64)  
- macOS (amd64, arm64)

## Using the Cloudflare DNS Plugin

After installation, you can use the Cloudflare DNS plugin for automatic HTTPS certificates:

1. Get a Cloudflare API Token with DNS edit permissions
2. Set the environment variable:
   ```bash
   export CADDY_CF_TOKEN="your-cloudflare-token"
   ```
3. Use in your Caddyfile:
   ```
   your-domain.com {
       tls {
           dns cloudflare {env.CADDY_CF_TOKEN}
       }
   }
   ```

See [EXAMPLES.md](EXAMPLES.md) for more detailed configuration examples.

## Automated Builds

This repository includes a GitHub Actions workflow that automatically builds Caddy with the Cloudflare DNS plugin for multiple platforms:

- Linux (amd64, arm64, armv7, armv6)
- Windows (amd64, arm64)  
- macOS (amd64, arm64)

### Triggering Builds

The workflow can be triggered in three ways:

1. **Tag-based releases**: Push a version tag (e.g., `v2.8.4`) to automatically build and create a GitHub release
   ```bash
   git tag v2.8.4
   git push origin v2.8.4
   ```

2. **Scheduled builds**: Automatic weekly builds every Sunday at 02:00 UTC that create releases with binaries for all supported platforms

3. **Manual execution**: Go to the Actions tab in GitHub and manually run the "Build Caddy with Cloudflare Plugin" workflow. You can optionally:
   - Specify a Caddy version to build (default: latest)
   - Choose to create a release for the build
   - Set a custom tag name for the release (default: generates unique timestamp-based tag)
   
   **Note**: To ensure unique releases, the workflow automatically adds a run number suffix to custom tag names and generates timestamp-based tags for manual releases. This prevents conflicts with existing releases.

### Build Output

Each build produces:
- Compressed binaries (`.tar.gz` for Unix, `.zip` for Windows)
- SHA256 checksums for verification
- Automatic GitHub releases with detailed descriptions

## Manual Building

If you prefer to build manually:

```bash
# Install Go and xcaddy
go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest

# Build Caddy with Cloudflare plugin
xcaddy build --with github.com/caddy-dns/cloudflare
```

## Links

- [Caddy Documentation](https://caddyserver.com/docs/)
- [Cloudflare DNS Plugin](https://github.com/caddy-dns/cloudflare)
