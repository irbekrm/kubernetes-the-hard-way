#!/bin/bash

set -eux

command -v terraform >/dev/null 2>&1 || { echo >&2 "Please install terraform CLI"; exit 1; }

if [ -z "$KTH_GOOGLE_APPLICATION_CREDENTIALS" ]; then
  echo "Please set KTH_GCP_CREDS to the path to your GCP service account creds (GOOGLE_APPLICATION_CREDENTIALS)"
  exit 1
fi

if [ -z "$KTH_GCP_PROJECT_ID" ]; then
  echo "Please set KTH_PROJECT_ID to a GCP project ID where the resources for this tutorial should be created"
  exit 1
fi

if [ -z "$KTH_GCP_REGION" ]; then
  echo "Please set KTH_GCP_REGION to a GCP region in which resources for this tutorial should be created"
  exit 1
fi

CURRENT_PATH=$(pwd)
TERRAFORM_GCP_MODULE="${CURRENT_PATH}/terraform/gcp"

pushd "${CURRENT_PATH}/terraform/template"
  terraform init
  terraform apply \
    -var gcp_credentials="${KTH_GOOGLE_APPLICATION_CREDENTIALS}" \
    -var gcp_project_id="${KTH_GCP_PROJECT_ID}" \
    -var gcp_region="${KTH_GCP_REGION}" \
    -var terraform_gcp_module="${TERRAFORM_GCP_MODULE}" \
    --auto-approve
popd

pushd "${CURRENT_PATH}/terraform/gcp"
  terraform init
    terraform apply \
      -var gcp_zone="${KTH_GCP_REGION}-b" \
      --auto-approve
popd