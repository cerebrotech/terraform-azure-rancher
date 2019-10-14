resource "azurerm_lb" "private_lb" {
  count = var.enable_private_lb ? 1 : 0

  name                = "${var.name}-int-lb"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = local.lb_ipconfig_name
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.tags
}

resource "azurerm_lb_backend_address_pool" "private_lb" {
  count = var.enable_private_lb ? 1 : 0

  name                = "${var.name}-addrpool"
  resource_group_name = var.resource_group_name
  loadbalancer_id     = azurerm_lb.private_lb[0].id
}

resource "azurerm_network_interface_backend_address_pool_association" "private_lb" {
  count = var.enable_private_lb ? var.instance_count : 0 # TODO: https://github.com/hashicorp/terraform/issues/10857

  network_interface_id    = element(azurerm_network_interface.vm.*.id, count.index)
  ip_configuration_name   = local.vm_ipconfig_name
  backend_address_pool_id = azurerm_lb_backend_address_pool.private_lb[0].id
}

# TODO: use HTTP checks when rancher chart v2.2.0 is released; currently unsupported.
#   these TCP checks will only ensure that a node/ingress are up and running.
resource "azurerm_lb_probe" "private_https" {
  count = var.enable_private_lb ? 1 : 0

  name                = "tcp-ack-443"
  resource_group_name = var.resource_group_name
  loadbalancer_id     = azurerm_lb.private_lb[0].id
  protocol            = "Tcp"
  port                = 443
}

resource "azurerm_lb_probe" "private_http" {
  count = var.enable_private_lb ? 1 : 0

  name                = "tcp-ack-80"
  resource_group_name = var.resource_group_name
  loadbalancer_id     = azurerm_lb.private_lb[0].id
  protocol            = "Tcp"
  port                = 80
}

resource "azurerm_lb_rule" "private_https" {
  count = var.enable_private_lb ? 1 : 0

  name                = "https"
  loadbalancer_id     = azurerm_lb.private_lb[0].id
  resource_group_name = var.resource_group_name

  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 443
  backend_address_pool_id        = azurerm_lb_backend_address_pool.private_lb[0].id
  frontend_ip_configuration_name = local.lb_ipconfig_name
  probe_id                       = azurerm_lb_probe.private_https[0].id
}

resource "azurerm_lb_rule" "private_http" {
  count = var.enable_private_lb ? 1 : 0

  name                = "http"
  loadbalancer_id     = azurerm_lb.private_lb[0].id
  resource_group_name = var.resource_group_name

  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  backend_address_pool_id        = azurerm_lb_backend_address_pool.private_lb[0].id
  frontend_ip_configuration_name = local.lb_ipconfig_name
  probe_id                       = azurerm_lb_probe.private_http[0].id
}
