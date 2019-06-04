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

data "template_file" "ranchhand_launcher" {
  template = "${file("${path.module}/templates/launch_ranchhand.sh")}"

  vars {
    distro   = "${var.ranchhand_distro}"
    release  = "${var.release}"
    node_ips = "${local.node_ips}"

    cert_ips       = "${join(",", local.ranchhand_cert_ips)}"
    cert_dns_names = "${join(",", var.ranchhand_cert_dnsnames)}"

    ssh_user       = "${var.admin_username}"
    ssh_key_path   = "${var.ssh_private_key}"
    ssh_proxy_user = "${var.ssh_proxy_user}"
    ssh_proxy_host = "${var.ssh_proxy_host}"
  }
}

resource "null_resource" "provision_cluster" {
  triggers {
    instance_ids = "${join(",", azurerm_virtual_machine.this.*.id)}"
  }

  provisioner "local-exec" {
    command     = "${data.template_file.ranchhand_launcher.rendered}"
    interpreter = ["/bin/bash", "-c"]
    working_dir = "${var.ranchhand_working_dir}"

    environment = {
      RANCHER_PASSWORD = "${random_string.password.result}"
    }
  }
}
