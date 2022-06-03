output "metadata" {
  value       = module.kube_prometheus_stack.metadata
  description = "Block status of the deployed release"
}
