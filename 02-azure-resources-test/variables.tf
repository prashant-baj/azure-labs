variable "prefix" {
  description = "Short lowercase prefix used in resource names (kept short - part of globally-unique names)."
  type        = string
  default     = "swat"

  validation {
    condition     = can(regex("^[a-z0-9]{2,8}$", var.prefix))
    error_message = "prefix must be 2-8 lowercase letters or digits."
  }
}

variable "location" {
  description = "Azure region. The lab policy allows only eastus, eastus2, canadacentral."
  type        = string
  default     = "eastus"

  validation {
    condition     = contains(["eastus", "eastus2", "canadacentral"], var.location)
    error_message = "location must be one of: eastus, eastus2, canadacentral (lab policy)."
  }
}
