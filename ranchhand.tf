data "template_file" "ranchhand_launcher" {
  template = "${file("${path.module}/templates/ranchhand_launcher.sh.tpl")}"

  vars {
    distro   = "${var.ranchhand_distro}"
    version  = "${var.ranchhand_version}"
    ssh_user = "${var.admin_username}"
    ssh_key  = "${var.ssh_private_key}"
    node_ips = "${join(",", azurerm_public_ip.this.*.ip_address)}"
  }
}

resource "null_resource" "provision_cluster" {
  triggers {
    instance_ids = "${join(",", azurerm_virtual_machine.this.*.id)}"
  }

  provisioner "local-exec" {
    command = "${data.template_file.ranchhand_launcher.rendered}"
  }
}
