output "vms" {
  value = {
    for i, vm in opennebula_virtual_machine.vm :
    "sectools-credit-${i}" => {
      ansible_host = vm.template_nic[0].computed_ip
    }
  }
}
