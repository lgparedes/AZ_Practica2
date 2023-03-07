output "resource_group_id" {
  value = azurerm_resource_group.AzureLG.id
}

output "vm_id" {
  value = azurerm_linux_virtual_machine.vm.id
}
