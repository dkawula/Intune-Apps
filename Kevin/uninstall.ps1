#If uninstall we should just need to Stopp the Service and return to a Manual Startup Type
#Yes I know settings will be held we can work on some more logic later

#Service is set to manual by default
Get-Service -Name dot3svc | Set-Service -StartupType Manual

#Start the Service if not running
Get-Service -Name dot3svc | Stop-Service -Force

#Reconnect the Interfaces
netsh lan reconnect interface=*

# Remove the Detection for the App on Uninstall
Get-Item -Path "HKLM:\Software\Intune Detection\8021x"| Remove-Item -Force

