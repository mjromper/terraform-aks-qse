#resource "azurerm_resource_group" "aks" {
#  name     = "${var.resource_group_name}"
#  location = "${var.location}"
#}

# resource "azurerm_virtual_network" "vnet" {
#   name                = "aks-vnet"
#   location            = "${azurerm_resource_group.aks.location}"
#   resource_group_name = "${azurerm_resource_group.aks.name}"
#   address_space       = ["10.1.0.0/16"]
# }

# resource "azurerm_subnet" "subnet" {
#   name                 = "aksnodes"
#   resource_group_name  = "${azurerm_resource_group.aks.name}"
#   address_prefix       = "10.1.0.0/24"
#   virtual_network_name = "${azurerm_virtual_network.vnet.name}"
# }

resource "azurerm_kubernetes_cluster" "akslkn" {
  name                = "${var.cluster_name}"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
  dns_prefix          = "${var.cluster_name}-${var.resource_group_name}"
  #kubernetes_version  = "${var.kubernetes_version}"

  linux_profile {
    admin_username = "azureuser"

    ssh_key {
      key_data = "${file("~/.ssh/id_rsa.pub")}"
    }
  }

  agent_pool_profile {
    name            = "agentpool"
    count           = "${var.agent_count}"
    vm_size         = "Standard_DS2_v2"
    os_type         = "Linux"
    os_disk_size_gb = 30

    # Using Presales subnet
    vnet_subnet_id = "${var.presales_subnet_id}"
  }

  service_principal {
    client_id     = "${var.client_id}"
    client_secret = "${var.client_secret}"
  }

  # network_profile {
  #   network_plugin = "${var.network_plugin}"
  # }

  role_based_access_control {
    enabled = true
  }

  tags = {
    Environment = "Development"
  }

  provisioner "local-exec" {
    command =  "${var.client_type == "linux"? var.linux_script : var.client_type == "mac"? var.mac_script : var.windows_script}"
    environment = {
      AKS_NAME = "${var.cluster_name}"
      AKS_RG   = "${var.resource_group_name}"
      AKS_SUBSCRIPTION   = "${var.subscription_id}"
    }
  }
}

data "azuread_service_principal" "akssp" {
  application_id = "${var.client_id}"
}

# resource "azurerm_role_assignment" "netcontribrole" {
#   scope                = "${azurerm_subnet.subnet.id}"
#   role_definition_name = "Network Contributor"
#   principal_id         = "${data.azuread_service_principal.akssp.object_id}"
# }

