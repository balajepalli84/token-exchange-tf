variable "create_service_users" {
  description = "Set true to create service users from service_users.txt; set false to skip user creation."
  type        = bool
  default     = false
}

variable "idcs_endpoint" {
  description = "The base endpoint for your Oracle Identity Cloud Service (IDCS) domain."
  type        = string
  default     = ""
}

variable "issuer" {
  description = "Issuer URI for the trust configuration (usually your IDCS or OIDC issuer URL)."
  type        = string
  default     = ""
}

variable "trust_name" {
  description = "Name for the identity propagation trust being created."
  type        = string
  default     = "token-exchange-trust"
}

variable "public_key_endpoint" {
  description = "The endpoint providing the public key (JWKS URI) for your trust setup."
  type        = string
  default     = ""
}

variable "jwt_claim_name" {
  description = "The JWT claim field to match in trust rules, e.g., 'email', 'sub'."
  type        = string
  default     = "sub"
}

variable "jwt_claim_operator" {
  description = "Operator for claim match in trust rules. Only 'eq' or 'co' are supported."
  type        = string
  default     = "eq"
  validation {
    condition     = contains(["eq", "co"], var.jwt_claim_operator)
    error_message = "Only 'eq' or 'co' are valid operators."
  }
}
