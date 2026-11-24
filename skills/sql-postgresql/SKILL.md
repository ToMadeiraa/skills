---
name: sql-postgresql
description: "SQL development best practices for efficient, secure, maintainable queries, with PostgreSQL specifics for schema design, indexing, query plans, JSONB, transactions, maintenance, and security."
metadata:
  maintainer: Mindrally
  source: https://github.com/Mindrally/skills
---

# SQL Best Practices

The rules below are portable SQL; PostgreSQL is the dialect used in the concrete examples. Where another engine behaves differently, the text says so explicitly.

**Scope.** The project's existing schema wins: do not rename existing tables or columns, rewrite
migrations, or "fix" a working query for style. Apply this guidance to new SQL and to changes the
task actually requires; verify with the project's `client-e2e-check` after touching the data path.

## Core Principles

- Write clear, readable SQL with consistent formatting and meaningful aliases.
- Optimize with evidence: read the query plan before adding an index or rewriting a query.
- Prevent injection with parameterized queries and least-privilege roles, never with escaping.
- Model data with native types and real constraints instead of strings and application-side validation.
- Keep transactions short, and use the weakest isolation level that is still correct.
- Document complex queries inline and version-control every schema change.

## Query Writing Standards

### Formatting and Style

- Use uppercase for SQL keywords (SELECT, FROM, WHERE, JOIN).
- Put each major clause on a new line, and indent subqueries and nested conditions consistently.
- Use meaningful table aliases: `customers AS c`, not `customers AS x`.
- Align column lists and conditions when it aids reading; do not reflow a statement just to preserve an alignment.

```sql
SELECT
    c.customer_id,
    c.customer_name,
    o.order_date,
    o.total_amount
FROM customers AS c
INNER JOIN orders AS o ON c.customer_id = o.customer_id
WHERE o.order_date >= '2024-01-01'
    AND o.status = 'completed'
ORDER BY o.order_date DESC;
```

### Column Selection

- Never use `SELECT *` in application code; list the columns the caller actually reads.
- Alias computed columns to give the result a stable contract: `SELECT first_name AS "First Name"`.
- Order columns logically: keys first, then attributes, then computed values.

### Filtering and Conditions

- Use `EXISTS` rather than `IN` for subquery existence checks; it short-circuits and stays correct with NULLs.
- Never wrap an indexed column in a function in `WHERE`; rewrite it as a range so the index remains usable.
- Put the most restrictive predicate first for readability, not for speed: the planner reorders predicates.
- Prefer `IN (list)` over a chain of `OR`s.
- Always pass values as parameters, never as concatenated literals.

```sql
-- Preferred: EXISTS for an existence check
SELECT c.customer_name
FROM customers AS c
WHERE EXISTS (
    SELECT 1 FROM orders AS o
    WHERE o.customer_id = c.customer_id
      AND o.order_date > '2024-01-01'
);

-- Avoid: function on an indexed column
WHERE YEAR(order_date) = 2024

-- Preferred: equivalent range
WHERE order_date >= '2024-01-01' AND order_date < '2025-01-01'
```

### Join Best Practices

- Always use explicit `JOIN` syntax; implicit joins in `WHERE` hide the join graph.
- State the join type explicitly (INNER, LEFT, RIGHT, FULL OUTER) instead of relying on a default.
- Filter in `ON` for outer joins and in `WHERE` for inner joins; a predicate on the outer side moved into `WHERE` silently turns the join into an inner one.
- Treat `CROSS JOIN` as deliberate: require a comment and a row-count check on both sides.
- Order joins from most to least selective only when it makes the intent clearer; execution order belongs to the planner.

```sql
-- Preferred: explicit join
SELECT c.name, o.order_id
FROM customers AS c
INNER JOIN orders AS o ON c.customer_id = o.customer_id;

-- Avoid: implicit join
SELECT c.name, o.order_id
FROM customers c, orders o
WHERE c.customer_id = o.customer_id;
```

