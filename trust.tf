locals {
  impersonation_emails = [
    for email in split("\n", trim(file("${path.module}/service_users.txt"), "\n")) :
      trim(replace(email, "\r", ""), " ")
    if trim(replace(email, "\r", ""), " ") != ""
  ]
}


# Lookup each service user in IDCS by email
data "oci_identity_domains_users" "impersonated_users" {
  for_each      = toset(local.impersonation_emails)
  idcs_endpoint = var.idcs_endpoint
  user_filter   = "userName eq \"${each.key}\""
}

# List emails that could not be matched in IDCS (for error handling)
locals {
  missing_users = [
    for email in local.impersonation_emails : email
    if length(try(data.oci_identity_domains_users.impersonated_users[email].users, [])) == 0
  ]
}

# Fail early if any user is missing in IDCS
resource "null_resource" "fail_if_missing" {
  count = length(local.missing_users) > 0 ? 1 : 0

  provisioner "local-exec" {
    command = "echo 'ERROR: Missing users: ${join(", ", local.missing_users)}' && exit 1"
  }
}

# Main trust resource using the correct client ID reference
resource "oci_identity_domains_identity_propagation_trust" "token_exchange_trust" {
  idcs_endpoint        = var.idcs_endpoint
  issuer               = var.issuer
  name                 = "token-exchange-propagation"
  schemas              = ["urn:ietf:params:scim:schemas:oracle:idcs:IdentityPropagationTrust"]
  type                 = "JWT"
  active               = true
  allow_impersonation  = true
  oauth_clients        = [oci_identity_domains_app.conf_app.name]
  public_key_endpoint  = var.public_key_endpoint
  subject_type         = "User"
  description          = "Created by Terraform"

  # Create impersonation rules for each valid service user
  dynamic "impersonation_service_users" {
    for_each = local.impersonation_emails
    content {
      rule  = "sub eq ${impersonation_service_users.value}"
      value = data.oci_identity_domains_users.impersonated_users[impersonation_service_users.value].users[0].id
    }
  }

  # Ensure trust is not created if users are missing
  depends_on = [null_resource.fail_if_missing]
}

# Output trust OCID
output "trust_id" {
  value = oci_identity_domains_identity_propagation_trust.token_exchange_trust.id
}
