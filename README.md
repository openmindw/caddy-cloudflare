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

The workflow can be triggered:
1. **Automatically** when a new version tag is pushed (e.g., `v2.8.4`)
2. **Manually** via GitHub Actions with an optional Caddy version parameter

### Using the Cloudflare DNS Plugin

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
