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

gcloud compute forwarding-rules delete kubernetes-forwarding-rule \
  --region "${KTH_GCP_REGION}"
  
gcloud compute target-pools delete kubernetes-target-pool \
  --region "${KTH_GCP_REGION}"

gcloud compute firewall-rules delete kubernetes-the-hard-way-allow-health-check

gcloud compute http-health-checks delete kubernetes


