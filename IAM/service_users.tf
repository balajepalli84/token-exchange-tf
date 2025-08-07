locals {
  service_usernames = split("\n", trim(file("${path.module}/service_users.txt"), "\n"))
}

resource "oci_identity_domains_user" "service_users" {
  for_each      = toset(local.service_usernames)

  idcs_endpoint = var.idcs_endpoint
  schemas       = ["urn:ietf:params:scim:schemas:core:2.0:User"]
  user_name     = each.key

  urnietfparamsscimschemasoracleidcsextensionuser_user {
    service_user = true
  }
}
