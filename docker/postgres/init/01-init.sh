#!/bin/sh
set -eu

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-SQL
  SELECT 'CREATE DATABASE "${N8N_POSTGRES_DB}"'
  WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '${N8N_POSTGRES_DB}')\gexec

  SELECT 'CREATE DATABASE "${EVOLUTION_POSTGRES_DB}"'
  WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '${EVOLUTION_POSTGRES_DB}')\gexec

  SELECT 'CREATE DATABASE "${RAG_POSTGRES_DB}"'
  WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '${RAG_POSTGRES_DB}')\gexec
SQL

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$N8N_POSTGRES_DB" <<-'SQL'
  CREATE EXTENSION IF NOT EXISTS vector;
SQL

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$RAG_POSTGRES_DB" <<-'SQL'
  CREATE EXTENSION IF NOT EXISTS vector;

  CREATE TABLE IF NOT EXISTS rag_embeddings (
    id bigserial PRIMARY KEY,
    source text NOT NULL,
    content text NOT NULL,
    embedding vector(1536),
    metadata jsonb DEFAULT '{}'::jsonb,
    created_at timestamptz NOT NULL DEFAULT now()
  );
SQL

