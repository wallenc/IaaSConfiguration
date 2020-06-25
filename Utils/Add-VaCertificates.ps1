#Function to write output to log file @ C:\Windows\Temp\ProvisioningScript.log
function WriteLog
{
    Param( 
        $message
    )

    $timestampedMessage = $("[" + [System.DateTime]::Now + "] " + $message) | % {
        Out-File -InputObject $_ -FilePath "$env:WinDir\Temp\ProvisioningScript.log" -Append
    }
}

#Cert URI for VA public cert chain
$certURI = "http://aia.pki.va.gov/pki/aia/va/"

#Create temp directories for Certs    
$RootcertsTemp = "C:\Temp\RootCerts"
$CAcertsTemp = "C:\Temp\CACerts"

WriteLog "Script Begin"    
#Create Temp Directory
New-Item -ItemType Directory -Path $RootcertsTemp -Force -Confirm: $false -Verbose
New-Item -ItemType Directory -Path $CAcertsTemp -Force -Confirm: $false -Verbose

#Download Certificates required to join a machine to the domain
Invoke-WebRequest -Uri $certURI/VAInternalRoot.cer -OutFile "$RootcertsTemp\VAInternalRoot.cer"
Invoke-WebRequest -Uri $certURI/VA-Internal-S2-RCA1-v1.cer -OutFile "$CAcertsTemp\VA-Internal-S2-RCA1-v1.cer"
Invoke-WebRequest -Uri $certURI/VA-Internal-S2-ICA2-v1.cer -OutFile "$CAcertsTemp\VA-Internal-S2-ICA2-v1.cer"
Invoke-WebRequest -Uri $certURI/VA-Internal-S2-ICA1-v1.cer -OutFile "$CAcertsTemp\VA-Internal-S2-ICA1-v1.cer"
Invoke-WebRequest -Uri $certURI/InternalSubCA2.cer -OutFile "$CAcertsTemp\InternalSubCA2.cer"
Invoke-WebRequest -Uri $certURI/InternalSubCA1.cer -OutFile "$CAcertsTemp\InternalSubCA1.cer"

#Build array of certificates to import
$RootcertsToImport = Get-ChildItem $RootcertsTemp
$CAcertsToImport = Get-ChildItem $CAcertsTemp

#Import certs to Root store
ForEach ($cert in $RootcertsToImport)
{
    $certDetails = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
    $certDetails.Import($RootcertsTemp + '\' + $cert.Name)
    #Check to see if the certificate is already imported into the Root store
    if (-not (Get-Childitem cert:\LocalMachine\Root | Where-Object { $_.Thumbprint -eq $certDetails.Thumbprint }))
    {
        $store = New-Object System.Security.Cryptography.X509Certificates.X509Store "Root", "LocalMachine"
        #Open the Root store in Read/Write mode
        $store.Open("ReadWrite")
        #Import the cert
        $store.Add($RootcertsTemp + '\' + $cert)
        #Close the store
        $store.Close()
        WriteLog "$cert has been imported into the Root store"
    }
    else
    {
        WriteLog "$cert was already present in the Root Certificate Store"
    }
}

#Import certs to CA store
ForEach ($cert in $CAcertsToImport)
{
    $certDetails = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
    $certDetails.Import($CAcertsTemp + '\' + $cert.Name)
    #Check to see if the certificate is already imported into the Root store
    if (-not (Get-Childitem cert:\LocalMachine\CA | Where-Object { $_.Thumbprint -eq $certDetails.Thumbprint }))
    {
        $store = New-Object System.Security.Cryptography.X509Certificates.X509Store "CA", "LocalMachine"
        #Open the Root store in Read/Write mode
        $store.Open("ReadWrite")
        #Import the cert
        $store.Add($CAcertsTemp + '\' + $cert)
        #Close the store
        $store.Close()
        WriteLog "$cert has been imported into the Root store"
    }
    else
    {
        WriteLog "$cert was already present in the CA Certificate Store"
    }
}

#Cleanup after install
cd..
Remove-Item -path $RootcertsTemp -Recurse
Remove-Item -path $CAcertsTemp -Recurse
