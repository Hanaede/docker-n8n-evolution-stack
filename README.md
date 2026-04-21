# n8n + PostgreSQL/pgvector + Redis + Evolution API para Docker Desktop

Un stack local listo para usar y crear agentes de IA por WhatsApp con:

- `n8n` para la orquestación de workflows
- `PostgreSQL + pgvector` para RAG y búsqueda vectorial
- `Redis` para memoria, buffering y caché
- `Evolution API` para la conectividad con WhatsApp
- `Adminer` como interfaz visual para PostgreSQL

Este proyecto está pensado para `Docker Desktop` tanto en `Windows` como en `macOS` y se puede levantar con un solo comando.

## Qué incluye

- Instancia local de `n8n` conectada a PostgreSQL
- `PostgreSQL` con `pgvector` habilitado
- `Redis` persistente
- `Evolution API` local conectada a PostgreSQL y Redis
- `Adminer` para explorar y editar la base de datos desde el navegador
- Bases de datos separadas para:
  - `n8n`
  - `evolution`
  - `rag`
- Volúmenes persistentes de Docker
- Health checks en todos los servicios
- Una base inicial para que adaptes tus propios workflows de agente IA
- Carpeta `workflows/` con workflows listos para importar en n8n

## Arquitectura del stack

```text
WhatsApp
  -> Evolution API
  -> n8n
  -> Redis
  -> PostgreSQL / pgvector
```

Caso de uso típico:

- recibir mensajes de WhatsApp a través de Evolution API
- procesarlos en n8n
- guardar o recuperar contexto en Redis
- consultar conocimiento de empresa en PostgreSQL vectorial
- enviar la respuesta de vuelta por Evolution API

## Requisitos

- Docker Desktop instalado
- Docker Desktop iniciado
- `docker compose` disponible

Comprobación rápida:

```bash
docker --version
docker compose version
```

## Inicio rápido

1. Clona este repositorio:

```bash
git clone https://github.com/Hanaede/docker-n8n-evolution-stack.git
cd docker-n8n-evolution-stack
```

2. Copia la plantilla de entorno:

```bash
cp .env.example .env
```

3. Edita `.env` y cambia al menos:

- `POSTGRES_PASSWORD`
- `N8N_ENCRYPTION_KEY`
- `AUTHENTICATION_API_KEY`
- `TZ` si lo necesitas

4. Levanta el stack:

```bash
docker compose up -d
```

5. Comprueba los contenedores:

```bash
docker compose ps
```

## URLs de los servicios

- `n8n`: http://localhost:5678
- `Evolution API`: http://localhost:8080
- `Adminer`: http://localhost:8081
- `PostgreSQL`: localhost:5432
- `Redis`: localhost:6379

## Primera puesta en marcha

### n8n

Abre:

```text
http://localhost:5678
```

Crea la cuenta owner desde el navegador en el primer acceso.

### Evolution API

Abre:

```text
http://localhost:8080
```

Crea o abre tu instancia de WhatsApp, genera el QR y escanéalo con WhatsApp.

### Adminer

Abre:

```text
http://localhost:8081
```

Y usa estos datos para entrar a PostgreSQL:

- Sistema: `PostgreSQL`
- Servidor: `postgres`
- Usuario: valor de `POSTGRES_USER`
- Contraseña: valor de `POSTGRES_PASSWORD`
- Base de datos: `rag` o la que quieras inspeccionar

## Bases de datos creadas automáticamente

En el primer arranque, PostgreSQL crea:

- `n8n`
- `evolution`
- `rag`

Además:

- habilita `vector` en `n8n`
- habilita `vector` en `rag`
- crea una tabla inicial en `rag`:
  - `rag_embeddings`

Esto deja el stack preparado para recuperación vectorial desde el primer día.

## Hostnames internos de Docker

Dentro de Docker, los servicios se comunican entre sí por el nombre del servicio:

- `postgres`
- `redis`
- `n8n`
- `evolution-api`

Esto es importante para webhooks y llamadas HTTP entre contenedores.

### Ejemplo

Desde tu máquina:

- `http://localhost:5678`

Desde el contenedor de Evolution API:

- `http://n8n:5678`

No uses `localhost` entre contenedores.

## Configuración de conexiones en n8n

### PostgreSQL para RAG

Si creas una credencial PostgreSQL en n8n para búsqueda vectorial:

