# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is **Dockware WEB with FrankenPHP**, a high-performance Docker image that provides developers with a pre-configured development environment featuring FrankenPHP with worker mode, Caddy web server, multiple PHP versions (7.4-8.5), Node.js versions (22, 24), Xdebug, and essential web development tools. The project creates production-ready Docker containers based on the FrankenPHP official image.

## Development Commands

### Build & Test Commands (via makefile)
```bash
# Install dependencies
make install

# Build image (requires version parameter)
make build version=dev

# Run all tests and build
make all version=dev

# Individual test suites
make svrunit version=dev    # SVRUnit functional tests
make cypress version=dev    # Browser end-to-end tests

# Analyze image size
make analyze version=dev

# Clean up
make clear
```

### Docker Usage
```bash
# Quick run
docker run -p 80:80 -p 443:443 diwmarco/web-frankenphp-frankenphp:latest

# With custom configuration
docker-compose up  # Uses PHP_VERSION, NODE_VERSION env vars
```

## Architecture

### FrankenPHP + Caddy Stack
- **FrankenPHP**: High-performance PHP application server with worker mode
- **Caddy**: Modern web server with automatic HTTPS and HTTP/2
- **Worker Mode**: PHP processes stay in memory for optimal performance
- **Multi-PHP Support**: Runtime switching between PHP versions (7.4-8.5)

### Key Directories
- `src/` - Main Docker image source code
  - `Dockerfile` - FrankenPHP-based container definition
  - `entrypoint.sh` - Container startup logic and FrankenPHP/Caddy configuration
  - `scripts/` - Installation scripts for PHP/Node versions
  - `config/` - Caddy, FrankenPHP, and PHP configuration
    - `caddy/Caddyfile` - Main Caddy web server configuration
    - `frankenphp/worker.php` - FrankenPHP worker mode bootstrap script
    - `php/` - PHP configuration templates
  - `assets/` - Runtime scripts and assets
- `tests/` - Comprehensive test suites
  - `svrunit/` - Functional tests organized by feature
  - `cypress/` - End-to-end browser tests including FrankenPHP-specific tests

### Runtime Environment Variables
The container supports runtime configuration via environment variables:
- `PHP_VERSION` - Switch between PHP 7.4-8.5
- `NODE_VERSION` - Switch between Node 22, 24  
- `CADDY_ROOT` - Set Caddy document root (default: /var/www/html/public)
- `FRANKENPHP_CONFIG` - FrankenPHP worker configuration
- `XDEBUG_ENABLED` - Enable/disable Xdebug (0/1)
- `RECOVERY_MODE` - Emergency mode (0/1)
- `SSH_USER/SSH_PWD` - Custom SSH credentials

### FrankenPHP Worker Mode
The project implements FrankenPHP worker mode for maximum performance:
- **Worker Script**: `/var/www/html/public/frankenphp-worker.php` handles all PHP requests
- **Persistent Memory**: PHP processes stay in memory between requests
- **Error Handling**: Robust error handling with development mode support
- **Request Routing**: Smart routing to handle various PHP application patterns

### Web Server Configuration
Caddy provides modern web server features:
- **Automatic HTTPS**: SSL certificates generated automatically
- **HTTP/2 Support**: Modern protocol support out of the box
- **Compression**: Gzip and Zstd compression enabled
- **Security Headers**: Comprehensive security headers configured
- **File Protection**: Sensitive files (.env, .git, etc.) blocked
- **Health Checks**: Built-in health endpoints (/health, /ready)

## Testing Strategy

### SVRUnit Tests (tests/svrunit/)
Functional tests validate core functionality:
- Multi-PHP version switching and compatibility
- SSH, Xdebug, recovery mode features
- Supervisor, Filebeat, Tideways integration
- Node.js version switching

### Cypress Tests (tests/cypress/)
End-to-end testing includes:
- FrankenPHP functionality and worker mode
- Caddy web server features
- Security header validation
- Health check endpoints
- Performance and compression testing

## Development Patterns

1. **Adding PHP Version**: Create new script in `src/scripts/php/install_phpX.Y.sh` following existing patterns
2. **Modifying Web Server**: Update `src/config/caddy/Caddyfile` for Caddy configuration
3. **Worker Mode Changes**: Modify `src/config/frankenphp/worker.php` for request handling
4. **Testing Changes**: Always run `make all version=dev` for complete validation
5. **Runtime Configuration**: Prefer environment variables over build-time configuration

## Performance Considerations

- **Worker Mode**: FrankenPHP keeps PHP in memory for ~10x performance improvement
- **HTTP/2**: Caddy provides HTTP/2 support for faster loading
- **Compression**: Automatic compression reduces bandwidth usage
- **Static Files**: Caddy handles static files efficiently without PHP overhead

## Key Integration Points

- **FrankenPHP**: Modern PHP application server with Go-based performance
- **Caddy**: Zero-config HTTPS, HTTP/2, and modern web server features
- **PHP-FPM**: Multiple PHP versions with FPM for compatibility
- **Worker Mode**: High-performance request handling with persistent processes
- **Health Monitoring**: Built-in health checks for container orchestration
- **SSH Access**: Development-friendly SSH access with key generation

## Commands Reference

### Container Management
```bash
# Switch PHP versions (no restart required)
make switch-php version=8.3

# Switch Node versions  
make switch-node version=24

# Restart PHP-FPM service
make restart-php

# Container restart required for FrankenPHP changes
docker restart <container_name>
```

### Development Tools
- **Xdebug**: Runtime enable/disable with `make xdebug-on` / `make xdebug-off`
- **Composer**: Pre-installed with global access
- **NPM/Yarn**: Available with Node version switching
- **SSH**: Built-in SSH server with development user access