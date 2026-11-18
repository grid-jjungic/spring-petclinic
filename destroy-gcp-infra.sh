#!/usr/bin/env bash
set -euo pipefail

# Load .env variables
if [ -f .env ]; then
    set -a
    source .env
    set +a
fi

echo "Starting the deletion process..."

# Delete VMs
echo "Deleting VM: ${VM_NAME}..."
gcloud compute instances delete "${VM_NAME}" \
    --zone="${ZONE}" \
    --quiet || true

# Delete Firewalls
echo "Deleting Firewall Rules..."
gcloud compute firewall-rules delete "${FIREWALL_SSH}" --quiet || true
gcloud compute firewall-rules delete "${FIREWALL_HTTP}" --quiet || true

# Deleting reserved IP
echo "Deleting Reserved IP: ${STATIC_IP_NAME}..."
gcloud compute addresses delete "${STATIC_IP_NAME}" \
    --region="${REGION}" \
    --quiet || true

# Deleting subnet
echo "Deleting Subnet: ${SUBNET_NAME}..."
gcloud compute networks subnets delete "${SUBNET_NAME}" \
    --region="${REGION}" \
    --quiet || true

# Deleting VPC
echo "Deleting VPC Network: ${VPC_NAME}..."
gcloud compute networks delete "${VPC_NAME}" \
    --quiet || true

echo "All GCP resources deleted successfully!"
