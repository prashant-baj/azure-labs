# Session 16 - every secret the app reads, and where its value comes from. Never a value in this file.
#
# A secret's journey:  masked GitLab variable  ->  TF_VAR_<name> (ci/production.yml)  ->  this variable
#                      ->  a Container App secret  ->  an environment variable inside the container.
# Your laptop never sees the deployed value; git never sees any value; the job log shows [MASKED].

variable "app_api_key" { # T-01 / SEC-001 - the key that proves a caller may use the protected routes
  description = "From the masked GitLab variable APP_API_KEY. Empty = the secret is not created."
  type        = string
  sensitive   = true
  default     = ""
}

locals {
  # Environment variable name => value. Add one line per secret; Session 17 adds the telemetry connection.
  app_secrets = {
    APP_API_KEY = var.app_api_key # rename to what your code reads - and the variable above to match
  }
  # Only secrets that have a value - a Container App secret cannot be empty.
  app_secret_names = nonsensitive(toset([for name, value in local.app_secrets : name if value != ""]))
}
