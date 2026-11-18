#!/usr/bin/env bash
set -euo pipefail

# THIS SCRIPT IS MEANT TO BE RAN FROM A HOST LAPTOP
# NOT FROM A VM INSIDE THE CLOUD

# Load .env
if [ -f .env ]; then
    set -a
    source .env
    set +a
fi

echo "Enabling compute API."
gcloud services enable compute.googleapis.com

echo "Creating VPC"
gcloud compute networks create "${VPC_NAME}" --subnet-mode=custom

echo "Creating subnet"
gcloud compute networks subnets create "${SUBNET_NAME}" \
    --network="${VPC_NAME}" \
    --region="${REGION}" \
    --range="${SUBNET_CIDR}"

echo "Reserving IP"
gcloud compute addresses create "${STATIC_IP_NAME}" --region="${REGION}"

PUBLIC_IP=$(gcloud compute addresses describe "${STATIC_IP_NAME}" --region="${REGION}" --format="value(address)")
echo "Reserved Public IP: ${PUBLIC_IP}"

# Getting the host IP address, to only access it from host.
HOST_IP=$(curl ifconfig.me)

echo "Adding firewall rules."
# SSH access
gcloud compute firewall-rules create "${FIREWALL_SSH}" \
    --network="${VPC_NAME}" \
    --allow=tcp:22 \
    --source-ranges="${HOST_IP}/32" \
    --target-tags=jovan-petclinic-server

# Web access
gcloud compute firewall-rules create "${FIREWALL_HTTP}" \
    --network="${VPC_NAME}" \
    --allow=tcp:8080 \
    --source-ranges="${HOST_IP}/32" \
    --target-tags=jovan-petclinic-server


echo "Provisioning a VM with deps installed"
gcloud compute instances create "${VM_NAME}" \
    --zone="${ZONE}" \
    --machine-type="e2-medium" \
    --subnet="${SUBNET_NAME}" \
    --address="${PUBLIC_IP}" \
    --tags=jovan-petclinic-server \
    --scopes=cloud-platform \
    --image-family="ubuntu-2204-lts" \
    --image-project="ubuntu-os-cloud" \
    --metadata-from-file=startup-script=startup.sh

echo "Waiting 90 seconds for SSH and OS to become available"
sleep 90

echo "Deploying application on VM"
gcloud compute ssh "${VM_NAME}" --zone="${ZONE}" \
  --command="GCR_TAG='${GCR_TAG}' bash -s" < docker-startup.sh

echo "Infra setup complete, VM IP: http://${PUBLIC_IP}:8080"
