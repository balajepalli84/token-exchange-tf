locals {
  raw_service_users = jsondecode(file("${path.module}/service_users.json"))

  service_users = [
    for u in local.raw_service_users : {
      username    = trim(u.username, " ")
      claim_name  = trim(u.claim_name, " ")
      claim_value = trim(u.claim_value, " ")
      operator    = contains(["eq", "co"], trim(u.operator, " ")) ? trim(u.operator, " ") : "eq"
    }
    if length(trim(u.username, " ")) > 0
      && length(trim(u.claim_name, " ")) > 0
      && length(trim(u.claim_value, " ")) > 0
  ]

  service_usernames = [for u in local.service_users : u.username]
  enabled_service_usernames = var.create_service_users ? local.service_usernames : []
}


resource "oci_identity_domains_user" "service_users" {
  for_each = { for username in local.enabled_service_usernames : username => username }

  idcs_endpoint = var.identity_domain_endpoint
  schemas       = ["urn:ietf:params:scim:schemas:core:2.0:User"]
  user_name     = each.key

  urnietfparamsscimschemasoracleidcsextensionuser_user {
    service_user = true
  }
}
