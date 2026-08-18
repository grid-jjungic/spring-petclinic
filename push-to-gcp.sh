#!/usr/bin/env bash
set -eu

# Load .env
if [ -f .env ]; then
    set -a
    source .env
    set +a
fi

# Validate GCP environment variables
if [ -z "${GCP_REGION:-}" ]; then
    echo "Error: GCP_REGION is not set in .env or environment" >&2
    exit 1
fi

if [ -z "${GCP_PROJECT:-}" ]; then
    echo "Error: GCP_PROJECT is not set in .env or environment" >&2
    exit 1
fi

if [ -z "${GCP_REPO:-}" ]; then
    echo "Error: GCP_REPO is not set in .env or environment" >&2
    exit 1
fi

IMAGE_NAME="spring-petclinic"
IMAGE_TAG="v1.0"
PLATFORMS="linux/amd64,linux/arm64"

# Making GCP URI
GCP_IMAGE_URI="${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT}/${GCP_REPO}/${IMAGE_NAME}:${IMAGE_TAG}"

echo "[1/2] Authenticating to GAR ${GCP_REGION}-docker.pkg.dev..."
gcloud auth print-access-token | docker login -u oauth2accesstoken --password-stdin "https://${GCP_REGION}-docker.pkg.dev"

echo "[2/2] Building and pushing multi-architecture image to GAR..."
docker buildx build \
    --platform "$PLATFORMS" \
    -t "$GCP_IMAGE_URI" \
    --push .

echo "SUCCESS: Multi-architecture image pushed to ${GCP_IMAGE_URI}"
