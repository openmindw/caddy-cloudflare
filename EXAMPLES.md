# Example Caddyfile Configuration

Below are examples of how to use Caddy with the Cloudflare DNS plugin for automatic HTTPS certificates.

## Basic Setup

```caddyfile
# Set your Cloudflare token as environment variable
# export CADDY_CF_TOKEN="your-cloudflare-api-token"

example.com {
    tls {
        dns cloudflare {env.CADDY_CF_TOKEN}
    }
    
    # Your site configuration
    respond "Hello from Caddy with Cloudflare DNS!"
}
```

## Multiple Domains

```caddyfile
# Wildcard certificate for all subdomains
*.example.com, example.com {
    tls {
        dns cloudflare {env.CADDY_CF_TOKEN}
    }
    
    # Route based on subdomain
    @api host api.example.com
    handle @api {
        reverse_proxy localhost:8080
    }
    
    @app host app.example.com  
    handle @app {
        reverse_proxy localhost:3000
    }
    
    # Default handler for main domain
    handle {
        file_server
    }
}
```

## With Manual Token

If you prefer not to use environment variables:

```caddyfile
example.com {
    tls {
        dns cloudflare your-cloudflare-api-token-here
    }
    
    file_server
}
```

## JSON Configuration

You can also use JSON configuration:

```json
{
  "apps": {
    "http": {
      "servers": {
        "srv0": {
          "listen": [":443"],
          "routes": [
            {
              "match": [{"host": ["example.com"]}],
              "handle": [
                {
                  "handler": "file_server"
                }
              ]
            }
          ]
        }
      }
    },
    "tls": {
      "automation": {
        "policies": [
          {
            "subjects": ["example.com"],
            "issuers": [
              {
                "module": "acme",
                "challenges": {
                  "dns": {
                    "provider": {
                      "name": "cloudflare",
                      "api_token": "{env.CADDY_CF_TOKEN}"
                    }
                  }
                }
              }
            ]
          }
        ]
      }
    }
  }
}
```

## Cloudflare API Token Setup

1. Go to [Cloudflare API Tokens](https://dash.cloudflare.com/profile/api-tokens)
2. Click "Create Token"
3. Use the "Custom token" template
4. Set permissions:
   - Zone: Zone Settings: Read
   - Zone: Zone: Read
   - Zone: DNS: Edit
5. Set zone resources to include your domain
6. Create the token and save it securely

## Environment Variables

Set the token in your environment:

```bash
# Linux/macOS
export CADDY_CF_TOKEN="your-token-here"

# Windows
set CADDY_CF_TOKEN=your-token-here

# In systemd service file
Environment=CADDY_CF_TOKEN=your-token-here

# In Docker
docker run -e CADDY_CF_TOKEN=your-token-here ...
```