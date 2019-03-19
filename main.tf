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

resource "azurerm_public_ip" "vm" {
  count = "${var.enable_public_instances ? var.instance_count : 0}"

  name                = "${var.name}-vip-${count.index+1}"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
  sku                 = "Standard"
  allocation_method   = "Static"
  zones               = ["${length(var.zones) > 0 ? var.zones[count.index % length(var.zones)] : ""}"]

  tags = "${var.tags}"
}

resource "azurerm_network_interface" "vm" {
  count = "${var.instance_count}"

  name                      = "${var.name}-nic-${count.index+1}"
  location                  = "${var.location}"
  resource_group_name       = "${var.resource_group_name}"
  network_security_group_id = "${var.network_security_group_id}"

  ip_configuration {
    name                          = "${local.vm_ipconfig_name}"
    subnet_id                     = "${var.subnet_id}"
    public_ip_address_id          = "${var.enable_public_instances ? element(concat(azurerm_public_ip.vm.*.id, list("")), count.index) : ""}"
    private_ip_address_allocation = "Dynamic"
  }

  tags = "${var.tags}"
}

resource "azurerm_application_security_group" "vm" {
  name                = "${var.name}-asg"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"

  tags = "${var.tags}"
}

resource "azurerm_network_interface_application_security_group_association" "vm" {
  # https://github.com/hashicorp/terraform/issues/10857
  #
  # NOTE: switch the count to `length(azurerm_network_interface.vm.*.id)` as
  # soon as computed values are supported.
  count = "${var.instance_count}"

  network_interface_id          = "${element(azurerm_network_interface.vm.*.id, count.index)}"
  ip_configuration_name         = "${local.vm_ipconfig_name}"
  application_security_group_id = "${azurerm_application_security_group.vm.id}"
}

resource "azurerm_virtual_machine" "this" {
  count = "${var.instance_count}"

  name                  = "${var.name}-${count.index+1}"
  resource_group_name   = "${var.resource_group_name}"
  location              = "${var.location}"
  network_interface_ids = ["${element(azurerm_network_interface.vm.*.id, count.index)}"]
  vm_size               = "${var.vm_size}"
  zones                 = ["${length(var.zones) > 0 ? var.zones[count.index % length(var.zones)] : ""}"]

  delete_os_disk_on_termination    = "${var.delete_os_disk_on_termination}"
  delete_data_disks_on_termination = "${var.delete_data_disks_on_termination}"

  storage_image_reference {
    publisher = "${var.vm_os_supported == "" ? var.vm_os_publisher : lookup(local.supported_os[var.vm_os_supported], "publisher")}"
    offer     = "${var.vm_os_supported == "" ? var.vm_os_offer : lookup(local.supported_os[var.vm_os_supported], "offer")}"
    sku       = "${var.vm_os_supported == "" ? var.vm_os_sku : lookup(local.supported_os[var.vm_os_supported], "sku")}"
    version   = "${var.vm_os_supported == "" ? var.vm_os_version : lookup(local.supported_os[var.vm_os_supported], "version")}"
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

  provisioner "remote-exec" {
    inline = "echo 'sshd is running'"

    connection {
      user         = "${var.admin_username}"
      private_key  = "${file(var.ssh_private_key)}"
      bastion_host = "${var.ssh_proxy_host}"
      bastion_user = "${var.ssh_proxy_user}"
    }
  }

  tags = "${var.tags}"
}

resource "azurerm_public_ip" "lb" {
  count = "${var.enable_public_lb ? 1 : 0}"

  name                = "${var.name}-vip-lb"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
  sku                 = "Standard"
  allocation_method   = "Static"

  tags = "${var.tags}"
}

resource "azurerm_lb" "this" {
  name                = "${var.name}-${var.enable_public_lb ? "ext" : "int"}-lb"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "${local.lb_ipconfig_name}"
    subnet_id                     = "${var.enable_public_lb ? "" : var.subnet_id}"
    public_ip_address_id          = "${var.enable_public_lb ? azurerm_public_ip.lb.id : ""}"
    private_ip_address_allocation = "Dynamic"
  }

  tags = "${var.tags}"
}

resource "azurerm_lb_backend_address_pool" "this" {
  name                = "${var.name}-addrpool"
  resource_group_name = "${var.resource_group_name}"
  loadbalancer_id     = "${azurerm_lb.this.id}"
}

resource "azurerm_network_interface_backend_address_pool_association" "this" {
  count = "${var.instance_count}" # TODO: https://github.com/hashicorp/terraform/issues/10857

  network_interface_id    = "${element(azurerm_network_interface.vm.*.id, count.index)}"
  ip_configuration_name   = "${local.vm_ipconfig_name}"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.this.id}"
}

# TODO: use HTTP checks when rancher chart v2.2.0 is released; currently unsupported.
#   these TCP checks will only ensure that a node/ingress are up and running.
resource "azurerm_lb_probe" "https" {
  name                = "tcp-ack-443"
  resource_group_name = "${var.resource_group_name}"
  loadbalancer_id     = "${azurerm_lb.this.id}"
  protocol            = "Tcp"
  port                = 443
}

resource "azurerm_lb_probe" "http" {
  name                = "tcp-ack-80"
  resource_group_name = "${var.resource_group_name}"
  loadbalancer_id     = "${azurerm_lb.this.id}"
  protocol            = "Tcp"
  port                = 80
}

resource "azurerm_lb_rule" "https" {
  name                = "https"
  loadbalancer_id     = "${azurerm_lb.this.id}"
  resource_group_name = "${var.resource_group_name}"

  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 443
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.this.id}"
  frontend_ip_configuration_name = "${local.lb_ipconfig_name}"
  probe_id                       = "${azurerm_lb_probe.https.id}"
}

resource "azurerm_lb_rule" "http" {
  name                = "http"
  loadbalancer_id     = "${azurerm_lb.this.id}"
  resource_group_name = "${var.resource_group_name}"

  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.this.id}"
  frontend_ip_configuration_name = "${local.lb_ipconfig_name}"
  probe_id                       = "${azurerm_lb_probe.http.id}"
}
