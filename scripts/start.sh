#!/bin/bash
set -e

echo "Levantando entorno completo..."

docker compose up -d --build

echo "Todo corriendo"
