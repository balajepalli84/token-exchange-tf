locals {
  # Parse emails, strip \r and whitespace, skip blanks
  service_usernames = [
    for email in split("\n", trim(file("${path.module}/service_users.txt"), "\n")) :
      trim(replace(email, "\r", ""), " ")
    if trim(replace(email, "\r", ""), " ") != ""
  ]
}

resource "oci_identity_domains_user" "service_users" {
  for_each = {
    for username in local.service_usernames : 
    username => username 
  }

  idcs_endpoint = var.idcs_endpoint
  schemas       = ["urn:ietf:params:scim:schemas:core:2.0:User"]
  user_name     = each.key

  urnietfparamsscimschemasoracleidcsextensionuser_user {
    service_user = true
  }

}
