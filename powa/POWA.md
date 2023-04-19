```
CREATE DATABASE powa;
\c powa

CREATE EXTENSION pg_stat_statements;
CREATE EXTENSION btree_gist;
CREATE EXTENSION powa;
CREATE EXTENSION pg_qualstats;
CREATE EXTENSION pg_stat_kcache;
CREATE EXTENSION hypopg;
-- CREATE EXTENSION pg_wait_sampling;

CREATE ROLE powa LOGIN PASSWORD 'dgCn2NkUXB8izH';

GRANT SELECT ON ALL TABLES IN SCHEMA public TO powa;
GRANT SELECT ON pg_statistic TO powa;
```
