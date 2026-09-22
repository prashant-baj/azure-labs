variable "prefix" {
  description = "Short name prefix for all resources. Lowercase letters/digits only (kept short - it's part of the globally-unique storage account name)."
  type        = string
  default     = "swat"

  validation {
    condition     = can(regex("^[a-z0-9]{2,11}$", var.prefix))
    error_message = "prefix must be 2-11 lowercase letters or digits."
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
