output "ids" {
  description = "List of VM instance ids"
  value       = [azurerm_virtual_machine.this.*.id]
}

output "node_ips" {
  description = "Comma-delimited string of VM node ips"
  value       = join(",", data.null_data_source.node_ips.*.outputs.ip)
}

output "public_lb_id" {
  description = "Load balancer id"
  value       = var.enable_public_lb ? element(concat(azurerm_lb.public_lb.*.id, [""]), 0) : ""
}

output "public_lb_ip_address" {
  description = "Public IP of the load balancer"
  value       = var.enable_public_lb ? element(concat(azurerm_public_ip.public_lb.*.ip_address, [""]), 0) : ""
}

output "private_lb_ip_address" {
  description = "Private IP of the load balancer"
  value       = var.enable_private_lb ? element(concat(azurerm_lb.private_lb.*.private_ip_address, [""]), 0) : "" # TODO: Make this accurate
}

output "application_security_group_id" {
  description = "ID of the ASG attached to all instance NICs"
  value       = azurerm_application_security_group.vm.id
}

output "cluster_provisioned" {
  description = "ID of the null_resource cluster provisioner"
  value       = module.ranchhand.cluster_provisioned
}

output "admin_password" {
  description = "Generated password for Rancher default admin user"
  value       = module.ranchhand.admin_password
}
