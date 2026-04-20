# n8n + PostgreSQL/pgvector + Redis + Evolution API for Docker Desktop

A ready-to-run local stack for building WhatsApp AI agents with:

- `n8n` for workflow orchestration
- `PostgreSQL + pgvector` for RAG and vector search
- `Redis` for memory, buffering, and cache
- `Evolution API` for WhatsApp connectivity

This project is designed for `Docker Desktop` on both `Windows` and `macOS` and can be started with a single command.

## What You Get

- Local `n8n` instance connected to PostgreSQL
- `PostgreSQL` with `pgvector` enabled
- Persistent `Redis`
- Local `Evolution API` connected to PostgreSQL and Redis
- Separate databases for:
  - `n8n`
  - `evolution`
  - `rag`
- Persistent Docker volumes
- Health checks for all services
- A starter structure you can adapt for your own AI agent workflows

## Stack Overview

```text
WhatsApp
  -> Evolution API
  -> n8n
  -> Redis
  -> PostgreSQL / pgvector
```

Typical use case:

- receive WhatsApp messages through Evolution API
- process them in n8n
- store/retrieve context in Redis
- retrieve company knowledge from PostgreSQL vector data
- send a reply back through Evolution API

## Requirements

- Docker Desktop installed
- Docker Desktop running
- `docker compose` available

Quick check:

```bash
docker --version
docker compose version
```

## Quick Start

1. Clone this repository:

```bash
git clone https://github.com/Hanaede/docker-n8n-evolution-stack.git
cd docker-n8n-evolution-stack
```

2. Copy the environment template:

```bash
cp .env.example .env
```

3. Edit `.env` and change at least:

- `POSTGRES_PASSWORD`
- `N8N_ENCRYPTION_KEY`
- `AUTHENTICATION_API_KEY`
- `TZ` if needed

4. Start the stack:

```bash
docker compose up -d
```

5. Check the containers:

```bash
docker compose ps
```

## Service URLs

- `n8n`: http://localhost:5678
- `Evolution API`: http://localhost:8080
- `PostgreSQL`: localhost:5432
- `Redis`: localhost:6379

## First Run

### n8n

Open:

```text
http://localhost:5678
```

Create the owner account in the browser on first launch.

### Evolution API

Open:

```text
http://localhost:8080
```

Create or open your WhatsApp instance, then generate the QR code and scan it with WhatsApp.

## Databases Created Automatically

On first startup, PostgreSQL creates:

- `n8n`
- `evolution`
- `rag`

It also:

- enables `vector` in `n8n`
- enables `vector` in `rag`
- creates a starter table in `rag`:
  - `rag_embeddings`

This makes the stack ready for vector-based retrieval from day one.

## Internal Docker Hostnames

Inside Docker, services talk to each other by container service name:

- `postgres`
- `redis`
- `n8n`
- `evolution-api`

This is important for webhook setup and inter-service HTTP calls.

### Example

From your host machine:

- `http://localhost:5678`

From the Evolution API container:

- `http://n8n:5678`

Do not use `localhost` between containers.

## n8n Connection Settings

### PostgreSQL for RAG

If you create a PostgreSQL credential in n8n for vector search:

- Host: `postgres`
- Port: `5432`
- Database: value of `RAG_POSTGRES_DB`
- User: value of `POSTGRES_USER`
- Password: value of `POSTGRES_PASSWORD`

### Redis for memory or cache

- Host: `redis`
- Port: `6379`

### Evolution API from n8n

Use:

- Base URL: `http://evolution-api:8080`
- Header: `apikey: <AUTHENTICATION_API_KEY>`

## Evolution API Webhook Setup

If you want Evolution API to send incoming WhatsApp messages to n8n:

- Production webhook URL:
  - `http://n8n:5678/webhook/evolution-incoming`
- Test webhook URL:
  - `http://n8n:5678/webhook-test/evolution-incoming`

Important:

- Use `localhost` only from your browser on your own machine
- Use `n8n` from one container to another

## Daily Commands

Start or recreate:

```bash
docker compose up -d
```

Stop:

```bash
docker compose stop
```

View all logs:

```bash
docker compose logs -f
```

View logs for one service:

```bash
docker compose logs -f n8n
docker compose logs -f evolution-api
docker compose logs -f postgres
docker compose logs -f redis
```

Restart one service:

```bash
docker compose restart n8n
```

Stop and remove containers without deleting data:

```bash
docker compose down
```

Stop and remove everything including volumes:

```bash
docker compose down -v
```

## Verification

### Check stack health

```bash
docker compose ps
```

### Check Redis

```bash
docker compose exec redis redis-cli ping
```

Expected output:

```text
PONG
```

### Check pgvector

```bash
docker compose exec postgres psql -U postgres -d rag -c "\dx"
docker compose exec postgres psql -U postgres -d rag -c "\d+ rag_embeddings"
```

### Check Evolution API

```bash
curl http://localhost:8080
```

### Check n8n

```bash
curl http://localhost:5678/healthz/readiness
```

## Troubleshooting

### QR code does not appear in Evolution API

If QR generation does not work, make sure you are not using an old Evolution API image.

This project uses a newer Evolution API image branch to avoid known QR/reconnection issues.

### Evolution webhook does not trigger n8n

Most common cause:

- webhook URL in Evolution is set to `http://localhost:5678/...`

That is wrong from inside Docker.

Use:

- `http://n8n:5678/webhook/evolution-incoming`

### I can open n8n in the browser, but containers cannot reach it

That is expected if you use `localhost`.

Use the Docker service name:

- `n8n`

### Port already in use

Change the port values in `.env`:

- `N8N_PORT`
- `POSTGRES_PORT`
- `REDIS_PORT`
- `EVOLUTION_PORT`

Then restart:

```bash
docker compose down
docker compose up -d
```

### Reset everything

```bash
docker compose down -v
```

Then start again:

```bash
docker compose up -d
```

## Project Structure

```text
.
├── .env.example
├── docker-compose.yml
├── README.md
└── docker
    └── postgres
        └── init
            └── 01-init.sh
```

## Notes

- This project is for local development and self-hosted testing
- It is not production-hardened by default
- n8n owner setup is completed in the browser on first launch
- Secrets should always be customized in `.env`

## Recommended Next Steps

After the stack is running, you can:

- create your WhatsApp instance in Evolution API
- configure an incoming webhook from Evolution to n8n
- create n8n credentials for:
  - OpenAI
  - PostgreSQL
  - Redis
  - Google Calendar
- build an AI agent workflow with:
  - Redis buffering
  - PostgreSQL vector retrieval
  - Google Calendar scheduling
  - Evolution API replies

## License

MIT

## References

- [n8n Docker Compose docs](https://docs.n8n.io/hosting/installation/server-setups/docker-compose/)
- [n8n database environment variables](https://docs.n8n.io/hosting/configuration/environment-variables/database/)
- [n8n monitoring and health endpoints](https://docs.n8n.io/hosting/logging-monitoring/monitoring/)
- [Evolution API documentation](https://doc.evolution-api.com/)
- [pgvector](https://github.com/pgvector/pgvector)
- [Redis official image](https://hub.docker.com/_/redis/)
