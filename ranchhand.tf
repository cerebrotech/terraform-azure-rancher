locals {
  ranchhand_cert_ips = ["${concat(list(local.lb_ip), var.ranchhand_cert_ipaddresses)}"]
  public_ips         = "${split(",", var.enable_public_instances ? join(",",azurerm_public_ip.vm.*.ip_address) : join(",",azurerm_network_interface.vm.*.private_ip_address))}"

  node_ips = "${var.enable_public_instances ?
    join(",", formatlist("%v:%v", local.public_ips, azurerm_network_interface.vm.*.private_ip_address)) :
    join(",", azurerm_network_interface.vm.*.private_ip_address)}"
}

resource "random_string" "password" {
  length = 20
}

module "ranchhand" {
  source = "git@github.com:cerebrotech/terraform-aws-rancher.git//modules/ranchhand?ref=steved/password-override"

  distro   = "${var.ranchhand_distro}"
  release  = "${var.release}"
  node_ips = "${split(",", local.node_ips)}"

  cert_ipaddresses = "${local.ranchhand_cert_ips}"
  cert_dnsnames    = "${var.ranchhand_cert_dnsnames}"

  ssh_username   = "${var.admin_username}"
  ssh_key_path   = "${var.ssh_private_key}"
  ssh_proxy_user = "${var.ssh_proxy_user}"
  ssh_proxy_host = "${var.ssh_proxy_host}"

  admin_password = "${var.admin_password}"
}
