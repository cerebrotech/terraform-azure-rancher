output "ids" {
  description = "List of VM instance ids"
  value       = ["${azurerm_virtual_machine.this.*.id}"]
}

output "lb_id" {
  description = "Load balancer id"
  value       = "${azurerm_lb.this.id}"
}

output "lb_public_ip_address" {
  description = "Public IP of the load balancer"
  value       = "${var.enable_public_lb ? azurerm_public_ip.lb.0.ip_address : ""}"
}

output "lb_private_ip_address" {
  description = "Private IP of the load balancer"
  value       = "${azurerm_lb.this.private_ip_address}"
}

output "application_security_group_id" {
  description = "ID of the ASG attached to all instance NICs"
  value       = "${azurerm_application_security_group.this.id}"
}
