#!/usr/bin/env bash
set -euo pipefail

echo 'Checking if VM startup script has finished...'
  while sudo systemctl is-active google-startup-scripts.service | grep -q 'activating'; do
    echo 'Startup script is still installing Docker, sleeping 5 seconds...'
    sleep 5
  done

REGISTRY_HOST=$(echo "${GCR_TAG}" | cut -d'/' -f1)

echo 'Authenticating Docker...'
sudo gcloud auth configure-docker ${REGISTRY_HOST} --quiet

echo 'Pulling image...'
sudo docker pull ${GCR_TAG}

echo 'Starting new container...'
sudo docker run -d \
  --name petclinic \
  --restart unless-stopped \
  -p 8080:8080 \
  ${GCR_TAG}

echo 'Container started successfully'
