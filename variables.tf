variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "region" {}
variable "idcs_endpoint" {}
variable "issuer" {}
variable "trust_name" {}
variable "public_key_endpoint" {}
variable "display_name" {
  type = string
}
variable "jwt_claim_name" {
  description = "JWT claim field to match, e.g. 'sub', 'email', etc."
  type        = string
}

variable "jwt_claim_operator" {
  description = "Operator for the claim match. Only 'eq' or 'co' are supported."
  type        = string
  validation {
    condition     = contains(["eq", "co"], var.jwt_claim_operator)
    error_message = "Only 'eq' or 'co' are valid operators."
  }
}


