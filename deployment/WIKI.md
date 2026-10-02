# Federated Wiki Integration

## Overview

Each Planet Nine allyabase deployment now includes a Federated Wiki instance with sessionless security for configuration management and dashboard functionality.

## Architecture

- **Wiki Software**: [Federated Wiki](https://github.com/fedwiki/wiki)
- **Security Plugin**: [wiki-security-sessionless](https://www.npmjs.com/package/wiki-security-sessionless)
- **Port**: 3333 (default), with offset for multi-base deployments

## Port Mapping

### Test Environment (Docker)
- **Base 1**: http://localhost:5124 → docker:3333
- **Base 2**: http://localhost:5224 → docker:3333
- **Base 3**: http://localhost:5324 → docker:3333

### Local Environment
- **Local**: http://localhost:3333

## Purpose

The wiki serves two primary functions:

### 1. Configuration Management

The wiki can be used to manage configuration across all Planet Nine services:

- **User Creation Gating**: Configure how users can create accounts
- **Service Configuration**: Set environment-specific settings
- **Feature Flags**: Enable/disable features per base
- **API Keys**: Store encrypted API keys and credentials
- **Rate Limits**: Configure rate limiting per service
- **Base Metadata**: Store base-specific information (name, owner, theme, etc.)

### 2. Dashboard

The wiki provides a human-friendly interface for monitoring and managing your base:

- **Service Status**: View health and status of all microservices
- **Recent Activity**: Monitor recent transactions, user registrations, etc.
- **Analytics**: View usage statistics and metrics
- **Quick Actions**: Common administrative tasks
- **Documentation**: Service-specific documentation and guides

## Initial Setup

When you first access your wiki, you'll need to create initial pages. Here are recommended starting pages:

### Welcome Page
```markdown
# Planet Nine Base Dashboard

Welcome to your Planet Nine base configuration and monitoring dashboard.

## Quick Links
- [[Service Configuration]]
- [[User Management]]
- [[Base Settings]]
- [[Monitoring]]
```

### Service Configuration Page
```markdown
# Service Configuration

Configuration for all Planet Nine microservices.

## User Creation
- Mode: open | closed | passphrase | hardware
- Passphrase Hash: (if using passphrase mode)

## Rate Limiting
- Global limit: 100 requests/minute
- Per-service overrides:
  - fount: 50 requests/minute
  - bdo: 200 requests/minute

## Feature Flags
- ENABLE_PROF: false
- ENABLE_EXPERIMENTAL_FEATURES: false
```

### Base Settings Page
```markdown
# Base Settings

## Identity
- Base Name: My Planet Nine Base
- Owner: your-uuid-here
- Theme: default

## Network
- Public: true
- Discovery: true
- Federation: enabled

## Emoji Identity
- Base Emoji: 🌍🔑💎
```

## Sessionless Authentication

The wiki uses sessionless security, which integrates with Planet Nine's cryptographic authentication:

- **No Passwords**: Authentication via cryptographic signatures
- **Key-Based Access**: Uses sessionless-node for verification
- **Same Keys**: Use your Planet Nine keys to access wiki
- **Federated**: Share pages with other bases securely

## Configuration Pattern

Services can read configuration from the wiki:

```javascript
// In your service (pseudo-code)
const wikiConfig = await fetch('http://localhost:3333/service-configuration.json');
const config = await wikiConfig.json();

// Use config
if (config.userCreation.mode === 'passphrase') {
  // Check passphrase
}
```

## Federation

Federated Wiki allows you to:

- **Share Configuration**: Share config pages with other bases
- **Collaborative Editing**: Multiple bases can collaborate on shared configs
- **Version Control**: Track changes over time
- **Forking**: Copy and modify configs from other bases

## Best Practices

1. **Start Simple**: Begin with basic config pages, expand as needed
2. **Document Changes**: Use wiki's version control to document why configs changed
3. **Security**: Keep sensitive data (like API keys) encrypted
4. **Regular Backups**: The wiki data is stored in Docker volumes
5. **Use Federation**: Share useful configs with other Planet Nine bases

## Troubleshooting

### Wiki Not Starting

Check logs:
```bash
docker logs allyabase-base1 | grep wiki
```

Check if port is exposed:
```bash
docker port allyabase-base1
```

### Can't Access Wiki

1. Verify the service is running: `curl http://localhost:5124`
2. Check firewall settings
3. Verify port mapping in Docker

### Authentication Issues

The sessionless security plugin requires:
1. Valid Planet Nine keys
2. Proper signature verification
3. Timestamp within acceptable range

## Development

To test wiki integration locally:

```bash
# Start local services
cd allyabase/deployment/docker
./spin-up-bases.sh --env=local

# Access wiki at http://localhost:3333
```

## Future Enhancements

Potential future uses for the wiki:

- **Real-Time Monitoring**: WebSocket integration for live service status
- **Alert Management**: Configure alerts and notifications
- **User Analytics**: Dashboards for user activity and engagement
- **Contract Templates**: Store and share contract templates
- **Spell Documentation**: Document custom MAGIC spells
- **Base Discovery**: Public directory of Planet Nine bases

## Resources

- [Federated Wiki Documentation](http://fed.wiki.org)
- [Sessionless Authentication](https://github.com/freyja-love-and-magic/sessionless)
- [Wiki Security Sessionless Plugin](https://www.npmjs.com/package/wiki-security-sessionless)
- [Planet Nine Documentation](https://planetnine.app)

---

**Last Updated**: October 16, 2025
