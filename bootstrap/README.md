# Allyabase Bootstrap System

A comprehensive bootstrapping and configuration management system for allyabase, featuring:

- **Automatic base discovery and announcements**
- **Federated wiki-based configuration UI**
- **User management with public key authentication**
- **External content feed integration (Bluesky, RSS)**
- **Service orchestration and port management**

## 🚀 Quick Start

### 1. Install Dependencies
```bash
cd bootstrap
npm install
```

### 2. Start Configuration UI
```bash
# Start fedwiki-based configuration interface
npm run config

# Opens at:
# - Wiki UI: http://localhost:3030
# - API: http://localhost:3031
```

### 3. Start Bootstrap Service
```bash
# Start the bootstrap service
npm start

# Or in development mode
npm run dev
```

## 📋 Configuration

### Configuration File Structure
The bootstrap system uses a comprehensive JSON configuration file with the following sections:

#### Base Information
- **Name**: Human-readable base name
- **Description**: Purpose and description of the base
- **Star System Number**: Optional uint32 identifier
- **Contact Info**: Email and website

#### Networking
- **Announce To Bases**: List of other bases to announce to
- **Listen for Announcements**: Whether to accept announcements from other bases
- **Service Endpoints**: Full service URL mapping

#### User Management
- **Max Users**: Total number of allowed users
- **Allowed Public Keys**: Optional whitelist of specific secp256k1 public keys
- **Registration Mode**: open, whitelist, invite, closed

#### Content Feeds
- **Bluesky Feeds**: Import content from Bluesky handles
- **Custom Feeds**: RSS/JSON feed imports
- **Tagging and Import Intervals**: Automatic content categorization

#### Services
- **Enabled Services**: Which allyabase microservices to run
- **Port Configuration**: Base port and offset settings

#### Bootstrap Settings
- **Auto-announce**: Automatic announcements on startup
- **Announcement Intervals**: How often to re-announce
- **Retry Logic**: Failed announcement handling

### Example Configuration
```json
{
  "baseInfo": {
    "name": "Community Planet Nine Base",
    "description": "A community-focused base for Planet Nine users",
    "starSystemNumber": 42,
    "contactInfo": {
      "email": "admin@mybase.example.com",
      "website": "https://mybase.example.com"
    }
  },
  "networking": {
    "announceToBase": [
      {
        "name": "Planet Nine Development Base",
        "baseUrl": "https://dev.bdo.allyabase.com",
        "services": {
          "bdo": "https://dev.bdo.allyabase.com",
          "sanora": "https://dev.sanora.allyabase.com"
        },
        "enabled": true
      }
    ],
    "listenForAnnouncements": true
  },
  "userManagement": {
    "maxUsers": 500,
    "allowedPublicKeys": [
      {
        "publicKey": "03a34b99f22c790c4e36b2b3c2c35a36db06226e41c692fc82b8b56ac1c540c5bd",
        "name": "Admin Key",
        "permissions": ["read", "write", "admin"]
      }
    ],
    "registrationMode": "open"
  },
  "contentFeeds": {
    "blueskyFeeds": [
      {
        "handle": "planetnine.dev",
        "feedType": "timeline",
        "tags": ["planetnine", "dev"],
        "importInterval": 60
      }
    ]
  }
}
```

## 🌍 Fedwiki Configuration Interface

The fedwiki-based configuration interface provides an intuitive way to manage your base configuration:

### Features
- **Interactive Forms**: Easy-to-use forms for all configuration sections
- **Real-time Validation**: Immediate feedback on configuration errors
- **Federated Sharing**: Share configuration templates across bases
- **Version History**: Track configuration changes over time

### Configuration Pages
1. **Base Information**: Name, description, contact details
2. **Networking Configuration**: Base discovery and announcements
3. **User Management**: Access controls and public keys
4. **Content Feeds**: Bluesky and RSS feed integration
5. **Service Configuration**: Enable/disable services and ports

### Usage
1. Navigate to `http://localhost:3030` after starting the config server
2. Edit configuration using the interactive forms
3. Changes are automatically saved to the configuration file
4. Restart the bootstrap service to apply changes

## 🔄 Bootstrap Process

### Startup Sequence
1. **Load Configuration**: Read and validate configuration file
2. **Initialize Sessionless**: Generate cryptographic keys for base identity
3. **Service Discovery**: Map enabled services to ports
4. **Schedule Announcements**: Set up periodic announcement jobs
5. **Start HTTP Server**: Health checks and announcement endpoints
6. **Initial Announcements**: Announce to configured bases

### Announcement Protocol
Bases announce themselves using signed messages:

