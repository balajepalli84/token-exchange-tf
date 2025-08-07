data "oci_identity_domains_users" "impersonated_users" {
  for_each      = toset(local.service_usernames)
  idcs_endpoint = var.idcs_endpoint
  user_filter   = "userName eq \"${each.key}\""
}

locals {
  missing_users = [
    for email in local.service_usernames : email
    if length(try(data.oci_identity_domains_users.impersonated_users[email].users, [])) == 0
  ]
  impersonated_user_ids = {
    for email in local.service_usernames :
      email => data.oci_identity_domains_users.impersonated_users[email].users[0].id
    if length(try(data.oci_identity_domains_users.impersonated_users[email].users, [])) > 0
  }
}

resource "terraform_data" "fail_if_missing" {
  count = length(local.missing_users) > 0 ? 1 : 0
  provisioner "local-exec" {
    command = ">&2 echo 'ERROR: The following users are missing in IDCS: ${join(", ", local.missing_users)}' && exit 1"
  }
}

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

  dynamic "impersonation_service_users" {
    for_each = local.impersonated_user_ids
    content {
      rule  = "${var.jwt_claim_name} ${var.jwt_claim_operator} ${impersonation_service_users.key}"
      value = impersonation_service_users.value
    }
  }
  depends_on = [
    oci_identity_domains_user.service_users
  ]
}

output "trust_id" {
  value = oci_identity_domains_identity_propagation_trust.token_exchange_trust.id
}
