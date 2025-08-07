locals {
  # 1. Parse and clean (strip \r, trim whitespace, skip empty)
  service_usernames = [
    for email in split("\n", trim(file("${path.module}/service_users.txt"), "\n")) :
      trim(replace(email, "\r", ""), " ")
    if trim(replace(email, "\r", ""), " ") != ""
  ]
}

# 2. Lookup users in IDCS
data "oci_identity_domains_users" "impersonated_users" {
  for_each      = toset(local.service_usernames)
  idcs_endpoint = var.idcs_endpoint
  user_filter   = "userName eq \"${each.key}\""
}

# 3. Determine which users are missing
locals {
  missing_users = [
    for email in local.service_usernames : email
    if length(try(data.oci_identity_domains_users.impersonated_users[email].users, [])) == 0
  ]
}

# 4. Create missing service users
resource "oci_identity_domains_user" "service_users" {
  for_each      = toset(local.missing_users)
  idcs_endpoint = var.idcs_endpoint
  schemas       = ["urn:ietf:params:scim:schemas:core:2.0:User"]
  user_name     = each.key

  urnietfparamsscimschemasoracleidcsextensionuser_user {
    service_user = true
  }
}

# 5. Compose the final user ID map: lookup found users, or use created
locals {
  impersonated_user_ids = {
    for email in local.service_usernames :
      email => (
        length(try(data.oci_identity_domains_users.impersonated_users[email].users, [])) > 0
        ? data.oci_identity_domains_users.impersonated_users[email].users[0].id
        : oci_identity_domains_user.service_users[email].id
      )
  }
}

# 6. Main trust resource
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
	  for_each = local.service_usernames
	  content {
		rule  = "${var.jwt_claim_name} ${var.jwt_claim_operator} ${impersonation_service_users.value}"
		value = local.impersonated_user_ids[impersonation_service_users.value]
	  }
	}
}

output "trust_id" {
  value = oci_identity_domains_identity_propagation_trust.token_exchange_trust.id
}
