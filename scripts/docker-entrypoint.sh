#!/bin/sh
set -e

WORKFLOWS_DIR=/home/node/workflows
N8N_USER_FOLDER="${N8N_USER_FOLDER:-/home/node/.n8n}"
BOOTSTRAP_FLAG="$N8N_USER_FOLDER/.jhound-bootstrap-done"
N8N_DB="$N8N_USER_FOLDER/.n8n/database.sqlite"

mkdir -p "$N8N_USER_FOLDER"

echo "[jhound] waiting for postgres..."
for i in $(seq 1 30); do
  if python3 -c "import os, psycopg2; psycopg2.connect(host=os.getenv('POSTGRES_HOST','postgres'), port=int(os.getenv('POSTGRES_PORT','5432')), dbname=os.getenv('POSTGRES_DB','jhound'), user=os.getenv('POSTGRES_USER','jhound'), password=os.getenv('POSTGRES_PASSWORD','')).close()" 2>/dev/null; then
    echo "[jhound] postgres ready"
    break
  fi
  sleep 1
done

# Generate bcrypt hash from plaintext password
if [ -n "${N8N_INSTANCE_OWNER_PASSWORD:-}" ]; then
  OWNER_HASH=$(python3 -c "
import bcrypt, os
pw = os.environ['N8N_INSTANCE_OWNER_PASSWORD']
print(bcrypt.hashpw(pw.encode(), bcrypt.gensalt()).decode())
")
  echo "[jhound] generated bcrypt hash for owner"
else
  OWNER_HASH=""
  echo "[jhound] N8N_INSTANCE_OWNER_PASSWORD not set — skipping owner env setup"
fi

# Export n8n instance owner env vars (native n8n v2.17+ feature)
export N8N_INSTANCE_OWNER_MANAGED_BY_ENV=true
export N8N_INSTANCE_OWNER_EMAIL="${N8N_INSTANCE_OWNER_EMAIL:-mubarak@codeswot.me}"
export N8N_INSTANCE_OWNER_FIRST_NAME="${N8N_INSTANCE_OWNER_FIRST_NAME:-Mubarak}"
export N8N_INSTANCE_OWNER_LAST_NAME="${N8N_INSTANCE_OWNER_LAST_NAME:-Ibrahim}"
export N8N_INSTANCE_OWNER_PASSWORD_HASH="${OWNER_HASH}"

# Workflow import (once)
if [ -f "$BOOTSTRAP_FLAG" ]; then
  echo "[jhound] bootstrap already done"
else
  echo "[jhound] starting n8n briefly to import workflows..."
  n8n start &
  N8N_PID=$!
  for i in $(seq 1 60); do
    if curl -sf http://localhost:5678/healthz >/dev/null 2>&1; then break; fi
    sleep 1
  done

  if [ -d "$WORKFLOWS_DIR" ] && ls "$WORKFLOWS_DIR"/*.json >/dev/null 2>&1; then
    echo "[jhound] importing workflows from $WORKFLOWS_DIR..."
    import_failed=0
    for wf_file in "$WORKFLOWS_DIR"/*.json; do
      wf_name=$(basename "$wf_file")
      tmp=$(mktemp -d)
      cp "$wf_file" "$tmp/"
      if n8n import:workflow --separate --input="$tmp" 2>&1 | grep -qE "Successfully imported"; then
        echo "[jhound] imported $wf_name"
      else
        echo "[jhound] FAILED to import $wf_name" >&2
        import_failed=1
      fi
      rm -rf "$tmp"
    done

    if [ "$import_failed" -eq 0 ] && [ -f "$N8N_DB" ]; then
      activated=$(python3 -c "
import sqlite3, sys
conn = sqlite3.connect('$N8N_DB')
cur = conn.cursor()
cur.execute('UPDATE workflow_entity SET active = 1, activeVersionId = versionId WHERE activeVersionId IS NULL OR active = 0')
sys.stdout.write(str(cur.rowcount))
conn.commit()
conn.close()
")
      echo "[jhound] activated $activated workflows via sqlite"
    fi
    touch "$BOOTSTRAP_FLAG"
    echo "[jhound] bootstrap complete"
  fi

  kill $N8N_PID 2>/dev/null || true
  wait $N8N_PID 2>/dev/null || true
  sleep 2
fi

# Start Nostr inbound listener in background (if NOSTR_NSEC is set)
if [ -n "${NOSTR_NSEC:-}" ] && [ -n "${NOSTR_TARGET_NPUB:-}" ]; then
  echo "[jhound] starting Nostr DM listener (after webhook is ready)..."
  (
    for i in $(seq 1 180); do
      code=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:5678/webhook/jhound-nostr-inbound -H "Content-Type: application/json" -d '{"from":"_boot_probe","text":"_probe","id":"_probe"}' 2>/dev/null || echo "000")
      if [ "$code" = "200" ]; then
        echo "[jhound] webhook ready (HTTP 200), launching Nostr listener"
        break
      fi
      sleep 1
    done
    exec node /home/node/scripts/nostr_notifier.js listen
  ) &
fi

echo "[jhound] starting n8n..."
exec n8n start
