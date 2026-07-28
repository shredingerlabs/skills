# Database approach (T-K08)

**Decision: no database.** If the project ever needs one, use **SQLite + raw SQL + versioned `.sql` files**.

## Why no database today

The `shredingerlabs/skills` repo is a collection of skills, ADRs, and a small test
project. Its only stateful actor is `scripts/afkLoop.sh`, a stateless driver that
walks GitHub Issues one at a time. The issue tracker — accessed through the
`gh` CLI — **is** the database: it is the source of truth for ticket state,
labels, comments, and dependencies. A separate DB would duplicate that state,
introduce sync drift, and add operational cost (backups, migrations, a server
process) with no concrete feature that needs it.

The test project in `tests/afkLoop/` is similarly stateless: `main.sh` prints
a greeting, `test.sh` runs assertions, no data is written to disk between runs.

## If a database is ever needed

1. **SQLite over PostgreSQL.** Single file, no server, fits a bash-driven
   project. PostgreSQL's advantages (concurrency, JSON indexing, replication)
   are not needed at this scale and would require a separate process the AFK
   loop would have to manage.
2. **Raw SQL over an ORM.** The surface area is small. An ORM (Prisma, Drizzle,
   SQLAlchemy, etc.) would add a build step, a language dependency, and a
   learning surface for what is at most a handful of tables. Raw SQL via
   `sqlite3` (already available on most Linux/macOS systems, including the
   dev image used by this repo) is the simplest thing that works.
3. **Versioned `.sql` migration files.** One file per change, named
   `NNNN-short-name.sql` (e.g. `0001-create-issues.sql`), applied in order by
   a tiny runner that records applied versions in a `_migrations` table. No
   external migration tool — a 30-line bash or Python script is enough.

## Revisit when

A decision like this is invalidated by a concrete feature, not by speculation.
Triggers that would force a revisit:

- A new component needs to hold state across process boundaries and that
  state cannot live in the issue tracker (e.g. telemetry, rate-limit caches,
  long-running job state).
- Concurrent writers from multiple machines/processes (single-file SQLite
  cannot safely serve that without WAL + careful locking).
- Query patterns that the issue tracker cannot satisfy (cross-issue joins,
  aggregations over thousands of tickets, full-text search).

Until one of those shows up, the answer stays "no database."
