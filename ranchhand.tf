locals {
  ranchhand_cert_ips = concat([local.lb_ip], var.ranchhand_cert_ipaddresses)

  node_ips = formatlist(
          (var.enable_public_instances ? "%s:%s" : "%[2]s"),
          var.enable_public_instances ? azurerm_public_ip.vm.*.ip_address : azurerm_network_interface.vm.*.private_ip_address,
          azurerm_network_interface.vm.*.private_ip_address,
        )
}

module "ranchhand" {
  source = "github.com/dominodatalab/ranchhand.git//terraform?ref=v0.2.0-rc2"

  distro   = var.ranchhand_distro
  release  = var.release
  node_ips = local.node_ips

  cert_ipaddresses = local.ranchhand_cert_ips
  cert_dnsnames    = var.ranchhand_cert_dnsnames

  ssh_username   = var.admin_username
  ssh_key_path   = var.ssh_private_key
  ssh_proxy_user = var.ssh_proxy_user
  ssh_proxy_host = var.ssh_proxy_host

  admin_password = var.admin_password

  working_dir = var.ranchhand_working_dir
}
