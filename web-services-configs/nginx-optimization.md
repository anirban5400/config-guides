# Nginx Performance Optimization & Configuration Guide

> *A comprehensive guide for configuring, optimizing, and securing Nginx web servers for high-traffic websites*

## Table of Contents
- [Prerequisites](#prerequisites)
- [Basic Configuration](#basic-configuration)
- [Performance Optimization](#performance-optimization)
- [Caching Configuration](#caching-configuration)
- [SSL/TLS Setup](#ssltls-setup)
- [Security Hardening](#security-hardening)
- [Load Balancing](#load-balancing)
- [Troubleshooting](#troubleshooting)

## Prerequisites

- Nginx installed (1.18.0+)
- Root or sudo access to the server
- Basic understanding of web server concepts
- Domain name(s) configured with DNS records

## Basic Configuration

### Main Configuration File Structure

The main Nginx configuration file is located at `/etc/nginx/nginx.conf`. Here's a well-structured basic configuration:

```nginx
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
    worker_connections 1024;
    multi_accept on;
    use epoll;
}

http {
    # Basic settings
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    server_tokens off;
    
    # MIME types
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    # Logging
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;
    
    # Gzip settings
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_buffers 16 8k;
    gzip_http_version 1.1;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
    
    # Virtual Host Configs
    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
```

### Virtual Host Configuration

Create a server block for your domain in `/etc/nginx/sites-available/example.com`:

```nginx
server {
    listen 80;
    listen [::]:80;
    server_name example.com www.example.com;
    
    # Redirect HTTP to HTTPS
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name example.com www.example.com;
    
    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
    ssl_trusted_certificate /etc/letsencrypt/live/example.com/chain.pem;
    
    # Document Root
    root /var/www/example.com/public;
    index index.html index.htm index.php;
    
    # Logging
    access_log /var/log/nginx/example.com.access.log;
    error_log /var/log/nginx/example.com.error.log;
    
    # Default location block
    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }
    
    # PHP handler
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
    }
    
    # Deny access to hidden files
    location ~ /\. {
        deny all;
    }
}
```

Enable the configuration:

```bash
sudo ln -s /etc/nginx/sites-available/example.com /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

## Performance Optimization

### Worker Processes & Connections

```nginx
# Set worker processes to match CPU cores
worker_processes auto;

# Increase worker connections based on server resources
events {
    worker_connections 4096;
    multi_accept on;
    use epoll;
}
```

### Buffering & Timeout Settings

```nginx
http {
    # Client buffer size
    client_body_buffer_size 10K;
    client_header_buffer_size 1k;
    client_max_body_size 8m;
    large_client_header_buffers 2 1k;
    
    # Timeouts
    client_body_timeout 12;
    client_header_timeout 12;
    keepalive_timeout 15;
    send_timeout 10;
}
```

### File Handling Optimization

```nginx
http {
    # Enable sendfile for better file serving
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    
    # Open file cache
    open_file_cache max=1000 inactive=20s;
    open_file_cache_valid 30s;
    open_file_cache_min_uses 2;
    open_file_cache_errors on;
}
```

## Caching Configuration

### FastCGI Cache for PHP

```nginx
# FastCGI cache configuration in http block
http {
    # Cache zone definition
    fastcgi_cache_path /var/run/nginx-cache levels=1:2 keys_zone=PHPCACHE:100m inactive=60m;
    fastcgi_cache_key "$scheme$request_method$host$request_uri";
    
    # Server block configuration
    server {
        # Cache configuration inside location block for PHP
        location ~ \.php$ {
            include snippets/fastcgi-php.conf;
            fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
            
            # Enable cache
            fastcgi_cache PHPCACHE;
            fastcgi_cache_valid 200 60m;
            fastcgi_cache_methods GET HEAD;
            
            # Cache bypass settings
            fastcgi_cache_bypass $cookie_PHPSESSID;
            fastcgi_no_cache $cookie_PHPSESSID;
            
            # Cache headers
            add_header X-FastCGI-Cache $upstream_cache_status;
        }
    }
}
```

### Static File Caching

```nginx
# Static file caching in location blocks
location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
    expires 365d;
    add_header Cache-Control "public, no-transform";
}

location ~* \.(pdf|html|htm|txt)$ {
    expires 30d;
    add_header Cache-Control "public, no-transform";
}
```

## SSL/TLS Setup

### Modern SSL Configuration

```nginx
server {
    listen 443 ssl http2;
    server_name example.com;
    
    # SSL certificates
    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
    
    # SSL optimization
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    
    # OCSP Stapling
    ssl_stapling on;
    ssl_stapling_verify on;
    resolver 8.8.8.8 8.8.4.4 valid=300s;
    resolver_timeout 5s;
    
    # SSL session caching
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 1d;
    ssl_session_tickets off;
    
    # HSTS settings
    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
}
```

## Security Hardening

### Security Headers

```nginx
server {
    # Security headers
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' https://www.google-analytics.com; style-src 'self' 'unsafe-inline'; img-src 'self' data: https://www.google-analytics.com; connect-src 'self'; font-src 'self'; object-src 'none'; media-src 'self'; frame-src 'none'; form-action 'self'; base-uri 'self';" always;
    
    # Disable server tokens
    server_tokens off;
}
```

### Rate Limiting

```nginx
http {
    # Define limit zones
    limit_req_zone $binary_remote_addr zone=login:10m rate=1r/s;
    limit_conn_zone $binary_remote_addr zone=conn_limit_per_ip:10m;
    
    server {
        # Apply rate limiting to login endpoint
        location /login {
            limit_req zone=login burst=5 nodelay;
            proxy_pass http://backend_server;
        }
        
        # Apply connection limit to the whole server
        limit_conn conn_limit_per_ip 10;
    }
}
```

## Load Balancing

### HTTP Load Balancing

```nginx
http {
    # Backend server definitions
    upstream backend {
        server backend1.example.com weight=3;
        server backend2.example.com weight=2;
        server backup.example.com backup;
        
        # Load balancing method
        # least_conn; # least connections
        # ip_hash;    # session persistence
        # hash $request_uri; # consistent hashing
    }
    
    server {
        location / {
            proxy_pass http://backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
}
```

## Troubleshooting

### Common Nginx Issues and Solutions

| Issue | Solution |
|-------|----------|
| 502 Bad Gateway | Check if backend service is running and accessible |
| 504 Gateway Timeout | Increase proxy timeout values in configuration |
| High CPU usage | Optimize worker processes, enable gzip compression |
| SSL certificate issues | Verify certificate paths and permissions |
| Permission denied errors | Check file ownership and access rights |

### Diagnostic Commands

```bash
# Test configuration syntax
sudo nginx -t

# Debug configuration with verbose output
sudo nginx -T

# Check running processes
ps aux | grep nginx

# Check open ports
sudo netstat -tlpn | grep nginx

# Check error logs
sudo tail -f /var/log/nginx/error.log
```

---

*This guide is regularly updated with the latest best practices. Last updated: 2025.* 