resource "oci_identity_domains_app" "conf_app" {
  idcs_endpoint = var.identity_domain_endpoint
  display_name = "${var.trust_name}conf_app"
  active        = true
  schemas = ["urn:ietf:params:scim:schemas:oracle:idcs:App"]
  is_oauth_client = true
  client_type     = "confidential"
  allowed_grants = ["client_credentials"]
  based_on_template {
    value = "CustomWebAppTemplateId"
  }
}
output "client_id" {
  value = oci_identity_domains_app.conf_app.name
}

