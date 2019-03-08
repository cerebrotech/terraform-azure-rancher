output "ids" {
  description = "List of VM instance ids"
  value       = ["${azurerm_virtual_machine.this.*.id}"]
}

output "public_ips" {
  description = "List of public IPs for all instances"
  value       = ["${azurerm_public_ip.this.*.ip_address}"]
}

output "private_ips" {
  description = "List of private IPs for all instances"
  value       = ["${azurerm_network_interface.this.*.private_ip_address}"]
}