- Host: `postgres`
- Puerto: `5432`
- Base de datos: valor de `RAG_POSTGRES_DB`
- Usuario: valor de `POSTGRES_USER`
- Contraseña: valor de `POSTGRES_PASSWORD`

### Adminer para acceso visual

Si quieres explorar o editar la base en tiempo real desde el navegador:

- URL: `http://localhost:8081`
- Sistema: `PostgreSQL`
- Servidor: `postgres`
- Usuario: valor de `POSTGRES_USER`
- Contraseña: valor de `POSTGRES_PASSWORD`
- Base de datos recomendada para RAG: valor de `RAG_POSTGRES_DB`

### Redis para memoria o caché

- Host: `redis`
- Puerto: `6379`

### Evolution API desde n8n

Usa:

- Base URL: `http://evolution-api:8080`
- Header: `apikey: <AUTHENTICATION_API_KEY>`

## Workflows 

### PDF a RAG con OpenAI y PGVector

Este workflow hace lo siguiente:

- recibe un PDF desde un formulario web de n8n
- extrae el contenido del PDF
- lo divide en fragmentos
- genera embeddings con OpenAI
- guarda los fragmentos y embeddings en PostgreSQL/pgvector


También puedes importarlo manualmente desde la interfaz de n8n con `Import from File`.

#### Configuración necesaria en n8n

Antes de activarlo, asigna estas credenciales:

- `Embeddings OpenAI`
  - tu API key de OpenAI
- `Postgres PGVector Store`
  - Host: `postgres`
  - Puerto: `5432`
  - Base de datos: `rag`
  - Usuario: valor de `POSTGRES_USER`
  - Contraseña: valor de `POSTGRES_PASSWORD`

#### Cómo usarlo

1. Activa el workflow en n8n.
2. Abre el nodo `Formulario de Subida PDF`.
3. Copia la `Production URL`.
4. Abre esa URL en el navegador.
5. Sube un PDF.

El workflow creará o reutilizará la tabla `n8n_rag_documents` dentro de la base `rag`.

#### Verificar los datos cargados

Puedes revisar el resultado desde Adminer o con SQL:

```sql
SELECT id, text, metadata
FROM n8n_rag_documents
LIMIT 10;
```

Para comprobar que los embeddings existen:

```sql
SELECT id, embedding IS NOT NULL AS tiene_embedding
FROM n8n_rag_documents
LIMIT 10;
```

### Evolution WhatsApp RAG Calendar Agent


Este workflow está orientado a atención por WhatsApp con IA y hace lo siguiente:

- recibe mensajes entrantes desde Evolution API por webhook
- agrupa mensajes del mismo usuario dentro de una ventana de 5 segundos usando Redis
- mantiene memoria conversacional en Redis
- consulta la base vectorial local en PostgreSQL/pgvector como herramienta RAG
- usa un `MCP Client Tool` para conectar con un servidor MCP de Google Calendar
- responde al usuario por WhatsApp a través de Evolution API

#### Qué necesitas configurar

Antes de activarlo:

- `OpenAI Chat Model`
  - credencial de OpenAI
- `Embeddings OpenAI`
  - credencial de OpenAI
- `Redis Chat Memory`
  - credencial Redis apuntando a `redis:6379`
- `RAG Company Knowledge`
  - credencial PostgreSQL apuntando a:
    - Host: `postgres`
    - Puerto: `5432`
    - Base de datos: `rag`
    - Usuario: valor de `POSTGRES_USER`
    - Contraseña: valor de `POSTGRES_PASSWORD`
- `Google Calendar MCP Tool`
  - endpoint real de tu servidor MCP para Google Calendar
- `Normalize Evolution Message`
  - sustituir `evolutionApiKey: 'change-me'` por tu API key real de Evolution
  - si lo necesitas, ajustar `googleCalendarMcpUrl`

#### Configurar Evolution para este workflow

Cuando el workflow esté activo, usa su webhook de producción como URL en Evolution.

Path del webhook:

- `evolution-whatsapp-agent`

Si Evolution y n8n están en la misma red Docker, la URL interna será:

```text
http://n8n:5678/webhook/evolution-whatsapp-agent
```

#### Qué hace el buffer de Redis

Este workflow guarda temporalmente el texto del usuario en Redis y espera 5 segundos.
Si el usuario manda varios mensajes seguidos, solo la última ejecución continúa y procesa el mensaje combinado.

