terraform {
  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = "~> 2.0"
    }
  }
}

provider "grafana" {
  url  = "http://localhost:3000"
  auth = "admin:admin"
}

resource "grafana_data_source" "prometheus" {
  type = "prometheus"
  name = "DS_PROMETHEUS"
  url  = "http://host.docker.internal:9090"
}

resource "grafana_data_source" "loki" {
  type = "loki"
  name = "Loki"
  url  = "http://host.docker.internal:3100"
}

resource "grafana_dashboard" "jvm_dashboard" {
  config_json = replace(
    file("dashboard_10519.json"),
    "$${DS_PROMETHEUS}",
    grafana_data_source.prometheus.name
  )
}
