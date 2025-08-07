variable "create_service_users" {
  description = "Set true to create service users from service_users.txt; set false to skip user creation."
  type        = bool
  default     = false
}

variable "identity_domain_endpoint" {
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