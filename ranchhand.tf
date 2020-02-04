locals {
  ranchhand_cert_ips = concat([local.lb_ip], var.ranchhand_cert_ipaddresses)

}

data "null_data_source" "node_ips" {
  count = length(azurerm_virtual_machine.this.*.id)
  inputs = {
    id = element(azurerm_virtual_machine.this.*.id, count.index)
    ip = element(coalescelist(azurerm_public_ip.vm.*.ip_address, azurerm_network_interface.vm.*.private_ip_address), count.index)
  }
}

module "ranchhand" {
  source = "github.com/dominodatalab/ranchhand.git?ref=v0.3.5"

  node_ips = data.null_data_source.node_ips.*.outputs.ip

  cert_ipaddresses = local.ranchhand_cert_ips
  cert_dnsnames    = var.ranchhand_cert_dnsnames

  ssh_username   = var.admin_username
  ssh_key_path   = var.ssh_private_key
  ssh_proxy_user = var.ssh_proxy_user
  ssh_proxy_host = var.ssh_proxy_host

  admin_password = var.admin_password

  working_dir = var.ranchhand_working_dir
}