Eso ayuda a que el agente responda con el contexto completo en vez de reaccionar línea por línea.

## Configuración del webhook de Evolution API

Si quieres que Evolution API envíe mensajes entrantes de WhatsApp a n8n:

- URL de producción:
  - `http://n8n:5678/webhook/evolution-incoming`
- URL de test:
  - `http://n8n:5678/webhook-test/evolution-incoming`

Importante:

- Usa `localhost` solo desde tu navegador en tu propia máquina
- Usa `n8n` para comunicar un contenedor con otro

## Comandos del día a día

Arrancar o recrear:

```bash
docker compose up -d
```

Parar:

```bash
docker compose stop
```

Ver todos los logs:

```bash
docker compose logs -f
```

Ver logs de un servicio:

```bash
docker compose logs -f n8n
docker compose logs -f evolution-api
docker compose logs -f postgres
docker compose logs -f redis
```

Reiniciar un servicio:

```bash
docker compose restart n8n
```

Parar y borrar contenedores sin eliminar datos:

```bash
docker compose down
```

Parar y borrar todo, incluidos volúmenes:

```bash
docker compose down -v
```

## Verificación

### Comprobar el estado del stack

```bash
docker compose ps
```

### Comprobar Redis

```bash
docker compose exec redis redis-cli ping
```

Salida esperada:

```text
PONG
```

### Comprobar pgvector

```bash
docker compose exec postgres psql -U postgres -d rag -c "\dx"
docker compose exec postgres psql -U postgres -d rag -c "\d+ rag_embeddings"
```

### Comprobar Evolution API

```bash
curl http://localhost:8080
```

### Comprobar Adminer

Abre:

```text
http://localhost:8081
```

### Comprobar n8n

```bash
curl http://localhost:5678/healthz/readiness
```

## Solución de problemas

### El QR no aparece en Evolution API

Si el QR no se genera, asegúrate de no estar usando una imagen antigua de Evolution API.

Este proyecto usa una rama de imagen más nueva para evitar errores conocidos de QR y reconexión.

### El webhook de Evolution no dispara n8n

La causa más común es esta:

- la URL del webhook en Evolution está configurada como `http://localhost:5678/...`

Eso es incorrecto dentro de Docker.

Usa:

- `http://n8n:5678/webhook/evolution-incoming`

### Puedo abrir n8n en el navegador, pero los contenedores no llegan a él

Es normal si estás usando `localhost`.

Usa el nombre del servicio Docker:

- `n8n`

### El puerto ya está ocupado

Cambia los valores en `.env`:

- `N8N_PORT`
- `POSTGRES_PORT`
- `REDIS_PORT`
- `EVOLUTION_PORT`

Después reinicia:

```bash
docker compose down
docker compose up -d
```

### Quiero resetearlo todo

```bash
docker compose down -v
```

Luego vuelve a levantarlo:

```bash
docker compose up -d
```

## Estructura del proyecto

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

## Notas

- Este proyecto está pensado para desarrollo local y pruebas self-hosted
- No viene endurecido para producción
- El owner de n8n se crea desde el navegador en el primer arranque
- Los secretos deben personalizarse siempre en `.env`

## Siguientes pasos recomendados

Cuando el stack esté funcionando, puedes:

- crear tu instancia de WhatsApp en Evolution API
- configurar un webhook de entrada desde Evolution hacia n8n
- crear credenciales en n8n para:
  - OpenAI
  - PostgreSQL
  - Redis
  - Google Calendar
- construir un workflow de agente IA con:
  - buffering en Redis
  - recuperación vectorial en PostgreSQL
  - agenda en Google Calendar
  - respuestas por Evolution API

## Licencia

MIT

## Referencias

- [Documentación de n8n con Docker Compose](https://docs.n8n.io/hosting/installation/server-setups/docker-compose/)
- [Variables de entorno de base de datos en n8n](https://docs.n8n.io/hosting/configuration/environment-variables/database/)
- [Health endpoints y monitorización de n8n](https://docs.n8n.io/hosting/logging-monitoring/monitoring/)
- [Documentación de Evolution API](https://doc.evolution-api.com/)
- [pgvector](https://github.com/pgvector/pgvector)
- [Imagen oficial de Redis](https://hub.docker.com/_/redis/)
