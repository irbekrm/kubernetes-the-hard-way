#!/bin/bash

set -eux

command -v gcloud >/dev/null 2>&1 || { echo >&2 "Please install kubectl"; exit 1; }

if [ -z "$KTH_GOOGLE_APPLICATION_CREDENTIALS" ]; then
  echo "Please set KTH_GCP_CREDS to the path to your GCP service account creds (GOOGLE_APPLICATION_CREDENTIALS)"
  exit 1
fi

if [ -z "$KTH_GCP_REGION" ]; then
  echo "Please set KTH_GCP_REGION to a GCP region in which resources for this tutorial should be created"
  exit 1
fi

# Distribute the control plane startup script to all controller nodes
for instance in controller-0 controller-1 controller-2; do
   gcloud compute scp bootstrap_control_plane.sh ${instance}:/tmp/ \
   --zone "${KTH_GCP_REGION}-b"
done

# Run control plane bootstrap script on all controller nodes
gcloud compute ssh controller-0 \
--zone "${KTH_GCP_REGION}-b" \
-- '/tmp/bootstrap_control_plane.sh'

gcloud compute ssh controller-1 \
--zone "${KTH_GCP_REGION}-b" \
-- '/tmp/bootstrap_control_plane.sh'

gcloud compute ssh controller-2 \
--zone "${KTH_GCP_REGION}-b" \
-- '/tmp/bootstrap_control_plane.sh'


# Create and bind a Cluster Role that will allow kube-apiserver to talk to kubelets

gcloud compute scp rbac_for_kubelet_auth.sh controller-0:/tmp/ \
  --zone "${KTH_GCP_REGION}-b"

gcloud compute ssh controller-0 \
--zone "${KTH_GCP_REGION}-b" \
-- '/tmp/rbac_for_kubelet_auth.sh'

# Provision a Network Load Balancer

KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute addresses describe kubernetes-the-hard-way \
    --region "${KTH_GCP_REGION}" \
    --format 'value(address)')

gcloud compute http-health-checks create kubernetes \
  --description "Kubernetes Health Check" \
  --host "kubernetes.default.svc.cluster.local" \
  --request-path "/healthz"

gcloud compute firewall-rules create kubernetes-the-hard-way-allow-health-check \
    --network kubernetes-the-hard-way \
    --source-ranges 209.85.152.0/22,209.85.204.0/22,35.191.0.0/16 \
    --allow tcp

gcloud compute target-pools create kubernetes-target-pool \
  --http-health-check kubernetes \
  --region "${KTH_GCP_REGION}"

gcloud compute target-pools add-instances kubernetes-target-pool \
   --instances controller-0,controller-1,controller-2 \
   --region "${KTH_GCP_REGION}" \
   --zone "${KTH_GCP_REGION}-b"

gcloud compute forwarding-rules create kubernetes-forwarding-rule \
    --address "${KUBERNETES_PUBLIC_ADDRESS}" \
    --ports 6443 \
    --region "${KTH_GCP_REGION}" \
    --target-pool kubernetes-target-pool

