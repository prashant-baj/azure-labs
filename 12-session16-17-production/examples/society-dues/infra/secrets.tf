# Session 16 - every secret the app reads, and where its value comes from. Never a value in this file.
#
# A secret's journey:  masked GitLab variable  ->  TF_VAR_<name> (ci/production.yml)  ->  this variable
#                      ->  a Container App secret  ->  an environment variable inside the container.
# Your laptop never sees the deployed value; git never sees any value; the job log shows [MASKED].

variable "treasurer_key" { # T-01 / SEC-001 - the key that proves a caller may see who paid what
  description = "From the masked GitLab variable TREASURER_KEY. Empty = the secret is not created."
  type        = string
  sensitive   = true
  default     = ""
}

locals {
  # Environment variable name => value. Add one line per secret; Session 17 adds the telemetry connection.
  app_secrets = {
    TREASURER_KEY                         = var.treasurer_key
    APPLICATIONINSIGHTS_CONNECTION_STRING = azurerm_application_insights.appi.connection_string # Session 17
  }
  # Only secrets that have a value - a Container App secret cannot be empty.
  app_secret_names = nonsensitive(toset([for name, value in local.app_secrets : name if value != ""]))
}
