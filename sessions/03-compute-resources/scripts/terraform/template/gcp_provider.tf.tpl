provider "google" {
  credentials = file("${gcp_credential_path}")
  project     = "${gcp_project_id}"
  region      = "${gcp_region}"
}