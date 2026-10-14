variable "prefix" {
  description = "Your group, 2-8 lowercase letters or digits (e.g. group1). Part of every name."
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9]{2,8}$", var.prefix))
    error_message = "prefix must be 2-8 lowercase letters or digits."
  }
}

variable "app_name" {
  description = "The component you deploy first, e.g. api. Lowercase letters, digits and hyphens."
  type        = string
  default     = "api"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,14}$", var.app_name))
    error_message = "app_name must start with a letter: 2-15 lowercase letters, digits or hyphens."
  }
}

variable "location" {
  description = "Lab policy allows only eastus, eastus2 and canadacentral."
  type        = string
  default     = "eastus"
  validation {
    condition     = contains(["eastus", "eastus2", "canadacentral"], var.location)
    error_message = "location must be eastus, eastus2 or canadacentral (lab policy)."
  }
}

variable "image" {
  description = "The image to run. The default is a public hello page, so the first apply works before your image exists."
  type        = string
  default     = "mcr.microsoft.com/k8se/quickstart:latest"
}

variable "target_port" {
  description = "The port your app listens on. 80 for the hello image; your own port once you deploy your image."
  type        = number
  default     = 80
}

variable "settings" {
  description = "Plain (non-secret) settings passed to the app as environment variables. Never put a secret here."
  type        = map(string)
  default     = {}
}
