name   = "kube-prometheus-stack"
region = "<CHANGE_ME>"

chart            = "kube-prometheus-stack"
chart_repository = "https://prometheus-community.github.io/helm-charts"
chart_version    = "35.0.0"

kubernetes_namespace = "prometheus"
create_namespace     = false

kube_prom_stack_service_account = "iamproxy-service-account"
eks_cluster_oidc_issuer_url     = "<CHANGE_ME>"
