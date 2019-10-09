resource "azurerm_public_ip" "vm" {
  count = var.enable_public_instances ? var.instance_count : 0

  name                = "${var.name}-vip-${count.index + 1}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"
  allocation_method   = "Static"
  # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
  # force an interpolation expression to be interpreted as a list by wrapping it
  # in an extra set of list brackets. That form was supported for compatibility in
  # v0.11, but is no longer supported in Terraform v0.12.
  #
  # If the expression in the following list itself returns a list, remove the
  # brackets to avoid interpretation as a list of lists. If the expression
  # returns a single list item then leave it as-is and remove this TODO comment.
  zones = [length(var.zones) > 0 ? var.zones[count.index % length(var.zones)] : ""]

  tags = var.tags
}

resource "azurerm_network_interface" "vm" {
  count = var.instance_count

  name                      = "${var.name}-nic-${count.index + 1}"
  location                  = var.location
  resource_group_name       = var.resource_group_name
  network_security_group_id = var.network_security_group_id

  ip_configuration {
    name                          = local.vm_ipconfig_name
    subnet_id                     = var.subnet_id
    public_ip_address_id          = var.enable_public_instances ? element(concat(azurerm_public_ip.vm.*.id, [""]), count.index) : ""
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.tags
}

resource "azurerm_application_security_group" "vm" {
  name                = "${var.name}-asg"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

resource "azurerm_network_interface_application_security_group_association" "vm" {
  # https://github.com/hashicorp/terraform/issues/10857
  #
  # NOTE: switch the count to `length(azurerm_network_interface.vm.*.id)` as
  # soon as computed values are supported.
  count = var.instance_count

  network_interface_id          = element(azurerm_network_interface.vm.*.id, count.index)
  ip_configuration_name         = local.vm_ipconfig_name
  application_security_group_id = azurerm_application_security_group.vm.id
}

resource "azurerm_virtual_machine" "this" {
  count = var.instance_count

  name                  = "${var.name}-${count.index + 1}"
  resource_group_name   = var.resource_group_name
  location              = var.location
  network_interface_ids = [element(azurerm_network_interface.vm.*.id, count.index)]
  vm_size               = var.vm_size
  # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
  # force an interpolation expression to be interpreted as a list by wrapping it
  # in an extra set of list brackets. That form was supported for compatibility in
  # v0.11, but is no longer supported in Terraform v0.12.
  #
  # If the expression in the following list itself returns a list, remove the
  # brackets to avoid interpretation as a list of lists. If the expression
  # returns a single list item then leave it as-is and remove this TODO comment.
  zones = [length(var.zones) > 0 ? var.zones[count.index % length(var.zones)] : ""]

  delete_os_disk_on_termination    = var.delete_os_disk_on_termination
  delete_data_disks_on_termination = var.delete_data_disks_on_termination

  storage_image_reference {
    publisher = var.vm_os_supported == "" ? var.vm_os_publisher : local.supported_os[var.vm_os_supported]["publisher"]
    offer     = var.vm_os_supported == "" ? var.vm_os_offer : local.supported_os[var.vm_os_supported]["offer"]
    sku       = var.vm_os_supported == "" ? var.vm_os_sku : local.supported_os[var.vm_os_supported]["sku"]
    version   = var.vm_os_supported == "" ? var.vm_os_version : local.supported_os[var.vm_os_supported]["version"]
  }

  storage_os_disk {
    name              = "${var.name}-osdisk-${count.index + 1}"
    create_option     = "FromImage"
    caching           = "ReadWrite"
    disk_size_gb      = var.os_disk_size_gb
    managed_disk_type = var.os_disk_type
  }

  storage_data_disk {
    lun               = 0
    name              = "${var.name}-datadisk-${count.index + 1}"
    create_option     = "Empty"
    disk_size_gb      = var.data_disk_size_gb
    managed_disk_type = var.data_disk_type
  }

  os_profile {
    computer_name  = "${var.name}-${count.index + 1}"
    admin_username = var.admin_username
    custom_data    = var.custom_data
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.admin_username}/.ssh/authorized_keys"
      key_data = file(var.ssh_public_key)
    }
  }

  provisioner "remote-exec" {
    inline = "echo 'sshd is running'"

    connection {
      host         = ""    # TF-UPGRADE-TODO: Set this to the IP address of the machine's primary network interface
      type         = "ssh" # TF-UPGRADE-TODO: If this is a windows instance without an SSH server, change to "winrm"
      user         = var.admin_username
      private_key  = file(var.ssh_private_key)
      bastion_host = var.ssh_proxy_host
      bastion_user = var.ssh_proxy_user
    }
  }

  tags = var.tags
}
