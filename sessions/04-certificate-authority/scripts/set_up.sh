#!/bin/bash

set -ex

command -v cfssl >/dev/null 2>&1 || { echo >&2 "Please install cfssl"; exit 1; }
command -v cfssljson >/dev/null 2>&1 || { echo >&2 "Please install cfssljson"; exit 1; }

if [ -z "$KTH_GOOGLE_APPLICATION_CREDENTIALS" ]; then
  echo "Please set KTH_GCP_CREDS to the path to your GCP service account creds (GOOGLE_APPLICATION_CREDENTIALS)"
  exit 1
fi

if [ -z "$KTH_GCP_REGION" ]; then
  echo "Please set KTH_GCP_REGION to a GCP region in which resources for this tutorial should be created"
  exit 1
fi


CURRENT_DIR=$(pwd)
CERTS_DIR=/tmp/kthw-certs

source "${CURRENT_DIR}/all_the_certs/ca.sh"
source "${CURRENT_DIR}/all_the_certs/admin.sh"
source "${CURRENT_DIR}/all_the_certs/kubelet.sh"
source "${CURRENT_DIR}/all_the_certs/kube-controller-manager.sh"
source "${CURRENT_DIR}/all_the_certs/kube-proxy.sh"
source "${CURRENT_DIR}/all_the_certs/kube-scheduler.sh"
source "${CURRENT_DIR}/all_the_certs/kubernetes-api.sh"
source "${CURRENT_DIR}/all_the_certs/service-account.sh"

mkdir -p $CERTS_DIR

cd $CERTS_DIR

# Create certs for certificate authority
create_ca

# Create k8s admin user client certs
create_admin_certs

# Create kubelet client certs
create_kubelet_certs

# Create kube controller manager client certs
create_kube_controller_manager_certs

# Create kube proxy client certs
create_kube_proxy_certs

# Create kube scheduler client certs
create_kube_sheduler_certs

# Create Kubernetes API server certs
create_kubernetes_api_certs

# Create certs for Kubernetes Controller Manager to
# sign service account token
create_service_account_certs

# Distribute the appropriate certs to worker instances
for instance in worker-0 worker-1 worker-2; do
  gcloud compute scp ca.pem ${instance}-key.pem ${instance}.pem ${instance}:~/ \
  --zone "${KTH_GCP_REGION}-b"
done

# Distribute the appropriate certs to controllers
for instance in controller-0 controller-1 controller-2; do
  gcloud compute scp ca.pem ca-key.pem kubernetes-key.pem kubernetes.pem \
    service-account-key.pem service-account.pem ${instance}:~/ \
    --zone "${KTH_GCP_REGION}-b"
done













