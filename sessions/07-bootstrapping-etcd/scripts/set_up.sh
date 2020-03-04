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

# Distribute the etcd bootstrap script to all controller nodes
for instance in controller-0 controller-1 controller-2; do
   gcloud compute scp bootstrap_etcd.sh ${instance}:/tmp/ \
   --zone "${KTH_GCP_REGION}-b"
done

# Run etcd bootstrap script on all controller nodes
gcloud compute ssh controller-0 \
--zone "${KTH_GCP_REGION}-b" \
-- '/tmp/bootstrap_etcd.sh'

gcloud compute ssh controller-1 \
--zone "${KTH_GCP_REGION}-b" \
-- '/tmp/bootstrap_etcd.sh'

gcloud compute ssh controller-2 \
--zone "${KTH_GCP_REGION}-b" \
-- '/tmp/bootstrap_etcd.sh'
  