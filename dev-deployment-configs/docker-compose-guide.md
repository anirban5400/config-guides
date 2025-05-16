# Docker Compose Configuration & Orchestration Guide

> *A comprehensive guide for building, configuring, and orchestrating multi-container applications using Docker Compose*

## Table of Contents
- [Prerequisites](#prerequisites)
- [Docker Compose Basics](#docker-compose-basics)
- [Configuration Strategies](#configuration-strategies)
- [Multi-Environment Setup](#multi-environment-setup)
- [Networking Configuration](#networking-configuration)
- [Volume Management](#volume-management)
- [Service Dependencies](#service-dependencies)
- [Security Best Practices](#security-best-practices)
- [Orchestration & Scaling](#orchestration--scaling)
- [Troubleshooting](#troubleshooting)

## Prerequisites

- Docker Engine installed (20.10.x+)
- Docker Compose installed (v2.x+)
- Basic understanding of containerization
- Familiarity with YAML syntax

## Docker Compose Basics

### Docker Compose File Structure

Docker Compose uses a YAML file (typically `docker-compose.yml`) to define multi-container applications:

```yaml
version: '3.9'

services:
  web:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./html:/usr/share/nginx/html
    restart: unless-stopped
    
  db:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: rootpassword
      MYSQL_DATABASE: myapp
      MYSQL_USER: user
      MYSQL_PASSWORD: password
    volumes:
      - db_data:/var/lib/mysql
    restart: unless-stopped

volumes:
  db_data:
```

### Essential Docker Compose Commands

```bash
# Start all services
docker compose up

# Start in detached mode
docker compose up -d

# View running containers
docker compose ps

# View logs
docker compose logs

# View logs for specific service and follow
docker compose logs -f web

# Stop all services
docker compose down

# Stop and remove volumes
docker compose down -v

# Rebuild services
docker compose up -d --build
```

## Configuration Strategies

### Using Environment Variables

Create a `.env` file:

```
MYSQL_ROOT_PASSWORD=rootpassword
MYSQL_DATABASE=myapp
MYSQL_USER=user
MYSQL_PASSWORD=password
WEB_PORT=80
```

Reference in `docker-compose.yml`:

```yaml
services:
  web:
    image: nginx:alpine
    ports:
      - "${WEB_PORT}:80"
      
  db:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: ${MYSQL_DATABASE}
      MYSQL_USER: ${MYSQL_USER}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
```

### Building Custom Images

```yaml
services:
  app:
    build:
      context: ./app
      dockerfile: Dockerfile
      args:
        NODE_ENV: production
    ports:
      - "3000:3000"
    environment:
      - DATABASE_URL=mysql://user:password@db:3306/myapp
```

Sample `Dockerfile` in `./app` directory:

```dockerfile
FROM node:16-alpine

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

EXPOSE 3000

CMD ["npm", "start"]
```

## Multi-Environment Setup

### Using Multiple Compose Files

**Base Configuration (`docker-compose.yml`):**

```yaml
version: '3.9'

services:
  app:
    build: ./app
    depends_on:
      - db
    
  db:
    image: mysql:8.0
    volumes:
      - db_data:/var/lib/mysql

volumes:
  db_data:
```

**Development Override (`docker-compose.dev.yml`):**

```yaml
services:
  app:
    build:
      context: ./app
      args:
        NODE_ENV: development
    volumes:
      - ./app:/app
      - /app/node_modules
    environment:
      - DEBUG=true
      
  db:
    environment:
      MYSQL_ROOT_PASSWORD: dev_password
    ports:
      - "3306:3306"  # Expose port for development
```

**Production Override (`docker-compose.prod.yml`):**

```yaml
services:
  app:
    build:
      context: ./app
      args:
        NODE_ENV: production
    restart: always
    
  db:
    environment:
      MYSQL_ROOT_PASSWORD: ${DB_PASSWORD}
    restart: always
    # Don't expose DB port in production
```

**Running with environment-specific config:**

```bash
# Development
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# Production
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

## Networking Configuration

### Network Types and Configuration

```yaml
services:
  web:
    image: nginx:alpine
    networks:
      - frontend
      
  app:
    build: ./app
    networks:
      - frontend
      - backend
      
  db:
    image: mysql:8.0
    networks:
      - backend

networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
    internal: true  # Not accessible from outside
```

### Exposing Ports Securely

```yaml
services:
  web:
    image: nginx:alpine
    ports:
      - "80:80"      # Publicly accessible
      - "443:443"    # Publicly accessible
      
  app:
    build: ./app
    expose:
      - "3000"       # Only accessible to other containers
      
  db:
    image: mysql:8.0
    # No ports exposed externally
```

## Volume Management

### Volume Types and Use Cases

```yaml
services:
  web:
    image: nginx:alpine
    volumes:
      # Named volume for persisting data
      - nginx_logs:/var/log/nginx
      
      # Bind mount for development
      - ./nginx/conf.d:/etc/nginx/conf.d:ro
      
      # Anonymous volume for cache
      - /tmp/nginx_cache
      
  db:
    image: mysql:8.0
    volumes:
      # Named volume for database files
      - db_data:/var/lib/mysql
      
      # Bind mount for initialization scripts
      - ./db/init:/docker-entrypoint-initdb.d

volumes:
  nginx_logs:
    driver: local
  db_data:
    driver: local
    # Optional driver_opts for production
    driver_opts:
      type: nfs
      o: addr=192.168.1.1,rw
      device: ":/path/to/nfs/share"
```

### Volume Backup and Restore

```bash
# Create a backup of a named volume
docker run --rm -v myapp_db_data:/source -v $(pwd):/backup alpine \
  tar -czf /backup/db_backup.tar.gz -C /source .

# Restore a volume from backup
docker run --rm -v myapp_db_data:/target -v $(pwd):/backup alpine \
  sh -c "rm -rf /target/* && tar -xzf /backup/db_backup.tar.gz -C /target"
```

## Service Dependencies

### Controlling Startup Order

```yaml
services:
  app:
    image: myapp:latest
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_healthy
        
  db:
    image: mysql:8.0
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 10s
      timeout: 5s
      retries: 5
      
  redis:
    image: redis:alpine
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 3s
      retries: 3
```

### Handling Initialization

```yaml
services:
  db:
    image: postgres:14
    volumes:
      - ./init-scripts:/docker-entrypoint-initdb.d
      
  app:
    image: myapp:latest
    depends_on:
      - db
    command: sh -c "
      echo 'Waiting for database to be ready...' &&
      /wait-for-it.sh db:5432 -t 60 &&
      echo 'Database is ready!' &&
      npm start
      "
    volumes:
      - ./wait-for-it.sh:/wait-for-it.sh:ro
```

Example `wait-for-it.sh` script:

```bash
#!/usr/bin/env bash
# wait-for-it.sh script to check if a host:port is available
# Source: https://github.com/vishnubob/wait-for-it
```

## Security Best Practices

### Managing Secrets

Using Docker secrets (Swarm mode):

```yaml
version: '3.9'

services:
  db:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD_FILE: /run/secrets/db_root_password
      MYSQL_PASSWORD_FILE: /run/secrets/db_password
    secrets:
      - db_root_password
      - db_password

secrets:
  db_root_password:
    file: ./secrets/db_root_password.txt
  db_password:
    file: ./secrets/db_password.txt
```

Using environment files (for non-Swarm):

```yaml
services:
  db:
    image: mysql:8.0
    env_file:
      - ./db.env
```

Example `db.env` file (should be excluded from version control):

```
MYSQL_ROOT_PASSWORD=rootpassword
MYSQL_DATABASE=myapp
MYSQL_USER=user
MYSQL_PASSWORD=password
```

### Limiting Container Capabilities

```yaml
services:
  app:
    image: myapp:latest
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE  # Only if needed
```

## Orchestration & Scaling

### Scaling Services

```yaml
services:
  worker:
    image: worker:latest
    deploy:
      replicas: 3
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
```

Command to scale a service:

```bash
# Docker Compose v2
docker compose up -d --scale worker=5
```

### Resource Limits

```yaml
services:
  app:
    image: myapp:latest
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 256M
        reservations:
          cpus: '0.25'
          memory: 128M
```

## Troubleshooting

### Common Issues and Solutions

| Issue | Symptoms | Solutions |
|-------|----------|-----------|
| Container exit | Container stops immediately | Check logs (`docker compose logs SERVICE_NAME`), ensure correct startup command |
| Network issues | Services can't communicate | Verify network settings, check if services are on the same network |
| Volume permission | Permission denied errors | Check file ownership, permissions, or use user mapping |
| Resource limits | Container performance issues | Increase CPU/memory limits, check for memory leaks |
| Startup order | Application can't connect to DB | Use healthchecks and depends_on with condition |

### Debugging Commands

```bash
# View container logs
docker compose logs -f service_name

# Execute command in running container
docker compose exec service_name sh

# View container details
docker compose inspect service_name

# Check network connections
docker network inspect my_compose_network

# View resource usage statistics
docker stats
```

---

*This guide is regularly updated with the latest best practices. Last updated: 2025.* 