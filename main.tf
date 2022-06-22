#--------------------------------------------------------------------------------------
# AWS Managed Prometheus Workspace
#--------------------------------------------------------------------------------------
locals {
  amp_id = aws_prometheus_workspace.amp_demo.id

  vars = {

    SNS_ARN    = module.pagerduty_sns["sns_topic_arn"]
    AWS_REGION = var.region
    CLIENT_URL = "http://ops.alert.com" ## link to be included in the alert in PD

  }

}
resource "aws_prometheus_workspace" "amp_demo" {

  alias = "amp-demo-workspace"


}

resource "aws_prometheus_alert_manager_definition" "alert_manager_definition" {
  workspace_id = aws_prometheus_workspace.amp_demo.id
  definition   = templatefile("${path.module}/prom-definition.yaml", local.vars)
  #templatefile("${path.module}/policies/ci-deployment.json.tmpl", {
  #  fn_arn = aws_s3_bucket.ci_deployment.arn
}

resource "aws_prometheus_rule_group_namespace" "alert_manager_rules" {
  name         = "rules"
  workspace_id = aws_prometheus_workspace.amp_demo.id
  data         = file("${path.module}/prom-rules.yaml")
}


#----------------------------------------------------------------
#  SNS Topic - PagerDuty
#----------------------------------------------------------------
module "pagerduty_sns" {
  source  = "cloudposse/sns-topic/aws"
  version = "0.20.1"

  name                                   = "pagerduty-sns"
  allowed_aws_services_for_sns_published = ["aps.amazonaws.com"]
  encryption_enabled                     = false

  subscribers = {
    lambda = {
      protocol               = "lambda"
      endpoint               = module.pagerduty_lambda.arn
      endpoint_auto_confirms = true
      raw_message_delivery   = false
    }
  }

}

#----------------------------------------------------------------
#  Lambda Function - PagerDuty
#----------------------------------------------------------------
resource "aws_ssm_parameter" "pd_ssm_parameter" {
  name        = "/PAGER_DUTY/KEY"
  description = "PagerDuty API Key"
  type        = "SecureString"
  value       = "find_me_in_aws_console"

  lifecycle {
    ignore_changes = [value]
  }

}

module "pagerduty_lambda" {
  source  = "cloudposse/lambda-function/aws"
  version = "0.3.6"

  function_name = "pagerduty"

  handler  = "pagerduty.lambda_handler"
  runtime  = "python3.8"
  filename = "./pagerduty/pagerduty.zip"

  custom_iam_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
  ]


  lambda_environment = {
    variables = {
      "PAGER_DUTY_KEY" = "/PAGER_DUTY/KEY"
    }
  }



}

resource "aws_lambda_permission" "invoke_with_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = module.pagerduty_lambda.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = module.pagerduty_sns["sns_topic_arn"]
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
        "aps:GetMetricMetadata",
        "aps:ListRules",
        "aps:ListAlerts"
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
