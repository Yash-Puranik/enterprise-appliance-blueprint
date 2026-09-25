#!/usr/bin/env bash

set -euo pipefail

# Go directly to the root of the project to avoid issues with relative paths. Teleports this file anywhere into this dir.

cd "$(dirname "$0")/.."

if [ ! -f .env ]; then
    echo "Error: Configuration file .env not found in project root." >&2
    exit 1
fi

set -a
source .env
set +a


