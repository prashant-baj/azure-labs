variable "prefix" {
  description = "Short name used in every resource name. The pipeline sets it from your group number."
  type        = string
  default     = "cdtest"
  validation {
    condition     = can(regex("^[a-z0-9]{2,10}$", var.prefix))
    error_message = "prefix must be 2-10 lowercase letters or digits."
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
  description = "A public test image. Change it in a merge request to watch the pipeline roll out a new revision."
  type        = string
  default     = "mcr.microsoft.com/k8se/quickstart:latest"
}

variable "commit" {
  description = "The commit that deployed this - set by the pipeline, shown as a tag."
  type        = string
  default     = "local"
}
