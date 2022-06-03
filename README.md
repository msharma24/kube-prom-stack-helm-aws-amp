# kube-prom-stack-helm-aws-amp

## Description
This project deploys the AWS Managed Prometheus (AMP) workspace and configures the Prometheus Community - [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack) Helm Chart using Terraform.

0. The helm release terraform module used in this project automatically creates an IAM Role for [IRSA](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html) and annotated to the namespace service account attached to the prometheus and grafana pods.
1. Prometheus [remote_write](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#remote_write)  is automatically configured to the ingest metrics to the AMP Endpoint. 
1. Grafana Datasource is automatically configured to read metrics from AMP with Sigv4 authentication via IRSA.



# Prerequisites

1. EKS Cluster with with IAM OIDC Enabled [Reference link](https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html)
2. Access to EKS Cluster via `kubectl` command line .
3. IAM User Credentials in your environment.

## Deploy
1. Update the `default.auto.tfvars` file with your EKS Cluster OIDC Issues URL (_without https://_) and AWS region of your EKS Cluster.
2. `terraform init`
3. `terraform plan`
4. `terraform apply [-auto-approve]`
5. This action will deploy the following resources:

						-> AWS Managed Prometheus Workspace 

						-> IAM Role 
  
						-> Creates a new namespace called Prometheus and deploys the Pods 
						
						- > Creates a service account with IAM Role annotation.

6. AWS AMP Workspace on AWS Console
![](https://raw.githubusercontent.com/msharma24/kube-prom-stack-helm-aws-amp/main/img/amp.png)
5. Once the Terraform complete the deployment - check the pods created in the new `prometheus` namespace `kubectl get pods -n prometheus`
![](https://raw.githubusercontent.com/msharma24/kube-prom-stack-helm-aws-amp/main/img/get-pods.png)
6. Once all the pods are running - access the Grafana instance by running port-forward command `kubectl -n prometheus port-forward _kube-prometheus-stack-grafana-<random_id>_ 3000`
![](https://raw.githubusercontent.com/msharma24/kube-prom-stack-helm-aws-amp/main/img/k-port-forward.png)
7. Access the Grafana Instance Locally `http://localhost:3000/ User: `admin` Password `prom-operator`
8. Go to Data Sources  and click on `prometheus-amp` data source to validate if the AMP Data Source is working 
![](https://raw.githubusercontent.com/msharma24/kube-prom-stack-helm-aws-amp/main/img/datasource.png)
And then scroll down and click `Save and Test` and it should respond with `Data Source is working `
![](https://raw.githubusercontent.com/msharma24/kube-prom-stack-helm-aws-amp/main/img/datasource-test.png)

9 Browse the built in Grafana Dashboard to monitor EKS Metrics
![](https://raw.githubusercontent.com/msharma24/kube-prom-stack-helm-aws-amp/main/img/grafana-dashboards.png)

10 Example Dashboard
![](https://raw.githubusercontent.com/msharma24/kube-prom-stack-helm-aws-amp/main/img/example-dashboard.png)

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.16.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.11.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_kube_prometheus_stack"></a> [kube\_prometheus\_stack](#module\_kube\_prometheus\_stack) | cloudposse/helm-release/aws | 0.4.3 |

## Resources

| Name | Type |
|------|------|
| [aws_prometheus_workspace.amp_demo](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/prometheus_workspace) | resource |
| [kubernetes_namespace.prometheus_namespace](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_service_account.kube_prometheus_stack_sa](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_atomic"></a> [atomic](#input\_atomic) | If set, installation process purges chart on fail. The wait flag will be set automatically if atomic is used. | `bool` | `true` | no |
| <a name="input_chart"></a> [chart](#input\_chart) | Chart name to be installed. The chart name can be local path, a URL to a chart, or the name of the chart if `repository` is specified. It is also possible to use the `<repository>/<chart>` format here if you are running Terraform on a system that the repository has been added to with `helm repo add` but this is not recommended. | `string` | n/a | yes |
| <a name="input_chart_description"></a> [chart\_description](#input\_chart\_description) | Set release description attribute (visible in the history). | `string` | `null` | no |
| <a name="input_chart_repository"></a> [chart\_repository](#input\_chart\_repository) | Repository URL where to locate the requested chart. | `string` | n/a | yes |
| <a name="input_chart_values"></a> [chart\_values](#input\_chart\_values) | Additional values to yamlencode as `helm_release` values. | `any` | `{}` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Specify the exact chart version to install. If this is not specified, the latest version is installed. | `string` | `null` | no |
| <a name="input_cleanup_on_fail"></a> [cleanup\_on\_fail](#input\_cleanup\_on\_fail) | Allow deletion of new resources created in this upgrade when upgrade fails. | `bool` | `true` | no |
| <a name="input_create_namespace"></a> [create\_namespace](#input\_create\_namespace) | Create the namespace if it does not yet exist. Defaults to `false`. | `bool` | `null` | no |
| <a name="input_eks_cluster_oidc_issuer_url"></a> [eks\_cluster\_oidc\_issuer\_url](#input\_eks\_cluster\_oidc\_issuer\_url) | n/a | `any` | n/a | yes |
| <a name="input_kube_prom_stack_service_account"></a> [kube\_prom\_stack\_service\_account](#input\_kube\_prom\_stack\_service\_account) | Service Account Assigned to the prometheus namespace for IRSA | `string` | n/a | yes |
| <a name="input_kubernetes_namespace"></a> [kubernetes\_namespace](#input\_kubernetes\_namespace) | The namespace to install the release into. | `string` | n/a | yes |
| <a name="input_rbac_enabled"></a> [rbac\_enabled](#input\_rbac\_enabled) | Service Account for pods. | `bool` | `true` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS Region. | `string` | n/a | yes |
| <a name="input_timeout"></a> [timeout](#input\_timeout) | Time in seconds to wait for any individual kubernetes operation (like Jobs for hooks). Defaults to `300` seconds | `number` | `null` | no |
| <a name="input_wait"></a> [wait](#input\_wait) | Will wait until all resources are in a ready state before marking the release as successful. It will wait for as long as `timeout`. Defaults to `true`. | `bool` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_metadata"></a> [metadata](#output\_metadata) | Block status of the deployed release |
