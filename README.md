# Azure Rancher Terraform module

Terraform module which creates an HA deployment of Rancher inside Azure.

## Usage

```hcl
module "rancher_cluster" {
  source = "git@github.com:cerebrotech/terraform-azure-rancher.git"

  instance_count      = 2
  vm_size             = "Standard_B2s"
  location            = "westus2"
  resource_group_name = "my-resources"
  subnet_ids          = ["${azurerm_subnet.services.*.id}"]

  tags {
    Source      = "terraform"
    Environment = "dev"
  }
}
```
