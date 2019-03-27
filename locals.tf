locals {
  lb_ipconfig_name   = "lb-ipconfig"
  vm_ipconfig_name   = "primary-ipconfig"
  public_lb_routing  = "${var.enable_public_lb ? var.public_lb_routing : false}"
  lb_ip              = "${local.public_lb_routing ? element(concat(azurerm_public_ip.public_lb.*.ip_address, list("")), 0) : element(concat(azurerm_lb.private_lb.*.private_ip_address, list("")), 0)}"

  supported_os = {
    UbuntuServer = {
      publisher = "Canonical"
      offer     = "UbuntuServer"
      sku       = "16.04-LTS"
      version   = "latest"
    }

    CentOS = {
      publisher = "OpenLogic"
      offer     = "CentOS"
      sku       = "7.5"
      version   = "latest"
    }

    RHEL = {
      publisher = "RedHat"
      offer     = "RHEL"
      sku       = "7-RAW-CI"
      version   = "7.5.2018041704"
    }
  }
}
