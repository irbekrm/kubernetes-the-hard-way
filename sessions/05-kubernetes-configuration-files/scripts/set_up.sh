#!/bin/bash

set -eux

command -v kubectl >/dev/null 2>&1 || { echo >&2 "Please install kubectl"; exit 1; }
command -v gcloud >/dev/null 2>&1 || { echo >&2 "Please install kubectl"; exit 1; }


if [ -z "$KTH_GOOGLE_APPLICATION_CREDENTIALS" ]; then
  echo "Please set KTH_GCP_CREDS to the path to your GCP service account creds (GOOGLE_APPLICATION_CREDENTIALS)"
  exit 1
fi

if [ -z "$KTH_GCP_REGION" ]; then
  echo "Please set KTH_GCP_REGION to a GCP region in which resources for this tutorial should be created"
  exit 1
fi


CURRENT_PATH=$(pwd)
WORKING_DIR=/tmp/kthw-certs

source "${CURRENT_PATH}/all_the_kubeconfigs/kubelet_kubeconfig.sh"
source "${CURRENT_PATH}/all_the_kubeconfigs/kube_proxy_kubeconfig.sh"
source "${CURRENT_PATH}/all_the_kubeconfigs/kube_controller_manager_kubeconfig.sh"
source "${CURRENT_PATH}/all_the_kubeconfigs/kube_scheduler_kubeconfig.sh"
source "${CURRENT_PATH}/all_the_kubeconfigs/admin_kubeconfig.sh"

KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute addresses describe kubernetes-the-hard-way \
  --region "$KTH_GCP_REGION" \
  --format 'value(address)')

cd $WORKING_DIR

# Create kubeconfig for kubelets
create_kubelet_kubeconfig

# Create kubeconfig for kube-proxy
create_kube_proxy_kubeconfig

# Create kubeconfig for kube-controller-manager
create_kube_controller_manager_kubeconfig

# Create kubeconfig for kube-scheduler
create_kube_scheduler_kubeconfig

# Create kubernetes admin user kubeconfig
create_admin_kubeconfig

# Copy kubelet and kube-proxy kubeconfig to each worker instance
for instance in worker-0 worker-1 worker-2; do
  gcloud compute scp ${instance}.kubeconfig kube-proxy.kubeconfig ${instance}:~/ \
  --zone "${KTH_GCP_REGION}-b"
done

# Copy kube-controller-manager, kube-scheduler and kubernetes admin user kubeconfigs
# to each controller instance
for instance in controller-0 controller-1 controller-2; do
  gcloud compute scp admin.kubeconfig kube-controller-manager.kubeconfig kube-scheduler.kubeconfig ${instance}:~/ \
--zone "${KTH_GCP_REGION}-b"
done








