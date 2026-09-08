# docker-starter

## MariaDB configuration profiles

The four full `my.cnf` profiles under `etc/lp`, `etc/dev`, `etc/corp`, and
`etc/portal` are the source templates for sites. They share the safe fleet
policy established during the 2026-08 MariaDB tuning: query cache disabled,
realistic table/file caches, `thread_stack=512K`, and bounded temporary and
per-operation buffers.

The profile determines only the fixed working-set and connection tier:

- `lp` / `dev`: 32 MiB InnoDB pool, 10 connections;
- `corp`: 64 MiB pool, 25 connections;
- `portal`: 128 MiB pool, 50 connections.

A site with a database that needs a larger working set must receive a
separately reviewed configuration and explicit Docker memory/no-swap limits;
do not raise the shared template values for one project.
