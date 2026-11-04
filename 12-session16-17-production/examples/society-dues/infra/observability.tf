# Session 17 - the observability stack for this component, next to the app it watches.
# Application Insights keeps its data in the Log Analytics workspace the Container Apps environment already
# uses: one place to query logs, requests, traces and metrics. Each resource names the spec line it serves.
#
# Needs from main.tf: azurerm_resource_group.rg, azurerm_log_analytics_workspace.logs (the Session 12 starter).
# Then add the connection string to local.app_secrets in secrets.tf (WORKSHOP-S17.md, step 2).

variable "alert_email" {
  description = "Who the alerts email - from the GitLab variable ALERT_EMAIL. Empty = alerts fire with no email."
  type        = string
  default     = ""
}

variable "nfr_p95_ms" {
  description = "OBS-002 / NFR-0nn: the 95th-percentile response time the NFR allows, in milliseconds."
  type        = number
  default     = 2000
}

variable "error_pct_alert" {
  description = "OBS-003: alert when more than this percentage of requests fail in five minutes."
  type        = number
  default     = 5
}

variable "business_metric" {
  description = "OBS-001: the name of your business metric, exactly as the code creates it (a counter)."
  type        = string
  default     = "dues_payments_recorded"
}

# Where every signal lands (OBS-001..004). Workspace-based: the data lives in azurerm_log_analytics_workspace.logs.
resource "azurerm_application_insights" "appi" {
  name                = "${local.name}-appi"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  workspace_id        = azurerm_log_analytics_workspace.logs.id
  application_type    = "web"
  retention_in_days   = 30
  tags                = local.tags
}

locals {
  workspace = azurerm_log_analytics_workspace.logs.id
  kql = {
    business = <<-KQL
      AppMetrics
      | where Name == "${var.business_metric}"
      | extend outcome = tostring(Properties.outcome)
      | summarize total = sum(Sum) by bin(TimeGenerated, 5m), outcome
    KQL
    p95      = <<-KQL
      AppRequests
      | summarize p95_ms = percentile(DurationMs, 95) by bin(TimeGenerated, 5m), Name
      | extend nfr_ms = ${var.nfr_p95_ms}
    KQL
    errors   = <<-KQL
      AppRequests
      | summarize failed = countif(Success == false), total = count() by bin(TimeGenerated, 5m)
      | extend error_pct = round(100.0 * failed / total, 1)
      | project TimeGenerated, error_pct
    KQL
    versions = <<-KQL
      AppRequests
      | summarize requests = count(), p95_ms = percentile(DurationMs, 95) by AppVersion
      | order by requests desc
    KQL
  }
  tile = { for k, q in local.kql : k => {
    type = 3
    name = k
    content = {
      version                 = "KqlItem/1.0"
      query                   = q
      size                    = 0
      timeContext             = { durationMs = 3600000 }
      queryType               = 0
      resourceType            = "microsoft.operationalinsights/workspaces"
      crossComponentResources = [local.workspace]
      visualization           = k == "versions" ? "table" : "timechart"
    }
  } }
}

# The dashboard (OBS-001, OBS-002, OBS-003): one business tile, two technical tiles, and which version served them.
resource "random_uuid" "workbook" {}

resource "azurerm_application_insights_workbook" "dashboard" {
  name                = random_uuid.workbook.result
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  display_name        = "${local.name} - business and technical health"
  source_id           = lower(local.workspace)
  tags                = local.tags
  data_json = jsonencode({
    version = "Notebook/1.0"
    items = [
      { type = 1, name = "title", content = { json = "## ${local.name}\nBusiness metric (OBS-001), response time against the NFR (OBS-002), failed requests (OBS-003), and which version served them." } },
      local.tile.business,
      local.tile.p95,
      local.tile.errors,
      local.tile.versions,
    ]
    fallbackResourceIds = [local.workspace]
    "$schema"           = "https://github.com/Microsoft/Application-Insights-Workbooks/blob/master/schema/workbook.json"
  })
}

# Who hears about it.
resource "azurerm_monitor_action_group" "team" {
  name                = "${local.name}-team"
  resource_group_name = azurerm_resource_group.rg.name
  short_name          = substr(replace(local.name, "-", ""), 0, 12)
  tags                = local.tags

  dynamic "email_receiver" {
    for_each = var.alert_email == "" ? [] : [var.alert_email]
    content {
      name          = "team"
      email_address = email_receiver.value
    }
  }
}

# OBS-002: slower than the NFR allows - the technical alert the drill fires.
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "slow" {
  name                 = "${local.name}-p95-over-nfr"
  resource_group_name  = azurerm_resource_group.rg.name
  location             = azurerm_resource_group.rg.location
  description          = "OBS-002: 95th-percentile response time above ${var.nfr_p95_ms} ms (NFR) for five minutes"
  scopes               = [local.workspace]
  severity             = 2
  evaluation_frequency = "PT5M"
  window_duration      = "PT5M"
  tags                 = local.tags

  criteria {
    query                   = "AppRequests | summarize p95_ms = percentile(DurationMs, 95)"
    time_aggregation_method = "Maximum"
    metric_measure_column   = "p95_ms"
    operator                = "GreaterThan"
    threshold               = var.nfr_p95_ms
    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.team.id]
  }
}

# OBS-003: too many failed requests - the alert the error drill fires.
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "errors" {
  name                 = "${local.name}-errors"
  resource_group_name  = azurerm_resource_group.rg.name
  location             = azurerm_resource_group.rg.location
  description          = "OBS-003: more than ${var.error_pct_alert}% of requests failed in five minutes"
  scopes               = [local.workspace]
  severity             = 1
  evaluation_frequency = "PT5M"
  window_duration      = "PT5M"
  tags                 = local.tags

  criteria {
    query                   = "AppRequests | summarize error_pct = 100.0 * countif(Success == false) / count()"
    time_aggregation_method = "Maximum"
    metric_measure_column   = "error_pct"
    operator                = "GreaterThan"
    threshold               = var.error_pct_alert
    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.team.id]
  }
}

output "logs_workspace_id" {
  description = "The workspace's customer ID - verify:observability queries it."
  value       = azurerm_log_analytics_workspace.logs.workspace_id
}

output "dashboard_name" {
  description = "Azure portal: Monitor > Workbooks, or the resource group > this workbook."
  value       = azurerm_application_insights_workbook.dashboard.display_name
}
