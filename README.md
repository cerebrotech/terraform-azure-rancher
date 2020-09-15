# terraform-azure-rancher

Terraform module which creates an HA deployment of Rancher inside Azure using [RanchHand](https://github.com/dominodatalab/ranchhand).

## Usage

```hcl
module "rancher" {
  source = "github.com/dominodatalab/terraform-azure-rancher"

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

## Development
Please submit any feature enhancements, bug fixes, or ideas via pull requests or issues. 
