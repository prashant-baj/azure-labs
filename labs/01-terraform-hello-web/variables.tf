variable "prefix" {
  description = "Short name prefix for all resources. Use lowercase letters/digits only."
  type        = string
  default     = "swat"

  validation {
    condition     = can(regex("^[a-z0-9]{2,12}$", var.prefix))
    error_message = "prefix must be 2-12 lowercase letters or digits."
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

variable "plan_sku" {
  description = "App Service Plan SKU. B1 is the smallest tier that supports Linux containers."
  type        = string
  default     = "B1"
}
