﻿Param(
      
    [Parameter(Mandatory = $True)]
    [ValidateNotNullOrEmpty()]
    [string] $SubscriptionId,
         
    [Parameter(Mandatory = $True)]
    [String] $Username,

    [Parameter(Mandatory = $True)]
    [string] $Password,

    [Parameter(Mandatory = $True)]
    [string] $FileURI,

    [Parameter(Mandatory = $True)]
    [string] $resourceGroupName
 
)

function Disable-ieESC {
    $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
    $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
    Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0
    Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0
    Stop-Process -Name Explorer
    Write-Host "IE Enhanced Security Configuration (ESC) has been disabled." -ForegroundColor Green
}

Disable-ieESC


Invoke-WebRequest -Uri $FileURI -OutFile "C:\PSModules.zip"
New-Item -Path "C:\PSModules" -ItemType directory -Force -ErrorAction SilentlyContinue
Expand-Archive "C:\PSModules.zip" -DestinationPath "C:\PSModules" -ErrorAction SilentlyContinue
Set-Location "C:\PSModules"


New-PSDrive -Name RemoveRG -PSProvider FileSystem -Root "C:\PSModules" | Out-Null
@"
<RemoveRG>
<SubscriptionId>$SubscriptionId</SubscriptionId>
<Username>$Username</Username>
<Password>$Password</Password>
<resourceGroupName>$resourceGroupName</resourceGroupName>
</RemoveRG>
"@| Out-File -FilePath RemoveRG:\RemoveRG.xml -Force

     $jobname = "RemoveResourceGroup"
     $script =  "C:\PSModules\RemoveRG.ps1"
     $repeat = (New-TimeSpan -Minutes 1)
     $action = New-ScheduledTaskAction –Execute "$pshome\powershell.exe" -Argument  "$script; quit"
     $duration = (New-TimeSpan -Days 1)
     $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).Date -RepetitionInterval $repeat -RepetitionDuration $duration
     $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable -DontStopOnIdleEnd
     Register-ScheduledTask -TaskName $jobname -Action $action -Trigger $trigger -RunLevel Highest -User "system" -Settings $settings
     <#
    Start-Job -ScriptBlock {
    param($SubscriptionId,$Username,$Password,$resourceGroupName)
    PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& 'C:\PSModules\RemoveRG.ps1' -SubscriptionId $SubscriptionId -Username $Username -Password $Password -resourceGroupName $resourceGroupName"
    } -ArgumentList($SubscriptionId,$Username,$Password,$resourceGroupName) -RunAs32
    #>
    