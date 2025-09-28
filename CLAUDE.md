# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Frappe-based Management System (FMS) running in Docker containers. The system uses Frappe framework v15 with ERPNext as the primary application.

## Architecture

- **Docker Services**: MariaDB, Redis (cache & queue), and the main ERP container
- **Frappe Bench**: Located at `/home/frappe/frappe-bench` inside the container
- **Apps**: `frappe` and `erpnext` are mounted from `./frappe-bench/apps/`
- **Sites**: Site configuration and assets are in `./frappe-bench/sites/`
- **Service Name**: `erp` container runs on ports 8000 (backend) and 8080 (frontend)

## Important: Bench Commands

Since the Frappe bench runs inside Docker, **ALL bench commands must be executed through Docker Compose**:

```bash
docker compose exec -u frappe erp bench [command]
```

### Default Site Configuration
The default site name is **`frontend`**. For commands that require a site parameter, always use `--site frontend`:

```bash
docker compose exec -u frappe erp bench --site frontend [command]
```

### Common Command Examples
- `docker compose exec -u frappe erp bench --site frontend console` - Open Python console for the site
- `docker compose exec -u frappe erp bench build` - Build assets (applies to all sites)
- `docker compose exec -u frappe erp bench --site frontend migrate` - Run database migrations
- `docker compose exec -u frappe erp bench --site frontend install-app [app_name]` - Install an app
- `docker compose exec -u frappe erp bench set-config [key] [value]` - Set global configuration
- `docker compose exec -u frappe erp bench --site frontend set-config [key] [value]` - Set site-specific configuration

## Common Development Commands

### Starting Services
```bash
docker compose up -d
```

### Viewing Logs
```bash
docker compose logs -f erp
```

### Database Operations
- Database: MariaDB 10.6
- Root password: `admin`
- Site name: `frontend`
- Admin password: `admin`

### Building & Development
```bash
# Build frontend assets
docker compose exec -u frappe erp bench build

# Clear cache for the site
docker compose exec -u frappe erp bench --site frontend clear-cache

# Run Python console for the site
docker compose exec -u frappe erp bench --site frontend console

# Watch assets for development
docker compose exec -u frappe erp bench watch
```

### App Management
```bash
# List installed apps (global)
docker compose exec -u frappe erp bench list-apps

# Install new app to the site
docker compose exec -u frappe erp bench get-app [app_name]
docker compose exec -u frappe erp bench --site frontend install-app [app_name]

# Uninstall app from the site
docker compose exec -u frappe erp bench --site frontend uninstall-app [app_name]
```

## Site-Specific Operations

Most Frappe commands that interact with the database or site-specific data require the `--site` parameter. Common site operations:

```bash
# Execute Python code in site context
docker compose exec -u frappe erp bench --site frontend execute [module.method]

# Run scheduled jobs
docker compose exec -u frappe erp bench --site frontend trigger-scheduler-event --event [all|hourly|daily|weekly|monthly]

# Set admin password
docker compose exec -u frappe erp bench --site frontend set-admin-password [new_password]

# Database operations
docker compose exec -u frappe erp bench --site frontend mariadb  # Access MariaDB console
docker compose exec -u frappe erp bench --site frontend backup   # Create backup
docker compose exec -u frappe erp bench --site frontend restore [backup_path]  # Restore from backup

# Clear specific caches
docker compose exec -u frappe erp bench --site frontend clear-website-cache
docker compose exec -u frappe erp bench --site frontend clear-cache
```

## File Structure

- **Apps**: Mounted from `./frappe-bench/apps/` to container's `/home/frappe/frappe-bench/apps/`
- **Sites**: Mounted from `./frappe-bench/sites/` to container's `/home/frappe/frappe-bench/sites/`
- **Configuration**: Site configuration in `sites/frontend/site_config.json`
- **Python Environment**: Virtual environment at `/home/frappe/frappe-bench/env` (Python 3.11)

## Key Scripts

- `prepare.sh`: Sets up Python path links for apps during container initialization
- `start-backend.sh`: Configures bench settings and starts Gunicorn server on first run
- `supervisord.conf`: Manages all services within the container

## Accessing the Container

```bash
# As frappe user (recommended)
docker compose exec -u frappe erp bash

# As root (for system operations)
docker compose exec erp bash
```

## Development Notes

- The container uses Gunicorn with 2 workers and 4 threads
- Redis is used for caching and queue management
- Site assets are built automatically on first run
- The system auto-installs all apps listed in `sites/apps.txt`

## Testing Commands

```bash
# Run tests for an app on the site
docker compose exec -u frappe erp bench --site frontend run-tests --app [app_name]

# Run specific test on the site
docker compose exec -u frappe erp bench --site frontend run-tests --app [app_name] --module [module_name]
```

## Troubleshooting

```bash
# Check bench status
docker compose exec -u frappe erp bench doctor

# Check site status
docker compose exec -u frappe erp bench --site frontend doctor

# Restart services inside container
docker compose exec erp supervisorctl restart all

# Rebuild container
docker compose down
docker compose build
docker compose up -d

# Backup site
docker compose exec -u frappe erp bench --site frontend backup

# Restore site
docker compose exec -u frappe erp bench --site frontend restore [path_to_backup]
```