```json
{
  "timestamp": "2024-01-01T00:00:00Z",
  "baseInfo": {
    "name": "My Base",
    "description": "Base description",
    "starSystemNumber": 42
  },
  "services": {
    "bdo": "https://mybase.example.com:3003",
    "sanora": "https://mybase.example.com:8243"
  },
  "publicKey": "03a34b99f22c790c4e36b2b3c2c35a36db06226e41c692fc82b8b56ac1c540c5bd",
  "signature": "signature_of_message_content"
}
```

### Verification Process
1. **Signature Verification**: Verify announcement signature using public key
2. **Store Announcement**: Save verified announcements for discovery
3. **Update Base Registry**: Add/update base in discovery system

## 🔧 API Endpoints

### Bootstrap Service API (Port 4242)

#### Health Check
```bash
GET /health
```

#### Get Status
```bash
GET /status
# Returns base info, services, and announcement targets
```

#### Get Configuration
```bash
GET /config
# Returns current configuration
```

#### Receive Announcements
```bash
POST /announce
# Endpoint for receiving announcements from other bases
```

### Configuration API (Port 3031)

#### Get Configuration
```bash
GET /api/config
```

#### Update Base Information
```bash
POST /api/config/baseInfo
Content-Type: application/json

{
  "name": "Updated Base Name",
  "description": "Updated description"
}
```

#### Update Networking
```bash
POST /api/config/networking
Content-Type: application/json

{
  "announceToBase": [...],
  "listenForAnnouncements": true
}
```

## 🔍 Monitoring & Logging

### Log Files
- **combined.log**: All log entries
- **error.log**: Error-level logs only
- **Console**: Real-time colored output

### Log Levels
- **info**: General information
- **warn**: Warning conditions
- **error**: Error conditions
- **debug**: Detailed debugging information

### Health Monitoring
```bash
# Check bootstrap service health
curl http://localhost:4242/health

# Check configuration API health  
curl http://localhost:3031/health
```

## 🧪 Testing

### Run Tests
```bash
npm test
```

### Test Coverage
- Configuration validation
- Announcement protocol
- Signature verification
- API endpoints
- Error handling

## 🔒 Security Considerations

### Cryptographic Security
- **secp256k1 Keys**: Industry-standard elliptic curve cryptography
- **Message Signing**: All announcements are cryptographically signed
- **Signature Verification**: Incoming announcements are verified before acceptance

### Network Security
- **Public Key Authentication**: No passwords or shared secrets
- **Optional Whitelisting**: Restrict access to specific public keys
- **Rate Limiting**: Built-in protection against announcement spam

### Configuration Security
- **Schema Validation**: All configuration changes are validated
- **File Permissions**: Configuration files should have restricted permissions
- **Audit Logging**: All configuration changes are logged

## 🚀 Production Deployment

### Environment Variables
```bash
# Configuration
BOOTSTRAP_CONFIG=/path/to/config.json
BOOTSTRAP_PORT=4242
FEDWIKI_PORT=3030
FEDWIKI_DATA=/path/to/fedwiki/data
LOG_LEVEL=info

# Service discovery
PUBLIC_HOSTNAME=mybase.example.com
```

### Docker Deployment
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --only=production
COPY . .
EXPOSE 4242 3030 3031
CMD ["npm", "start"]
```

### Process Management
```bash
# Using PM2
pm2 start bootstrap-service.js --name allyabase-bootstrap
pm2 start fedwiki-config-server.js --name fedwiki-config

# Using systemd
# Create service files in /etc/systemd/system/
```

## 🤝 Integration with Allyabase Services

### Service Port Mapping
The bootstrap service automatically calculates service ports based on configuration:

```javascript
const servicePortMap = {
  julia: 0,        // basePort + 0
  continuebee: -1, // basePort - 1
  pref: 2,         // basePort + 2
  bdo: 3,          // basePort + 3
  // ... etc
};
```

### Service Discovery
- **Internal Discovery**: Services discover each other through the bootstrap service
- **External Discovery**: Other bases discover services through announcements
- **Health Checks**: Bootstrap service monitors service health

### Configuration Integration
Services can read bootstrap configuration for:
- User authentication settings
- Content feed configurations  
- Network topology information
- Rate limiting and access controls

## 🔮 Future Enhancements

### Planned Features
- **GUI Configuration Editor**: Web-based alternative to fedwiki
- **Advanced Content Filters**: Content moderation and filtering
- **Load Balancing**: Multi-instance service deployment
- **Analytics Dashboard**: Usage metrics and monitoring
- **Backup/Restore**: Configuration and data backup systems

### Community Features
- **Base Templates**: Shareable configuration templates
- **Discovery Network**: Enhanced base discovery protocols
- **Federation Protocols**: Deeper integration with fedwiki ecosystem
- **Plugin System**: Extensible configuration and bootstrap plugins

---

For more information, see the [Planet Nine Documentation](https://github.com/freyja-love-and-magic/allyabase) and [Federated Wiki](https://github.com/fedwiki/wiki).