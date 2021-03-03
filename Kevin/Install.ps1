
#Windows 10 Post Configuration Script
#Turn on 802.1x Authentication Tab on the Network Adapter Properties
#Deploy the Root Certificates first using Intune

#Flip to 64 bit PowerShell

$Is64Bit = $false

Function Restart-As64BitProcess { 
If ([System.Environment]::Is64BitProcess) { return } $Invocation = $($MyInvocation.PSCommandPath)
if ($Invocation -eq $null) { return }
$sysNativePath = $psHome.ToLower().Replace("syswow64", "sysnative")
Start-Process "$sysNativePath\powershell.exe" -ArgumentList "-ex bypass -file "$Invocation" -Is64Bit" -WindowStyle Hidden -Wait }

Restart-As64BitProcess

#This might get packaged as a Win32 App / Required
#It will come down after the Certs so it should work.

start-transcript c:\temp\802.1x.log
Copy-Item "$($PSScriptRoot)\install.ps1" -Destination "c:\temp\install.ps1" -Force

#Service is set to manual by default
Get-Service -Name dot3svc | Set-Service -StartupType Automatic

#Start the Service if not running
Get-Service -Name dot3svc | Set-Service -Status Running  

#Take the XML File that was exported and copy it into the script then generate a new XML File in c:\Temp

$LanProfileSource = [xml]@"
<?xml version="1.0"?>
<LANProfile xmlns="http://www.microsoft.com/networking/LAN/profile/v1">
	<MSM>
		<security>
			<OneXEnforced>false</OneXEnforced>
			<OneXEnabled>true</OneXEnabled>
			<OneX xmlns="http://www.microsoft.com/networking/OneX/v1">
				<cacheUserData>true</cacheUserData>
				<EAPConfig><EapHostConfig xmlns="http://www.microsoft.com/provisioning/EapHostConfig"><EapMethod><Type xmlns="http://www.microsoft.com/provisioning/EapCommon">13</Type><VendorId xmlns="http://www.microsoft.com/provisioning/EapCommon">0</VendorId><VendorType xmlns="http://www.microsoft.com/provisioning/EapCommon">0</VendorType><AuthorId xmlns="http://www.microsoft.com/provisioning/EapCommon">0</AuthorId></EapMethod><Config xmlns="http://www.microsoft.com/provisioning/EapHostConfig"><Eap xmlns="http://www.microsoft.com/provisioning/BaseEapConnectionPropertiesV1"><Type>13</Type><EapType xmlns="http://www.microsoft.com/provisioning/EapTlsConnectionPropertiesV1"><CredentialsSource><CertificateStore><SimpleCertSelection>true</SimpleCertSelection></CertificateStore></CredentialsSource><ServerValidation><DisableUserPromptForServerValidation>false</DisableUserPromptForServerValidation><ServerNames></ServerNames><TrustedRootCA>a8 98 5d 3a 65 e5 e5 c4 b2 d7 d6 6d 40 c6 dd 2f b1 9c 54 36 </TrustedRootCA><TrustedRootCA>df 3c 24 f9 bf d6 66 76 1b 26 80 73 fe 06 d1 cc 8d 4f 82 a4 </TrustedRootCA></ServerValidation><DifferentUsername>false</DifferentUsername><PerformServerValidation xmlns="http://www.microsoft.com/provisioning/EapTlsConnectionPropertiesV2">true</PerformServerValidation><AcceptServerName xmlns="http://www.microsoft.com/provisioning/EapTlsConnectionPropertiesV2">false</AcceptServerName></EapType></Eap></Config></EapHostConfig></EAPConfig>
			</OneX>
		</security>
	</MSM>
</LANProfile>
"@
$LanProfileSource.Save("c:\temp\ethernet.xml")

#Import Lan Profile 

netsh lan add profile filename="c:\temp\ethernet.xml" interface=*

#Reconnect the Interfaces
netsh lan reconnect interface=*

#Now we need a simple detection Method for the App It will just check to see if this file is here.

Function Create-Regkeys {

$testpath = test-path -Path "HKLM:\Software\Intune Detection"

if (-not ($testpath)){

New-Item -Path "HKLM:\Software" -Name "Intune Detection" -Force
}

$testpath = test-path -Path "HKLM:\Software\Intune Detection\8021x"

if (-not ($testpath)) {

New-Item -Path "HKLM:\Software\Intune Detection" -Name "8021x" -Force
}


New-ItemProperty -Path "HKLM:\Software\Intune Detection\8021x" -Name "AppPresent" -Value "True" -PropertyType "String" -force
}

Create-Regkeys

<#>
#Working

#Export existing configuration
netsh lan export profile folder=c:\temp interface="Ethernet 2"

#Sample Configuration
$LanProfileSource = [xml]@"s
<?xml version="1.0"?>
<LANProfile xmlns="http://www.microsoft.com/networking/LAN/profile/v1">
	<MSM>
		<security>
			<OneXEnforced>false</OneXEnforced>
			<OneXEnabled>true</OneXEnabled>
			<OneX xmlns="http://www.microsoft.com/networking/OneX/v1">
				<cacheUserData>true</cacheUserData>
				<EAPConfig><EapHostConfig xmlns="http://www.microsoft.com/provisioning/EapHostConfig"><EapMethod><Type xmlns="http://www.microsoft.com/provisioning/EapCommon">13</Type><VendorId xmlns="http://www.microsoft.com/provisioning/EapCommon">0</VendorId><VendorType xmlns="http://www.microsoft.com/provisioning/EapCommon">0</VendorType><AuthorId xmlns="http://www.microsoft.com/provisioning/EapCommon">0</AuthorId></EapMethod><Config xmlns="http://www.microsoft.com/provisioning/EapHostConfig"><Eap xmlns="http://www.microsoft.com/provisioning/BaseEapConnectionPropertiesV1"><Type>13</Type><EapType xmlns="http://www.microsoft.com/provisioning/EapTlsConnectionPropertiesV1"><CredentialsSource><CertificateStore><SimpleCertSelection>true</SimpleCertSelection></CertificateStore></CredentialsSource><ServerValidation><DisableUserPromptForServerValidation>false</DisableUserPromptForServerValidation><ServerNames></ServerNames><TrustedRootCA>a8 98 5d 3a 65 e5 e5 c4 b2 d7 d6 6d 40 c6 dd 2f b1 9c 54 36 </TrustedRootCA><TrustedRootCA>df 3c 24 f9 bf d6 66 76 1b 26 80 73 fe 06 d1 cc 8d 4f 82 a4 </TrustedRootCA></ServerValidation><DifferentUsername>false</DifferentUsername><PerformServerValidation xmlns="http://www.microsoft.com/provisioning/EapTlsConnectionPropertiesV2">true</PerformServerValidation><AcceptServerName xmlns="http://www.microsoft.com/provisioning/EapTlsConnectionPropertiesV2">false</AcceptServerName></EapType></Eap></Config></EapHostConfig></EAPConfig>
			</OneX>
		</security>
	</MSM>
</LANProfile>
"@
$LanProfileSource.Save("c:\temp\ethernet.xml")

</#>


stop-transcript
