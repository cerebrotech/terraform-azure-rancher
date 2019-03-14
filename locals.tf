locals {
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
