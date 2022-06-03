#--------------------------------------------------------------------------------------
# AWS Managed Prometheus Workspace
#--------------------------------------------------------------------------------------
locals {
  amp_id = aws_prometheus_workspace.amp_demo.id

}
resource "aws_prometheus_workspace" "amp_demo" {

  alias = "amp-demo-workspace"


}

#--------------------------------------------------------------------------------------
# Create namespace and serviceaccount with the TF Kubernetes provider
#--------------------------------------------------------------------------------------
resource "kubernetes_service_account" "kube_prometheus_stack_sa" {
  metadata {
    name      = var.kube_prom_stack_service_account
    namespace = var.kubernetes_namespace

    annotations = {
      "eks.amazonaws.com/role-arn" : module.kube_prometheus_stack.service_account_role_arn

    }

  }

  depends_on = [
    kubernetes_namespace.prometheus_namespace
  ]

}

resource "kubernetes_namespace" "prometheus_namespace" {


  metadata {
    name = var.kubernetes_namespace
  }


}

#--------------------------------------------------------------------------------------
# TF Helm Release
#--------------------------------------------------------------------------------------
module "kube_prometheus_stack" {
  source  = "cloudposse/helm-release/aws"
  version = "0.4.3"

  name                 = ""
  chart                = var.chart
  repository           = var.chart_repository
  description          = var.chart_description
  chart_version        = var.chart_version
  kubernetes_namespace = var.kubernetes_namespace
  create_namespace     = false
  wait                 = var.wait
  atomic               = var.atomic
  cleanup_on_fail      = var.cleanup_on_fail
  timeout              = var.timeout

  recreate_pods = true


  iam_role_enabled                            = true
  service_account_role_arn_annotation_enabled = true

  service_account_name      = var.kube_prom_stack_service_account
  service_account_namespace = var.kubernetes_namespace

  iam_policy_statements = {
    AllowAMpIngest = {
      effect = "Allow"
      actions = [
        "aps:RemoteWrite",
        "aps:QueryMetrics",
        "aps:GetSeries",
        "aps:GetLabels",
        "aps:GetMetricMetadata"
      ]
      resources = ["*"]
    }
  }


  eks_cluster_oidc_issuer_url = var.eks_cluster_oidc_issuer_url

  values = [
    file("${path.module}/values.yaml")
  ]

  set = [
    {
      name  = "grafana.serviceAccount.name"
      value = var.kube_prom_stack_service_account
      type  = "string"
    },
    {
      name  = "grafana.additionalDataSources[0].url"
      value = "https://aps-workspaces.${var.region}.amazonaws.com/workspaces/${local.amp_id}"
      type  = "string"

    },
    {

      name  = "grafana.additionalDataSources[0].jsonData.sigV4Region"
      value = var.region
      type  = "string"

    },
    {

      name  = "prometheus.prometheusSpec.remoteWrite[0].sigv4.region"
      value = var.region
      type  = "string"
    },
    {

      name  = "prometheus.prometheusSpec.remoteWrite[0].url"
      value = "https://aps-workspaces.${var.region}.amazonaws.com/workspaces/${local.amp_id}/api/v1/remote_write"
      type  = "string"

    },
    {
      name  = "prometheus.serviceAccount.name"
      value = var.kube_prom_stack_service_account
      type  = "string"

    }
  ]


}
