#!/bin/bash -Eeu

readonly ROOT_DIR="$(cd "$(dirname "${0}")/.." && pwd)"
source "${ROOT_DIR}/sh/augmented-docker-compose.sh"

augmented_docker_compose \
  down \
  --remove-orphans \
  --volumes
