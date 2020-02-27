resource "local_file" "gcp_provider" {
    content = templatefile("${path.module}/gcp_provider.tf.tpl", { 
        gcp_credential_path = var.gcp_credentials,
        gcp_project_id = var.gcp_project_id
        gcp_region = var.gcp_region
    })
    filename = "${var.terraform_gcp_module}/gcp_provider.tf"
}