### Aggregation

- Filter before grouping: a predicate in `WHERE` beats the same predicate in `HAVING`.
- Use `COUNT(*)` for row counts and `COUNT(column)` only when NULLs must be excluded.
- Remember that `GROUP BY` collapses NULLs into one group; exclude it with `WHERE ... IS NOT NULL` when that group is meaningless.
- Use window functions when a value is needed per row and per group at the same time.

```sql
-- Efficient: filter before aggregation
SELECT category_id, COUNT(*) AS product_count
FROM products
WHERE active = true
GROUP BY category_id
HAVING COUNT(*) > 10;
```

## Schema Design

### Data Types

- Choose the narrowest native type that cannot silently overflow: `NUMERIC`/`DECIMAL` for money, integers for counts, `DATE` only when the timezone genuinely does not apply.
- Prefer `TIMESTAMPTZ` over `TIMESTAMP` for anything that records a moment in time.
- Use `TEXT` when no length limit is real; a `VARCHAR(n)` limit that later has to be raised is a migration, not a protection.
- Use `UUID` (or a database-generated identity) for distributed or externally visible keys, `SERIAL`/`IDENTITY` for compact internal keys.
- Use `JSONB`, arrays, `INET`, `CIDR`, and range types instead of encoding those shapes into text.

```sql
CREATE TABLE orders (
    order_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES customers(customer_id),
    order_data JSONB NOT NULL DEFAULT '{}',
    tags TEXT[] NOT NULL DEFAULT '{}',
    total_amount NUMERIC(12, 2) NOT NULL CHECK (total_amount >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

### Constraints and Keys

- Every table gets a primary key; without one a table cannot be deduplicated, replicated, or safely bulk-updated.
- Declare foreign keys with an explicit `ON DELETE`/`ON UPDATE` action; the default `NO ACTION` is a decision too.
- Add `NOT NULL` wherever the application would otherwise have to handle a NULL.
- Push value validity into `CHECK` constraints, and enumerations into `CHECK (col IN (...))` or a lookup table.
- Put a unique index behind every natural key the application assumes is unique.

```sql
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    sku VARCHAR(50) NOT NULL UNIQUE,
    name TEXT NOT NULL,
    price NUMERIC(10, 2) NOT NULL CHECK (price >= 0),
    status VARCHAR(20) NOT NULL DEFAULT 'active'
        CHECK (status IN ('active', 'inactive', 'discontinued')),
    metadata JSONB NOT NULL DEFAULT '{}'
);
```

### Partitioning

- Partition only tables large enough to hurt (millions of rows or a time-ordered retention window); on a small table partitioning costs more than it saves.
- Choose the strategy by the dominant predicate: `RANGE` for time, `LIST` for tenant or region, `HASH` for an even spread.
- Create indexes on the partitioned parent so new partitions inherit them.
- Make sure queries carry the partition key in `WHERE`; without it every partition is read.

```sql
CREATE TABLE events (
    event_id BIGSERIAL,
    event_type VARCHAR(50) NOT NULL,
    payload JSONB,
    created_at TIMESTAMPTZ NOT NULL
) PARTITION BY RANGE (created_at);

CREATE TABLE events_2024_q1 PARTITION OF events
    FOR VALUES FROM ('2024-01-01') TO ('2024-04-01');
```

## Indexing

### Index Types

- B-tree (the default) covers equality and range predicates, and is the right choice for most foreign keys and sort columns.
- GIN for `JSONB`, arrays, and full-text search; GiST for geometry and range types; BRIN for large, naturally ordered tables where a tiny index is enough.
- Prefer a partial index when queries always filter on the same value: `... WHERE status = 'active'`.
- Use a covering index (`INCLUDE (...)`) when the query needs a few extra columns and the table lookup dominates the cost.
- Composite indexes are ordered: `(customer_id, order_date)` serves `customer_id` alone, but not `order_date` alone.
- Every index taxes every write and takes space; drop the ones nothing reads.

```sql
-- B-tree index for common lookups
CREATE INDEX idx_orders_customer ON orders(customer_id);

