locals {
  node_ips = "${var.enable_public_endpoint ?
    join(",", formatlist("%v:%v", azurerm_public_ip.this.*.ip_address, azurerm_network_interface.this.*.private_ip_address)) :
    join(",", azurerm_network_interface.this.*.private_ip_address)}"
}

data "template_file" "ranchhand_launcher" {
  template = "${file("${path.module}/templates/ranchhand_launcher.sh.tpl")}"

  vars {
    distro         = "${var.ranchhand_distro}"
    version        = "${var.ranchhand_release}"
    ssh_user       = "${var.admin_username}"
    ssh_key_path   = "${var.ssh_private_key}"
    node_ips       = "${local.node_ips}"
    ssh_proxy_host = "${var.ssh_proxy_host}"
    ssh_proxy_user = "${var.ssh_proxy_user}"
  }
}

resource "null_resource" "provision_cluster" {
  triggers {
    instance_ids = "${join(",", azurerm_virtual_machine.this.*.id)}"
  }

  provisioner "local-exec" {
    command     = "${data.template_file.ranchhand_launcher.rendered}"
    working_dir = "${var.ranchhand_working_dir}"
  }
}
