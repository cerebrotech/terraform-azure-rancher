terraform {
  required_version = "~> 0.11.11"
}

provider "local" {
  version = "~> 1.1.0"
}

provider "null" {
  version = "~> 2.1.0"
}

provider "template" {
  version = "~> 2.1.0"
}

resource "azurerm_public_ip" "this" {
  count = "${var.enable_public_endpoint ? var.instance_count : 0}"

  name                = "${var.name}-vip-${count.index+1}"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
  allocation_method   = "Dynamic"
  zones               = ["${length(var.zones) > 0 ? var.zones[count.index % length(var.zones)] : ""}"]

  tags = "${var.tags}"
}

resource "azurerm_network_interface" "this" {
  count = "${var.instance_count}"

  name                      = "${var.name}-nic-${count.index+1}"
  location                  = "${var.location}"
  resource_group_name       = "${var.resource_group_name}"
  network_security_group_id = "${var.network_security_group_id}"

  ip_configuration {
    name                          = "primary-ipconfig"
    subnet_id                     = "${var.subnet_ids[count.index % length(var.subnet_ids)]}"
    public_ip_address_id          = "${var.enable_public_endpoint ? element(concat(azurerm_public_ip.this.*.id, list("")), count.index) : ""}"
    private_ip_address_allocation = "Dynamic"
  }

  tags = "${var.tags}"
}

resource "azurerm_application_security_group" "this" {
  name                = "${var.name}-asg"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"

  tags = "${var.tags}"
}

resource "azurerm_network_interface_application_security_group_association" "this" {
  count = "${var.instance_count}"

  network_interface_id          = "${element(azurerm_network_interface.this.*.id, count.index)}"
  ip_configuration_name         = "primary-ipconfig"
  application_security_group_id = "${azurerm_application_security_group.this.id}"
}

resource "azurerm_virtual_machine" "this" {
  count = "${var.instance_count}"

  name                  = "${var.name}-${count.index+1}"
  resource_group_name   = "${var.resource_group_name}"
  location              = "${var.location}"
  network_interface_ids = ["${element(azurerm_network_interface.this.*.id, count.index)}"]
  vm_size               = "${var.vm_size}"
  zones                 = ["${length(var.zones) > 0 ? var.zones[count.index % length(var.zones)] : ""}"]

  delete_os_disk_on_termination    = "${var.delete_os_disk_on_termination}"
  delete_data_disks_on_termination = "${var.delete_data_disks_on_termination}"

  storage_image_reference {
    publisher = "${var.vm_os_supported == "" ? var.vm_os_publisher : lookup(local.supported_os[var.vm_os_supported], "publisher")}"
    offer     = "${var.vm_os_supported == "" ? var.vm_os_offer : lookup(local.supported_os[var.vm_os_supported], "offer")}"
    sku       = "${var.vm_os_supported == "" ? var.vm_os_sku : lookup(local.supported_os[var.vm_os_supported], "sku")}"
    version   = "${var.vm_os_version}"
  }

  storage_os_disk {
    name              = "${var.name}-osdisk-${count.index+1}"
    create_option     = "FromImage"
    caching           = "ReadWrite"
    disk_size_gb      = "${var.os_disk_size_gb}"
    managed_disk_type = "${var.os_disk_type}"
  }

  storage_data_disk {
    lun               = 0
    name              = "${var.name}-datadisk-${count.index+1}"
    create_option     = "Empty"
    disk_size_gb      = "${var.data_disk_size_gb}"
    managed_disk_type = "${var.data_disk_type}"
  }

  os_profile {
    computer_name  = "${var.name}-${count.index+1}"
    admin_username = "${var.admin_username}"
    custom_data    = "${var.custom_data}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.admin_username}/.ssh/authorized_keys"
      key_data = "${file("${var.ssh_public_key}")}"
    }
  }

  # Dummy ssh session to ensure we're ready for rancher install
  provisioner "remote-exec" {
    inline = "echo Kilroy was here"

    connection {
      user = "${var.ssh_proxy_user}"
      private_key = "${file(var.ssh_private_key)}"
      bastion_host = "${var.ssh_proxy_host}"
      bastion_user = "${var.ssh_proxy_user}"
    }
  }

  tags = "${var.tags}"
}