-- GIN index for JSONB queries
CREATE INDEX idx_orders_data ON orders USING GIN (order_data);

-- Partial index for active records only
CREATE INDEX idx_active_products ON products(name) WHERE status = 'active';

-- Covering index to avoid the table lookup
CREATE INDEX idx_orders_covering ON orders(customer_id)
    INCLUDE (order_date, total_amount);
```

### Index Maintenance

- Run `ANALYZE` after bulk loads and let autovacuum keep statistics current; stale statistics produce bad plans.
- `REINDEX` a bloated index instead of living with it.
- Audit usage: an index with `idx_scan = 0` across a full workload cycle is dead weight.
- Verify the index is actually reached; a predicate like `col::text = ...` will not touch `idx_col`.

```sql
-- Check index usage
SELECT schemaname, relname, indexrelname, idx_scan, idx_tup_read
FROM pg_stat_user_indexes
ORDER BY idx_scan ASC;
```

## Query Optimization

- Read the plan before changing anything: `EXPLAIN (ANALYZE, BUFFERS)` shows where time and I/O actually go.
- A sequential scan on a small table is correct; on a large table it usually means a missing or unusable index.
- Compare estimated rows with actual rows. A ratio off by orders of magnitude means stale statistics or a bad estimate, not a bad index.
- Limit result sets (`LIMIT`/`TOP`/`FETCH FIRST`) when the caller does not need everything.
- Paginate large reads with keyset pagination; a growing `OFFSET` costs more on every page.
- Replace a correlated subquery with a join (or a lateral join) when it runs per row.
- Cache at the application edge only for genuinely hot, staleness-tolerant queries; a cache must not hide a missing index.

```sql
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT c.name, COUNT(o.order_id)
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE c.created_at > '2024-01-01'
GROUP BY c.customer_id, c.name;
```

```sql
-- Pagination example
SELECT product_id, product_name, price
FROM products
ORDER BY product_id
LIMIT 20 OFFSET 40;
```

### Common Table Expressions

- Use a CTE to name one step of a complex query; it buys readability, not performance by itself.
- Treat CTEs as optimization fences on older PostgreSQL versions; from 12 on the planner may inline them, and `MATERIALIZED`/`NOT MATERIALIZED` forces the choice.

```sql
WITH recent_orders AS MATERIALIZED (
    SELECT customer_id, COUNT(*) AS order_count, SUM(total) AS total_spent
    FROM orders
    WHERE order_date > CURRENT_DATE - INTERVAL '30 days'
    GROUP BY customer_id
)
SELECT c.name, ro.order_count, ro.total_spent
FROM customers c
JOIN recent_orders ro ON c.customer_id = ro.customer_id
WHERE ro.total_spent > 1000;
```

### Window Functions

- Use window functions for running totals, rankings, and per-group comparisons instead of a self-join or a second aggregation.
- `PARTITION BY` defines the group, `ORDER BY` defines the sequence; with no `ORDER BY` the frame is the whole partition.

```sql
SELECT
    order_id,
    customer_id,
    total_amount,
    SUM(total_amount) OVER (PARTITION BY customer_id ORDER BY order_date) AS running_total,
    ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date DESC) AS order_rank
FROM orders;
```

## Semi-Structured Data (JSONB)

- Store `JSONB`, not `JSON`: it is normalised, compressed, and indexable.
- Create a GIN index on every `JSONB` column that appears in `WHERE`, and query with the containment operators `@>`, `<@`, `?` so the index applies.
- Promote a field to a real column once queries filter or sort on it often; `JSONB` is for sparse or evolving attributes, not for avoiding schema work.
- Validate the document's required keys with a `CHECK` constraint or an application-side schema; `JSONB` on its own accepts anything.

```sql
-- Efficient JSONB query with a GIN index
SELECT * FROM products
WHERE metadata @> '{"category": "electronics"}';

