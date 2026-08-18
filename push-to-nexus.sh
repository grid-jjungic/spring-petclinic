#!/usr/bin/env bash
set -eu

# Configuring variables
NEXUS_HOST="host.docker.internal:8082"
NEXUS_USER="admin"
NEXUS_REPO="docker-private"
IMAGE_NAME="spring-petclinic"
IMAGE_TAG="v1.0"
PLATFORMS="linux/amd64,linux/arm64"

# Making Nexus URI
NEXUS_IMAGE_URI="${NEXUS_HOST}/repository/${NEXUS_REPO}/${IMAGE_NAME}:${IMAGE_TAG}"

echo "[1/2] Authenticating to Nexus at ${NEXUS_HOST}..."
read -rsp "Enter Nexus Password for ${NEXUS_USER}: " NEXUS_PASSWORD
echo ""
echo "$NEXUS_PASSWORD" | docker login "$NEXUS_HOST" -u "$NEXUS_USER" --password-stdin

echo "[2/2] Building and pushing multi-architecture image to Nexus..."
docker buildx build \
    --platform "$PLATFORMS" \
    -t "$NEXUS_IMAGE_URI" \
    --push .

echo "SUCCESS: Multi-architecture image pushed to ${NEXUS_IMAGE_URI}"
