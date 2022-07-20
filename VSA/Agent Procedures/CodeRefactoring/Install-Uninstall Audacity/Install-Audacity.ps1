## This script downloads and silently installs Audacity 2.2.2
param (
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()] 
    [string] $URL,
    [parameter(Mandatory=$false)]
    [string] $Destination = "$env:TEMP\audacity.exe"
)
if ($URL -eq 'Test') {
    $URL = 'https://dl2.boxcloud.com/d/1/b1!-jagSASpgkrRD43UNoTYcvsiLRYWyJY9Hr4Id2uR9eK90tP7sY9S9nwvIG3UFrvQKtKVaC-B-qq60lgJpRsiWK6EGovLMTpPiKxCU7jBzKazEQ-BvC79uoY_MpeXQgC-Yql38lYWUfJBNeKWrFGT54SiPlaZ4XNTlYVVarZlVFMiUlN5px7J26q4fNQM2v3f9ygHdSSxvt1EiHbZZQimdJjzrvJB3qqiM6D5LHqKF7LEekMFLclirUrdiNXGhkVqqdrc_I07_r3Met_YgQV76ulDfcsd935iLXd-oTziy-yl1tIC2_iI-Y_mNsrJUXoDV-t6ndqsKOK4sdDnqhbzCm0syzWJ7BA1mesK6joM7B-6MJSCH99QjBfUVfqxrApUQAqewzC4l2bZE0ob6-yG318yDavZz8XD5OYyKYqVkpJerc8dhwRSJI0v4oaEIsk9HiqG6yNUqGV8rg47pvCeRHzE6Zb3gcLTxmzNAWArnLzCWpwxpYqf2DSN9OZsmybJ-JvtbE8XPkSf0n3CwattoE6wmgCUGnH-OVup5K-Uajh0FI1ngUoKvOi-ltk1rc7B2wqwsXl2kiz9bcDTFcDfqjktfAxz0v33Q5T7zfphJPusHfckXo7EPMHk08tmOAr2EaM33BHRCYdZ3PFFUJu1R0N5Z0RAlVrdn1a0zaYYV0bRjEZKMp4-Wf10J7qINHPQxtim_5WBK217uGRJBhZarzkldYTNXxOLHFdqhG5rfu08ImSGVDqAs73aBW1QuHqvS5DUiP6Kqk-4APwcIuYg9bYMH6s9PdbhYVcAwbFKBC2T8MRQGCemG9WAoFGw2SvASn7oLzGfBOO3IBot2rGOajnRM7Iq7-ETcD2Ei_n35yQMyRjkJ5yzYKZUSOl-djEJz1dfDgjWqifM9WRjTlZk8BOBDXPmd7ZLorD5HOgXGxJQmwTqM1JmHbtlz2kAJ6zKpFpBnGzn_VxBp8_XVLs2-_nU3zW7n2uQeQ_I6Jpl6I04qjl_941moFovtMZdeVYeYNHnBzJVaLsRQCQQDPXzvh1LEsmGyQ-qKSMUYYwPagTEnp0AnukJqu77hf3RInjS3kkEwyWDb-8F5tJu5AT8wrw5C8s3uh7bhQuM1oEtGSpm9srei7qdU58yyZFnkBuN7xfkg6OAQZ2NMSv9zr_EVFQwWB2ifE0f2qSX9rKlsQ0x6OSAyXXjqWGIp1ZFwRTt7Ll5uuL2MEPFkIoQt9FOrlfOErWyceJAkeNYHdl6m2G65Q1aWYkIsue2swLdE0TLGyBm6N60qC8JJSKKO7FGVNxP/download'
}

#Define variables
$AppName = "Audacity"
$AppFullName = "Audacity*"

#Create VSA X Event Source if it doesn't exist
if ( -not [System.Diagnostics.EventLog]::SourceExists("VSA X")) {
    [System.Diagnostics.EventLog]::CreateEventSource("VSA X", "Application")
}

function Get-RegistryRecords {
    Param($productDisplayNameWithWildcards)

    $machine_key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
    $machine_key6432 = 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'

    return Get-ItemProperty -Path @($machine_key, $machine_key6432) -ErrorAction SilentlyContinue |
           Where-Object {
              $_.DisplayName -like $productDisplayNameWithWildcards
           } | Sort-Object -Property @{Expression = {$_.DisplayVersion}; Descending = $True} | Select-Object -First 1
}


#Lookup related records in Windows Registry to check if application is already installed
function Test-IsInstalled(){
    return Get-RegistryRecords($AppFullName);
}

#Start download
function Get-Installer($URL) {

    Write-Output "Downloading $AppName installer."
	$ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $URL -OutFile $Destination

    if (Test-Path -Path $Destination) {
        Start-Install
    } else {

        [System.Diagnostics.EventLog]::WriteEntry("VSA X", "Unable to download $AppName installation file.", "Error", 400)
    }
}

#Execute installer
function Start-Install() {

    Write-Output "Starting $AppName installation."
    Start-Process -FilePath $Destination -ArgumentList "/VERYSILENT /NORESTART" -Wait
}

#Delete installation file
function Start-Cleanup() {

    Write-Output "Removing installation files."
    Remove-Item -Path $Destination -ErrorAction SilentlyContinue
}

#If application is not installed yet, continue with installation
if (Test-IsInstalled -ne $null) {

    [System.Diagnostics.EventLog]::WriteEntry("VSA X", "$AppName is already installed on the target computer, not proceeding with installation.", "Warning", 300)
    Write-Output "$AppName is already installed on the target computer, not proceeding with installation."

    break

} else {
    
    [System.Diagnostics.EventLog]::WriteEntry("VSA X", "$AppName installation process has been initiated by VSA X script", "Information", 200)

    Get-Installer($URL)
    Start-Cleanup
    
    Start-Sleep -s 10

    $Installed = Test-IsInstalled

    #Verify that application has been successfully installed
    if ($null -eq $Installed) {

        [System.Diagnostics.EventLog]::WriteEntry("VSA X", "Couldn't install $AppName on the target computer.", "Error", 400)
        Write-Output "Couldn't install $AppName on the target computer."

    } else {
        [System.Diagnostics.EventLog]::WriteEntry("VSA X", "$AppName has been successfully installed.", "Information", 200)
        Write-Output "$AppName has been successfully installed."
    }
}