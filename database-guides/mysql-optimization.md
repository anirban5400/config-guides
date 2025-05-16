# MySQL Performance Optimization & Administration Guide

> *A comprehensive guide for optimizing MySQL/MariaDB databases, configuration tweaking, and performance tuning for high-traffic applications*

## Table of Contents
- [Prerequisites](#prerequisites)
- [Server Configuration](#server-configuration)
- [Query Optimization](#query-optimization)
- [Indexing Strategies](#indexing-strategies)
- [Replication Setup](#replication-setup)
- [Backup Strategies](#backup-strategies)
- [Security Hardening](#security-hardening)
- [Monitoring & Maintenance](#monitoring--maintenance)
- [Troubleshooting](#troubleshooting)

## Prerequisites

- MySQL 8.0+ or MariaDB 10.6+
- Root or administrative access to MySQL
- Basic understanding of database concepts
- 4GB+ RAM for optimal performance

## Server Configuration

### Key Configuration File Settings

The main MySQL configuration file is typically located at `/etc/mysql/my.cnf` or `/etc/my.cnf`. Here are important settings to optimize:

```ini
[mysqld]
# Basic Settings
user = mysql
pid-file = /var/run/mysqld/mysqld.pid
socket = /var/run/mysqld/mysqld.sock
port = 3306
basedir = /usr
datadir = /var/lib/mysql
tmpdir = /tmp
lc-messages-dir = /usr/share/mysql

# Character Set / Collation
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci

# InnoDB Settings
innodb_buffer_pool_size = 1G                # 50-70% of available RAM
innodb_buffer_pool_instances = 8            # Multiple instances for concurrency
innodb_file_per_table = 1                   # Separate tablespace files
innodb_flush_log_at_trx_commit = 1          # ACID compliance (0 or 2 for performance)
innodb_flush_method = O_DIRECT              # Bypass OS cache
innodb_log_file_size = 256M                 # Larger for write-heavy workloads

# Connection and Thread Settings
max_connections = 500                       # Adjust based on expected connections
thread_cache_size = 128                     # Cache for new connections
max_allowed_packet = 64M                    # Maximum packet size allowed

# Query Cache (disabled in MySQL 8.0+)
#query_cache_type = 0                       # Disable query cache
#query_cache_size = 0                       # Size of query cache

# Logging
slow_query_log = 1
slow_query_log_file = /var/log/mysql/mysql-slow.log
long_query_time = 2                         # Log queries that take more than 2 seconds
log_error = /var/log/mysql/error.log

# Binary Logging (for replication)
server-id = 1                              # Unique server ID
log_bin = /var/log/mysql/mysql-bin.log     # Binary log file path
binlog_format = ROW                        # ROW-based logging for reliability
binlog_expire_logs_seconds = 2592000       # 30 days retention
max_binlog_size = 100M                     # Maximum size before rotation
```

### Server Hardware Considerations

| Resource | Recommendation | Notes |
|----------|---------------|-------|
| CPU | 4+ cores | More cores for higher concurrency |
| RAM | 8GB+ | Allocate 70-80% to InnoDB buffer pool |
| Disk | SSD preferred | Consider RAID 10 for production |
| Network | 1Gbps+ | Low latency for distributed systems |

## Query Optimization

### Identifying Slow Queries

```sql
-- Enable slow query logging at runtime
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL long_query_time = 1;  -- Log queries taking more than 1 second

-- List slow queries from MySQL admin
SHOW FULL PROCESSLIST;

-- Analyze query execution with EXPLAIN
EXPLAIN SELECT * FROM users 
JOIN orders ON users.id = orders.user_id 
WHERE users.status = 'active';
```

### Query Optimization Techniques

```sql
-- Use specific columns instead of SELECT *
SELECT id, username, email FROM users WHERE status = 'active';

-- Add proper indexes for WHERE clauses
CREATE INDEX idx_users_status ON users(status);

-- Avoid using functions on indexed columns
-- Bad: WHERE YEAR(created_at) = 2023
-- Good: WHERE created_at BETWEEN '2023-01-01' AND '2023-12-31'

-- Use LIMIT for large result sets
SELECT * FROM logs ORDER BY created_at DESC LIMIT 1000;

-- Consider indexed temporary tables for complex joins
CREATE TEMPORARY TABLE temp_user_stats (
  user_id INT NOT NULL,
  order_count INT NOT NULL,
  PRIMARY KEY (user_id)
) ENGINE=InnoDB;

INSERT INTO temp_user_stats 
SELECT user_id, COUNT(*) FROM orders GROUP BY user_id;
```

## Indexing Strategies

### Index Types and Best Practices

```sql
-- Primary Key (clustered index)
CREATE TABLE products (
  id INT NOT NULL AUTO_INCREMENT,
  name VARCHAR(100) NOT NULL,
  PRIMARY KEY (id)
);

-- Single-column index
CREATE INDEX idx_products_name ON products(name);

-- Compound index (order matters for queries)
CREATE INDEX idx_orders_user_date ON orders(user_id, created_at);

-- Covering index (includes all columns needed by query)
CREATE INDEX idx_users_email_name ON users(email, first_name, last_name);

-- Full-text index
CREATE FULLTEXT INDEX idx_articles_content ON articles(title, content);
```

### Index Analysis and Maintenance

```sql
-- Show table indexes
SHOW INDEX FROM users;

-- Analyze index usage
EXPLAIN SELECT * FROM users WHERE email = 'user@example.com';

-- Find unused indexes
SELECT * FROM sys.schema_unused_indexes;

-- Find missing indexes
SELECT * FROM sys.statements_with_full_table_scans
ORDER BY rows_examined DESC;

-- Optimize table (rebuilds indexes)
OPTIMIZE TABLE users;
```

## Replication Setup

### Master-Slave Replication Configuration

**Master Server Configuration:**

```ini
# my.cnf on master
[mysqld]
server-id = 1
log_bin = /var/log/mysql/mysql-bin.log
binlog_format = ROW
binlog_do_db = mydatabase  # Specify databases to replicate
```

SQL commands on master:

```sql
-- Create replication user on master
CREATE USER 'replication'@'%' IDENTIFIED BY 'strongpassword';
GRANT REPLICATION SLAVE ON *.* TO 'replication'@'%';
FLUSH PRIVILEGES;

-- Get binary log position
SHOW MASTER STATUS;
```

**Slave Server Configuration:**

```ini
# my.cnf on slave
[mysqld]
server-id = 2
log_bin = /var/log/mysql/mysql-bin.log
relay_log = /var/log/mysql/mysql-relay-bin
read_only = 1
```

SQL commands on slave:

```sql
-- Configure slave to connect to master
CHANGE MASTER TO
  MASTER_HOST = 'master_ip_address',
  MASTER_USER = 'replication',
  MASTER_PASSWORD = 'strongpassword',
  MASTER_LOG_FILE = 'mysql-bin.000001', -- From SHOW MASTER STATUS
  MASTER_LOG_POS = 123;                 -- From SHOW MASTER STATUS

-- Start replication
START SLAVE;

-- Check replication status
SHOW SLAVE STATUS\G
```

## Backup Strategies

### Logical Backups with mysqldump

```bash
# Full database backup
mysqldump -u root -p --all-databases --single-transaction \
  --quick --lock-tables=false > full_backup_$(date +%F).sql

# Specific database backup
mysqldump -u root -p --databases mydatabase --single-transaction \
  --quick --routines --triggers --events > mydatabase_$(date +%F).sql

# Only backup table structure
mysqldump -u root -p --no-data mydatabase > schema_backup.sql
```

### Physical Backups with Percona XtraBackup

```bash
# Install Percona XtraBackup
apt-get install percona-xtrabackup-80

# Full backup
xtrabackup --backup --target-dir=/backup/full

# Incremental backup
xtrabackup --backup --target-dir=/backup/inc1 \
  --incremental-basedir=/backup/full

# Prepare backup for restoration
xtrabackup --prepare --target-dir=/backup/full

# Restore backup
systemctl stop mysql
mv /var/lib/mysql /var/lib/mysql.old
xtrabackup --copy-back --target-dir=/backup/full
chown -R mysql:mysql /var/lib/mysql
systemctl start mysql
```

## Security Hardening

### User Management and Privileges

```sql
-- Create user with specific privileges
CREATE USER 'appuser'@'localhost' IDENTIFIED BY 'strongpassword';
GRANT SELECT, INSERT, UPDATE, DELETE ON mydatabase.* TO 'appuser'@'localhost';
FLUSH PRIVILEGES;

-- Audit user privileges
SELECT user, host FROM mysql.user;
SHOW GRANTS FOR 'appuser'@'localhost';

-- Remove anonymous users
DELETE FROM mysql.user WHERE user = '';
FLUSH PRIVILEGES;

-- Restrict remote root access
DELETE FROM mysql.user WHERE user='root' AND host NOT IN ('localhost', '127.0.0.1', '::1');
FLUSH PRIVILEGES;
```

### Encryption Settings

```ini
# Enable SSL/TLS
[mysqld]
ssl-ca=/path/to/ca.pem
ssl-cert=/path/to/server-cert.pem
ssl-key=/path/to/server-key.pem
require_secure_transport=ON
```

SQL commands:

```sql
-- Create user that requires SSL
CREATE USER 'secureuser'@'%' IDENTIFIED BY 'password' REQUIRE SSL;
GRANT ALL PRIVILEGES ON mydatabase.* TO 'secureuser'@'%';

-- Enable encryption for tablespaces
SET GLOBAL default_table_encryption = ON;
```

## Monitoring & Maintenance

### Key Metrics to Monitor

| Metric | Description | Normal Range |
|--------|-------------|--------------|
| Connections | Current open connections | <80% of max_connections |
| Buffer Pool Usage | InnoDB buffer pool utilization | 95-99% |
| Queries per Second | Rate of queries | Depends on application |
| Slow Queries | Number of slow queries | <1% of total queries |
| Disk I/O | Read/write operations | Depends on hardware |

### MySQL Status Commands

```sql
-- General server status
SHOW GLOBAL STATUS;

-- InnoDB engine status
SHOW ENGINE INNODB STATUS\G

-- Current processes and queries
SHOW PROCESSLIST;

-- Table sizes and statistics
SELECT table_name, table_rows, data_length, index_length,
  ROUND((data_length + index_length) / 1024 / 1024, 2) AS total_mb
FROM information_schema.tables
WHERE table_schema = 'mydatabase'
ORDER BY total_mb DESC;

-- Check for table fragmentation
ANALYZE TABLE users;
SHOW TABLE STATUS LIKE 'users'\G
```

## Troubleshooting

### Common Issues and Solutions

| Issue | Symptoms | Solutions |
|-------|----------|-----------|
| High CPU Usage | Server slowdown, high load average | Check slow queries, optimize indexing |
| Memory Swapping | Increased disk I/O, slow performance | Reduce buffer pool size, check for memory leaks |
| Connection Timeouts | "Too many connections" errors | Increase max_connections, optimize connection pooling |
| Replication Lag | Slave server outdated | Check slave status, network issues, optimize master queries |
| Corrupt Tables | Error messages, data inconsistency | Run CHECK TABLE, repair or restore from backup |

### Diagnostic Commands

```sql
-- Check table for errors
CHECK TABLE users;

-- Repair corrupted table
REPAIR TABLE users;

-- Find long-running queries
SELECT id, user, host, db, command, time, state, info 
FROM information_schema.processlist 
WHERE time > 60 
ORDER BY time DESC;

-- Kill a problematic query
KILL QUERY 12345;  -- process ID

-- Check for deadlocks
SHOW ENGINE INNODB STATUS\G
```

---

*This guide is regularly updated with the latest best practices. Last updated: 2025.* 