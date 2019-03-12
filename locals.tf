locals {
  supported_os = {
    UbuntuServer = {
      publisher = "Canonical"
      offer     = "UbuntuServer"
      sku       = "16.04-LTS"
    }

    CentOS = {
      publisher = "OpenLogic"
      offer     = "CentOS"
      sku       = "7.5"
    }

    RHEL = {
      publisher = "RedHat"
      offer     = "RHEL"
      sku       = "7-RAW-CI"
    }
  }
}
