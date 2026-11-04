# Paste these two blocks into azurerm_container_app "app" in main.tf - see WORKSHOP-S16.md, step 4.

# 1 - next to the existing `secret { name = "acr-password" ... }` block:
dynamic "secret" {
  for_each = local.app_secret_names
  content {
    name  = lower(replace(secret.key, "_", "-"))
    value = local.app_secrets[secret.key]
  }
}

# 2 - inside template { container { ... } }, next to the existing `dynamic "env"` block:
dynamic "env" {
  for_each = local.app_secret_names
  content {
    name        = env.key
    secret_name = lower(replace(env.key, "_", "-"))
  }
}
env {
  name  = "APP_ENV" # "production" switches the drill off - the test environment keeps it
  value = "test"
}
