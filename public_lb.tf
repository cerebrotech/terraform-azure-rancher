resource "azurerm_public_ip" "public_lb" {
  count = var.enable_public_lb ? 1 : 0

  name                = "${var.name}-vip-lb"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"
  allocation_method   = "Static"

  tags = var.tags
}

resource "azurerm_lb" "public_lb" {
  count = var.enable_public_lb ? 1 : 0

  name                = "${var.name}-${local.public_lb_routing ? "ext" : "nat"}-lb"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = local.lb_ipconfig_name
    subnet_id                     = var.enable_public_lb ? "" : var.subnet_id
    public_ip_address_id          = var.enable_public_lb ? element(concat(azurerm_public_ip.public_lb.*.id, [""]), 0) : ""
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.tags
}

resource "azurerm_lb_backend_address_pool" "public_lb" {
  count = var.enable_public_lb ? 1 : 0

  name                = "${var.name}-addrpool"
  resource_group_name = var.resource_group_name
  loadbalancer_id     = azurerm_lb.public_lb[0].id
}

resource "azurerm_network_interface_backend_address_pool_association" "public_lb" {
  count = var.enable_public_lb ? var.instance_count : 0 # TODO: https://github.com/hashicorp/terraform/issues/10857

  network_interface_id    = element(azurerm_network_interface.vm.*.id, count.index)
  ip_configuration_name   = local.vm_ipconfig_name
  backend_address_pool_id = azurerm_lb_backend_address_pool.public_lb[0].id
}

# TODO: use HTTP checks when rancher chart v2.2.0 is released; currently unsupported.
#   these TCP checks will only ensure that a node/ingress are up and running.
resource "azurerm_lb_probe" "public_https" {
  count = local.public_lb_routing ? 1 : 0

  name                = "tcp-ack-443"
  resource_group_name = var.resource_group_name
  loadbalancer_id     = azurerm_lb.public_lb[0].id
  protocol            = "Tcp"
  port                = 443
}

resource "azurerm_lb_probe" "public_http" {
  count = local.public_lb_routing ? 1 : 0

  name                = "tcp-ack-80"
  resource_group_name = var.resource_group_name
  loadbalancer_id     = azurerm_lb.public_lb[0].id
  protocol            = "Tcp"
  port                = 80
}

resource "azurerm_lb_rule" "public_https" {
  count = local.public_lb_routing ? 1 : 0

  name                = "https"
  loadbalancer_id     = azurerm_lb.public_lb[0].id
  resource_group_name = var.resource_group_name

  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 443
  backend_address_pool_id        = azurerm_lb_backend_address_pool.public_lb[0].id
  frontend_ip_configuration_name = local.lb_ipconfig_name
  probe_id                       = azurerm_lb_probe.public_https[0].id
}

resource "azurerm_lb_rule" "public_http" {
  count = local.public_lb_routing ? 1 : 0

  name                = "http"
  loadbalancer_id     = azurerm_lb.public_lb[0].id
  resource_group_name = var.resource_group_name

  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  backend_address_pool_id        = azurerm_lb_backend_address_pool.public_lb[0].id
  frontend_ip_configuration_name = local.lb_ipconfig_name
  probe_id                       = azurerm_lb_probe.public_http[0].id
}

resource "azurerm_lb_outbound_rule" "public_outbound_nat" {
  count = var.enable_public_lb ? 1 : 0

  name                = "public-lb-outbound-nat"
  loadbalancer_id     = azurerm_lb.public_lb[0].id
  resource_group_name = var.resource_group_name

  protocol                = "All"
  backend_address_pool_id = azurerm_lb_backend_address_pool.public_lb[0].id

  frontend_ip_configuration {
    name = local.lb_ipconfig_name
  }
}
