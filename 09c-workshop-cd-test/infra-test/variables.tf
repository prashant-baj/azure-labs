variable "prefix" {
  description = "Short name used in every resource name. The pipeline sets wk<group number>, e.g. wk3."
  type        = string
  default     = "wktest"
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

variable "message" {
  description = "One line shown on the test page. Change it in a merge request and watch main roll it out."
  type        = string
  default     = "Deployed by our pipeline - no one typed az or terraform."
}

# Set by the pipeline - they make the page prove WHICH commit and pipeline deployed it.
variable "project" {
  type    = string
  default = "local"
}
variable "commit" {
  type    = string
  default = "local"
}
variable "pipeline_url" {
  type    = string
  default = ""
}