-- Extract specific fields
SELECT
    product_id,
    metadata->>'brand' AS brand,
    (metadata->>'rating')::numeric AS rating
FROM products
WHERE metadata ? 'rating';
```

## Transactions and Locking

- Keep transactions as short as possible; never hold one open across user interaction or a network round trip.
- Pick the weakest isolation level that is still correct: `READ COMMITTED` covers most cases, `REPEATABLE READ` for consistent multi-statement reads, `SERIALIZABLE` only where an invariant demands it — and then retry on serialization failures.
- Always pair `BEGIN` with `COMMIT` or `ROLLBACK` on every error path; a leaked open transaction holds locks until the connection dies.
- Use savepoints for multi-step operations that may fail part-way.
- Use advisory locks for application-level coordination that row locks cannot express.
- When something hangs, inspect the lock graph instead of killing sessions blindly.

```sql
BEGIN;

UPDATE accounts SET balance = balance - 100 WHERE account_id = 1;
UPDATE accounts SET balance = balance + 100 WHERE account_id = 2;

COMMIT;
-- On error: ROLLBACK;
```

In engines without exception handling in plain SQL, check the error status after each statement and roll back explicitly:

```sql
-- SQL Server
IF @@ERROR <> 0
    ROLLBACK TRANSACTION;
ELSE
    COMMIT TRANSACTION;
```

```sql
-- Advisory lock for application coordination
SELECT pg_advisory_lock(hashtext('resource_name'));
-- Do work
SELECT pg_advisory_unlock(hashtext('resource_name'));

-- Check for blocking queries
SELECT blocked_locks.pid AS blocked_pid,
       blocking_locks.pid AS blocking_pid,
       blocked_activity.query AS blocked_query
FROM pg_catalog.pg_locks blocked_locks
JOIN pg_catalog.pg_locks blocking_locks
    ON blocking_locks.locktype = blocked_locks.locktype
    AND blocking_locks.relation = blocked_locks.relation
    AND blocking_locks.pid != blocked_locks.pid
JOIN pg_catalog.pg_stat_activity blocked_activity
    ON blocked_activity.pid = blocked_locks.pid;
```

## Connection Management

- Pool connections in front of the database (PgBouncer, pgpool-II, or the application pool); one connection per request does not scale past a few hundred clients.
- Size the pool to the database's real concurrency limit, not to the number of application threads.
- Use transaction pooling for short-lived connections, and session pooling only when sessions carry state (prepared statements, advisory locks, `SET`).
- Set server-side timeouts so a stalled client cannot pin a backend indefinitely.

```sql
-- Recommended session settings
SET statement_timeout = '30s';
SET lock_timeout = '10s';
SET idle_in_transaction_session_timeout = '60s';
```

## Security

- Always use parameterized queries or prepared statements; never concatenate user input into SQL.
- Do not treat escaping or input "cleaning" as a defence; a parameterized query is the only complete answer.
- Grant the least privilege the application needs; the runtime role should neither own the schema nor be a superuser, and migrations should run under a separate role.
- Encrypt data in transit (SSL/TLS) and sensitive data at rest.
- Audit and log access to sensitive tables (pgAudit or trigger-based logging).
- Use row-level security for multi-tenant isolation that must not depend on every query remembering `WHERE tenant_id = ...`.

```sql
-- Enable row-level security
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;

CREATE POLICY documents_tenant_policy ON documents
    FOR ALL
    USING (tenant_id = current_setting('app.tenant_id')::uuid);

-- Grant minimal privileges
GRANT SELECT, INSERT, UPDATE ON orders TO app_user;
GRANT USAGE ON SEQUENCE orders_order_id_seq TO app_user;
```

## Data Modification

### INSERT

- Name the columns explicitly; a `VALUES` list without one breaks silently when the table changes.
- Insert many rows in one statement instead of looping single-row inserts.
- Use `INSERT ... ON CONFLICT` (PostgreSQL) or `MERGE` (standard, SQL Server) for insert-or-update, not a select-then-write race.

```sql
INSERT INTO customers (customer_name, email, created_at)
VALUES
    ('John Doe', 'john@example.com', CURRENT_TIMESTAMP),
    ('Jane Smith', 'jane@example.com', CURRENT_TIMESTAMP);

