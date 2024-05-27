# Refs:
# https://gist.github.com/maykinayki/fdf1fbc64eee88a80c426555ed3a23d4
# https://learn.microsoft.com/en-us/virtualization/hyper-v-on-windows/user-guide/setup-nat-network
#
# to remove:
# Get-NetNat "LfclassNAT" | Remove-NetNat
#
$NetworkSubnet = 24
$NetworkCIDR = "172.30.0.0/$NetworkSubnet"
$NetAdapterIPAddress = "172.30.0.251"

$SwitchName = "lfclass"
$NATName = "LfclassNAT"

New-VMSwitch -SwitchName $SwitchName -SwitchType Internal

$VMAdapter = Get-VMNetworkAdapter -ManagementOS -SwitchName $SwitchName
$NetAdapter = Get-NetAdapter | Where-Object { $_.DeviceID -eq $VMAdapter.DeviceId }
$NetAdapterIndex = $NetAdapter | Select-Object -ExpandProperty InterfaceIndex

New-NetIPAddress -InterfaceIndex $NetAdapterIndex -IPAddress $NetAdapterIPAddress -PrefixLength $NetworkSubnet
New-NetNat -Name $NATName -InternalIPInterfaceAddressPrefix $NetworkCIDR
