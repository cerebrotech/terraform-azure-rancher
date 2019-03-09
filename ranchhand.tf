data "template_file" "ranchhand_launcher" {
  template = "${file("${path.module}/templates/ranchhand_launcher.sh.tpl")}"

  vars {
    distro         = "${var.ranchhand_distro}"
    version        = "${var.ranchhand_release}"
    ssh_user       = "${var.admin_username}"
    ssh_key        = "${var.ssh_private_key}"
    node_ips       = "${var.enable_public_endpoint ? join(",", azurerm_public_ip.this.*.ip_address) : join(",", azurerm_network_interface.this.*.private_ip_address)}"
    internal_ips   = "${join(",", azurerm_network_interface.this.*.private_ip_address)}"
    ssh_proxy_host = "${var.ssh_proxy_host}"
    ssh_proxy_user = "${var.ssh_proxy_user}"
  }
}

resource "null_resource" "provision_cluster" {
  triggers {
    instance_ids = "${join(",", azurerm_virtual_machine.this.*.id)}"
  }

  provisioner "local-exec" {
    command = "${data.template_file.ranchhand_launcher.rendered}"
    working_dir = "${var.working_dir}"
  }
}
