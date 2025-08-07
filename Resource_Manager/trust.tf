# 1. Data source removed - not needed due to forward reference issue

# 2. Locals for missing/invalid users and operator validation
locals {
  missing_users = [
    for u in local.service_users : u.username
    if !contains(keys(oci_identity_domains_user.service_users), u.username)
  ]

  impersonated_user_ids = {
    for username, user in oci_identity_domains_user.service_users :
      username => user.id
  }

  invalid_operators = [
    for u in local.service_users : u.operator
    if !contains(["eq", "co"], u.operator)
  ]
}

# 3. Fail (if missing users and not creating)
resource "terraform_data" "fail_if_missing" {
  count = (!var.create_service_users && length(local.missing_users) > 0) ? 1 : 0

  provisioner "local-exec" {
    command = <<EOT
echo "ERROR: The following users are missing in IDCS: ${join(", ", local.missing_users)}"
exit 1
EOT
  }
}

# 4. Fail (if bad operators when creating)
resource "terraform_data" "fail_on_bad_operator" {
  count = var.create_service_users && length(local.invalid_operators) > 0 ? 1 : 0

  provisioner "local-exec" {
    command = <<EOT
echo "ERROR: Invalid operator(s) in service_users.json: ${join(", ", local.invalid_operators)}"
exit 1
EOT
  }
}

# 5. The trust/resource itself
resource "oci_identity_domains_identity_propagation_trust" "token_exchange_trust" {
  idcs_endpoint        = var.identity_domain_endpoint
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
    for_each = {
      for u in local.service_users :
        u.username => u
      if contains(keys(local.impersonated_user_ids), u.username)
    }

    content {
      rule  = "${impersonation_service_users.value.claim_name} ${impersonation_service_users.value.operator} ${impersonation_service_users.value.claim_value}"
      value = local.impersonated_user_ids[impersonation_service_users.value.username]
    }
  }

  depends_on = [
    oci_identity_domains_user.service_users
  ]
}

output "trust_id" {
  value = oci_identity_domains_identity_propagation_trust.token_exchange_trust.id
}