-- Upsert (PostgreSQL)
INSERT INTO inventory (sku, quantity)
VALUES ('ABC-1', 10)
ON CONFLICT (sku) DO UPDATE
SET quantity = inventory.quantity + EXCLUDED.quantity;
```

### UPDATE

- Every `UPDATE` carries a `WHERE`; if all rows is the intent, say so in a comment and run it inside a transaction.
- Test the statement as a `SELECT` first and check the row count.
- Verify that a `FROM`-join update matches one row per target; a many-to-one join silently discards values.

### DELETE

- Every `DELETE` carries a `WHERE`.
- Prefer a soft delete (status flag or `deleted_at`) for data users may need back, and archive instead of hard-deleting.
- Check the `ON DELETE CASCADE` path before deleting a parent row; cascades are not reversible.
- Delete in batches on large tables so locks and WAL stay bounded.

## Maintenance

### Vacuum and Analyze

- Keep autovacuum enabled and tuned to the write rate; a table that is never vacuumed accumulates bloat and eventually threatens transaction-ID wraparound.
- Run `VACUUM ANALYZE` manually after bulk loads and large deletes.
- Track bloat on the largest tables and clear it with `VACUUM FULL` or `pg_repack` in a maintenance window.

```sql
-- Check table bloat
SELECT schemaname, relname,
       n_live_tup, n_dead_tup,
       round(n_dead_tup * 100.0 / nullif(n_live_tup + n_dead_tup, 0), 2) AS dead_pct
FROM pg_stat_user_tables
WHERE n_dead_tup > 1000
ORDER BY n_dead_tup DESC;
```

### Backup and Recovery

- Take a logical backup (`pg_dump`) for portability and a physical one (`pg_basebackup`) for size and speed.
- Configure WAL archiving for point-in-time recovery (PITR), and test the restore, not only the backup.
- Keep backups outside the failure domain of the database host.

## Monitoring

- Enable `pg_stat_statements` and review the slowest and the most frequent queries on a schedule.
- Watch connections, replication lag, disk usage, lock waits, and deadlocks; alert on trends, not only on fixed thresholds.
- Use `pg_stat_activity` for the current picture and `pg_stat_statements` for the accumulated one.

```sql
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Find slow queries
SELECT query, calls, mean_exec_time, total_exec_time
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 10;
```

## Naming Conventions

- Use `snake_case` for tables and columns; unquoted PostgreSQL identifiers fold to lowercase anyway.
- Pick plural or singular table names and apply it everywhere; the examples here use plural.
- Name primary keys `<table>_id` and foreign keys after the referenced key, so joins read the same in every query.
- Name booleans `is_active` / `has_shipped`, timestamps `<event>_at`, amounts `<thing>_total`.
- Keep names descriptive (`order_total`, not `ot`), and avoid reserved words.

## Documentation

- Comment the business rule a query encodes, not the syntax it uses.
- Document stored procedures and functions with purpose, parameters, side effects, and an example call.
- Maintain a data dictionary for tables, columns, and enumerated values.
- Keep schema changes in version-controlled migrations; never alter production by hand.

## Error Handling

- Handle errors at the transaction boundary and return a meaningful message to the caller instead of a raw driver error.
- Log the statement, the parameters (redacted), the SQLSTATE, and the context needed to reproduce.
- Use `RAISE EXCEPTION` and `EXCEPTION WHEN ...` in PostgreSQL `plpgsql`, `TRY ... CATCH` in SQL Server, `DECLARE ... HANDLER` in MySQL.
- Never swallow an error and commit a partial change.
