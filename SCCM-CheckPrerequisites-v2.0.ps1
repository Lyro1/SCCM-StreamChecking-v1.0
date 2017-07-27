


#Functions section

Function Write-Time( ) 
{
    <#
        .SYNOPSIS
        Function to diplay a timestamped message in the console.
        .DESCRIPTION
        Function designed to display a message preeceded by a timestamp of when the message as been displayed.
        .PARAMETER msg
        This is the content that need to be displayed with a timestamp. It must be a string.
        .PARAMETER value
        This is the type of your message :
            0 - Normal
            1 - Success
            2 - Warning
            3 - Error

        .EXAMPLE
        Write-Time("Hello World") will return "[17/07/2017 13:39:07] Hello World"
        Write-Time("Hello World", 3) will display the same message as above, with a red foreground color : "[17/07/2017 13:39:07] Hello World"
    #>
    param( [string] $msg, [int]$type )
    if ($type -ne 0) {
        switch ($type) 
        {
            1 { Write-Host "[$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')] $msg" -foregroundcolor Green }
            2 { Write-Host "[$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')] $msg" -foregroundcolor Yellow }
            3 { Write-Host "[$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')] $msg" -foregroundcolor Red }
            default { Write-Host "[$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')] $msg" -foregroundcolor White } 
        }
    }
    else {
        Write-Host "[$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')] $msg"
    }
}

Function Test-InternetConnection {
    Test-Connection -ComputerName "http://www.google.com" -count 1 -quiet
}

Function Get-Disks-Infos() 
{
    $harddisks = Get-WmiObject –query “SELECT * from win32_logicaldisk”
    $res = '<ul>'
    if ($harddisks.Count -eq 0) {
        $res = "<ul>No hard drives found on this computer"
    }
    else {
        foreach ($disk in $harddisks) {
            #if ($disk.VolumeName -ne "" -and $disk.Size -gt 0) {
                $res = ($res + ('<li>' + $disk.VolumeName + ' : ' + [Math]::Floor($disk.Size / 1000000000 ) ).ToString() + 'Go (' + ([Math]::Floor($disk.FreeSpace / 1000000000 ) ).ToString() + 'Go Free)</li>')
            #}
            #else {
            #    $res = "<li>Unknown Disk</li>"
            #}
        }
    }
    $res = $res + '</ul>'
    return $res    
}

Function Get-SCCMUsedVersion {
    <#
            .SYNOPSIS
            Get the Microsoft System Center Client application installed and used on the local computer
            .DESCRIPTION
            This function will look for CcmExec.exe in the defautl installation path for this product wether you are on a x86 computer or not.
            Based on the property of the Outlook.exe file it will determine the Outlook version used.
            .EXAMPLE
            Get-SCCMUsedVersion
            
            Will prompt the outlook version installed and used on the local computer.
    #>
    [CmdletBinding()]
    param ()
    $SCCMPath = (Resolve-Path 'C:\Windows\CCM\CcmExec.exe').Path
    $SCCMVersion = ((Get-ItemProperty $SCCMPath).VersionInfo)
    Write-Verbose -Message "[$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')] $($MyInvocation.MyCommand.Name) - Found SCCM Client version $SCCMVersion on the computer"
    if ($SCCMVersion -match '5.0.8325'){
        Write-Output 'SCCM1511'
    }
    elseif ($SCCMVersion -match '5.00.8355'){
        Write-Output 'SCCM1602'
    }
    elseif ($SCCMVersion -match '5.00.8412'){
        Write-Output 'SCCM1606'
    }
	elseif ($SCCMVersion -match '5.00.8458'){
        Write-Output 'SCCM1610'
    }
	elseif ($SCCMVersion -match '5.00.8498'){
        Write-Output 'SCCM1702'
    }
}

Function Get-SCInstalledVersion 
{
    <#
            .SYNOPSIS
            Get the SoftwareCenter application installed on the local computer
            .DESCRIPTION
            This function will look for SoftwareCenter in the default installation path for those products wether you are on a x86 computer or not.
            .EXAMPLE
            Get-SCInstalledVersion
            
            Will prompt the SoftwareCenter installed or not on the local computer.
    #>
    [CmdletBinding()]
    param(
        $OCSInstallationPath = 'C:\Windows\CCM\ClientUX\SCClient.exe'
    )
    if(Test-Path $OCSInstallationPath){
        Write-Verbose -Message "[$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')] $($MyInvocation.MyCommand.Name) - Found SoftwareCenter on the computer"
        $displayedName = 'Yes'
    }
    else {
        Write-Verbose -Message "[$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')] $($MyInvocation.MyCommand.Name) - No Microsoft SoftwareCenter found on the computer"
        $displayedName = 'No'
    }
    
    Write-Output $displayedName
}

Function Test-ActiveDirectoryLabels 
{
    <#
            .SYNOPSIS
            Test if the Active Directory user account exist.
            .DESCRIPTION
            Test if the Active Directory user account exist.
            The test will proceed to a Directory Service Search matching the SAMAccountName of the user.
            .EXAMPLE
            Test-ActiveDirectoryLabels
            
            Will show if the Active Directory user account exist or not.
    #>
    [CmdletBinding()]
    param ()

    $infonContent = ((New-Object DirectoryServices.DirectorySearcher "(&(ObjectCategory=user)(ObjectClass=Person)(SamAccountName=$env:USERNAME))").FindAll())
    if(!$infonContent){
		Write-Verbose -Message "[$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')] $($MyInvocation.MyCommand.Name) - User does not have the Active Directory 'info' attributs set for COMETE NG"
        Write-Output "User account $env:USERNAME <a class='text-danger'>not exist</a> in Active Directory)."
    }
    else {
        Write-Verbose -Message "[$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')] $($MyInvocation.MyCommand.Name) - User exist in the Active Directory"
        Write-Output "User account $env:USERNAME <a class='text-success'>exist</a> in Active Directory."
    }
}

Function Ping-Check($computer, $iPingRetryWait, $iPingRetryTimes)
{
	$bPing = $false
	$ping = New-Object Net.NetworkInformation.Ping
	$PingResult = $ping.send($computer)
	if ($PingResult.Status.Tostring().ToLower() -eq "success")
	{
		$bPing = $true
	} else {
		#if first attemp failed, wait for number of seconds that's defined in XML file and try again
		Start-Sleep $iPingRetryWait
		#attemp to ping few more times (defined in XML file)
		For ($i=1; $i -le $iPingRetryTimes; $i++)
		{
			$PingResult = $ping.send($computer)
			if ($PingResult.Status.Tostring().ToLower() -eq "success")
			{
				$bPing = $true
			}
		}
		
	}
	return $bPing
}

Function Test-UrlResolution {
    <#
            .SYNOPSIS
            Test URL resolution based on DNS query
            .DESCRIPTION
            Test URL resolution based on DNS query
            .EXAMPLE
            Test-UrlResolution -Urls $($entry.Urls -split ',')
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string[]]$Urls
    )
    foreach ($url in $Urls) {
        if($url.ToLower().EndsWith('*')) {
            $subDomain = ($url.split('.'))[0]
            $userDNSDomain = $Env:USERDNSDOMAIN
            $url = $subDomain + '.' + $userDNSDomain
        }
        Write-Time -msg "$($MyInvocation.MyCommand.Name) - Testing the DNS resolution of URL: $url..."
        try {
            if([System.Net.DNS]::GetHostEntry($url)){
                $urlResults = New-Object -TypeName PSObject -Property @{
                    url = $url
                    DnsResolution = $true
                }
                Write-Time -msg "$($MyInvocation.MyCommand.Name) - $url resolved (OK)" -type 1
                $global:success++
            }
            else {
                $urlResults = New-Object -TypeName PSObject -Property @{
                    url = $url
                    DnsResolution = $false
                }
                Write-Time -msg "$($MyInvocation.MyCommand.Name) - $url did not resolved (KO)" -type 3
                $global:failure++
            }
        }
        catch {
            $urlResults = New-Object -TypeName PSObject -Property @{
                url = $url
                DnsResolution = $false
            }
            Write-Time -msg "$($MyInvocation.MyCommand.Name) - $url did not resolved (KO)" -type 3
            $global:failure++
        }
        Write-Output $urlResults
    }
}


Function Test-VipPorts {
    <#
            .SYNOPSIS
            Tests port connection for a specific IP address
            .DESCRIPTION
            This function is used to verify connection to specified ports for specified IP Address
            .EXAMPLE
            Test-VipPorts -Vips $($entry.Vips -split ',') -Ports $($entry | Select-Object -ExpandProperty Ports)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Vips,
        [Parameter(Mandatory = $true)]
        [string]$Port,
        [Parameter(Mandatory = $true)]
        [ValidateSet('TCP', 'UDP')]
        [string]$Protocol,
        [Parameter(Mandatory = $false)]
        [String]$Timeout = 3000
    )
    foreach ($vip in $($Vips -split ',')){
        if ($Protocol -eq 'TCP') {
            $tcpClient = New-Object system.Net.Sockets.TcpClient
            try {
                $iar = $tcpClient.BeginConnect($vip,$Port,$null,$null)
                $wait = $iar.AsyncWaitHandle.WaitOne($Timeout,$false)
                if(!$wait){
                    $tcpClient.Close()
                    $object = New-Object -TypeName PSObject -Property @{
                        IP = $vip
                        Port = $Port
                        Protocol = $Protocol
                        GetResponce = $False
                    }
                    Write-Time -msg "$($MyInvocation.MyCommand.Name) - Port: $Port $Protocol, on IP: $Vip, Connection attempt timed out (KO)" -type 3
                    $global:failure++
                }
                else {
                    if($tcpClient.Connected) {
                        $tcpClient.Close()
                        $object = New-Object -TypeName PSObject -Property @{
                            IP = $vip
                            Port = $Port
                            Protocol = $Protocol
                            GetResponce = $True
                        }
                        Write-Time -msg "$($MyInvocation.MyCommand.Name) - Port: $Port $Protocol, on IP: $Vip, is available (OK)" -type 1
                        $global:success++
                    }
                    else {
                        $object = New-Object -TypeName PSObject -Property @{
                            IP = $vip
                            Port = $Port
                            Protocol = $Protocol
                            GetResponce = $False
                        }
                        Write-Time -msg "$($MyInvocation.MyCommand.Name) - Port: $Port $Protocol, on IP: $Vip, is not available (KO)" -type 3
                        $global:failure++
                    }
                }
            }
            catch {
                $object = New-Object -TypeName PSObject -Property @{
                    IP = $vip
                    Port = $Port
                    Protocol = $Protocol
                    GetResponce = $False
                }
                Write-Time -msg "$($MyInvocation.MyCommand.Name) - Port: $Port $Protocol, on IP: $Vip, is not available (KO)" -type 3
                $global:failure++
            }
            Write-Output $object
        }
        elseif ($Protocol -eq 'UDP') {
            $test = Test-UDPwithPortQry -ComputerName $vip -Protocol $Protocol -Port $Port -PortQryPath $Port
            $object = New-Object -TypeName PSObject -Property @{
                IP = $vip
                Port = $Port
                Protocol = $Protocol
                GetResponce = $test
            }
        Write-Output $object
        }
    }
}

Function Test-UDPwithPortQry  {
    param (
        [Parameter(Mandatory=$true)] 
        [string]$ComputerName,
        [Parameter(Mandatory=$true)] 
        [string]$Protocol,
        [Parameter(Mandatory=$true)] 
        [int]$Port,
        [Parameter(Mandatory=$false)] 
        [string]$PortQryPath = $PortQryLocation
    )
    if ($PortQryPath -ne "") {
        $portQryBin = Test-Path $PortQryPath
    }
    else {
        $portQryBin = False
    }
    

    if ($portQryBin) {

        [string]$command = $PortQryPath
        $portQuery = & $command -n $ComputerName -p $Protocol -e $Port

        if ($portQuery -match "$($Protocol) port $($Port) is LISTENING") {
            
            Write-Time -msg "$($MyInvocation.MyCommand.Name) - $($Protocol) port $($Port) is LISTENING" -type 1
            $result = 'TRUE'
        }
        else {
            
            Write-Time -msg "$($MyInvocation.MyCommand.Name) - $($Protocol) port $($Port) is not found as LISTENING (may be filtered)" -type 2
            $result = 'FALSE'
        }
    }

    else {

        Write-Time -msg "$($MyInvocation.MyCommand.Name) - PortQry has not been found, unable to test UDP port response" -type 3
        $result = 'NOT TESTED'
    }

    Write-Output $result

}







################### ~~~~~~~~~~~~~~~~~~~~~~~~~~~||  SCCM Health Cheking Main Script  ||~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###################


### ~~~~~~~~ Windows notification : Beginning of the checking process

[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

$objNotifyIcon = New-Object System.Windows.Forms.NotifyIcon 

$objNotifyIcon.Icon = "C:\Users\d594416\Documents\Work\Scripts\SCCM-CheckPrerequisites-v2.0\RESSOURCES\favicon_0.ico"
$objNotifyIcon.BalloonTipIcon = "Info" 
$objNotifyIcon.BalloonTipText = "Starting SCCM Prerequisites Cheking..." 
$objNotifyIcon.BalloonTipTitle = "SCCM Check Prerequisites"
 
$objNotifyIcon.Visible = $True 
$objNotifyIcon.ShowBalloonTip(1000)

$begintime = Get-Date
Write-Time("Starting SCCM Prerequisites Cheking...")
$actiondone = 0
$actionsuccess = 0
$actionfail = 0



### ~~~~~~~~ Trying to find the settings.xml file
$settingfound = $FALSE
Try {
    $scriptRoot = Split-Path (Resolve-Path $myInvocation.MyCommand.Path)
    $ConfigXML = Join-Path $scriptRoot "settings.xml"
    $xml = [xml](get-content $configXML)
    Write-Time -msg "Successfully found settings.xml" -type 1
    $actionsuccess++
    $settingfound = $TRUE
}
Catch {
    Write-Time -msg "Can't access settings.xml. Follow the instructions in README" -type 3
    $actionfail++
}
$actiondone++



### ~~~~~~~~ Getting infos from the current user on the current PC
Write-Time("Getting user informations...")
Try {
    $SCCMVersion = Get-SCCMUsedVersion
    $filepath = $PSScriptRoot + '\REPORTS\SCCM-CheckPrerequisites-' + $(Get-Date -Format 'dd-MM-yyyy-HH-mm-ss') +'.html'
    $date = Get-Date -format "dd/MM/yyyy HH:mm:ss"
    $servername = $env:COMPUTERNAME
    $company = $xml.Configuration.Company;
    $IMVersion = Get-SCInstalledVersion
    $ADCheck = Test-ActiveDirectoryLabels
    $cpu = Get-WmiObject -Class Win32_Processor -ComputerName . | Select-Object -Property Name
    $cpuusage = Get-WmiObject -Class Win32_Processor | Measure-Object -property LoadPercentage -Average | Select Average
    $motherboard = Get-WmiObject -Class Win32_BaseBoard -ComputerName .
    $gpu = Get-WmiObject -Class Win32_VideoController -ComputerName . | Select-Object -Property Name
    $ram = Get-WmiObject -Class Win32_PhysicalMemory -computerName . | Select-Object -Property Capacity, MemoryType
    switch ($ram.MemoryType) 
        { 
            0 {$ramtype = "Unknown"} 
            1 {$ramtype = "Other"} 
            2 {$ramtype = "DRAM"} 
            3 {$ramtype = "Synchronous DRAM"} 
            4 {$ramtype = "Cache DRAM"} 
            5 {$ramtype = "EDO"} 
            6 {$ramtype = "EDRAM"} 
            7 {$ramtype = "VRAM"} 
            8 {$ramtype = "SRAM"} 
            9 {$ramtype = "RAM"} 
            10 {$ramtype = "ROM"} 
            11 {$ramtype = "Flash"} 
            12 {$ramtype = "EEPROM"} 
            13 {$ramtype = "FEDROM"} 
            14 {$ramtype = "EPROM"} 
            15 {$ramtype = "CDRAM"} 
            16 {$ramtype = "3DRAM"} 
            17 {$ramtype = "SDRAM"} 
            18 {$ramtype = "SGRAM"} 
            19 {$ramtype = "RDRAM"} 
            20 {$ramtype = "DDR"} 
            21 {$ramtype = "DDR2"} 
            22 {$ramtype = "DDR2 FB-DIMM"} 
            24 {$ramtype = "DDR3"} 
            25 {$ramtype = "FBD2"} 
            default {"Unknown"}
        }
    $disks = Get-Disks-Infos
    $os = Get-WmiObject -Class Win32_OperatingSystem -ComputerName .
    Write-Time -msg "Successfully got user infos" -type 1
    $actionsuccess++
}
Catch {
    Write-Time -msg "Cannot get user infos" -type 3
    $actionfail++
}
$actiondone++



### ~~~~~~~~ Network Checking

Write-Time -msg "Trying to read infos of $company in settings.xml..."



    ## ~~~~~~ We search the differents address regarding the Active Directory Domain the computer is connected to.
Try {
    $primaryserver = $xml.Configuration.Custom.PrimaryServer
    $DPNetworkports = $xml.Configuration.Ports.DP
    $ADnetworkports = $xml.Configuration.Ports.AD
    $DPNetworktxml = $xml.Configuration.Custom.DPNetwork.ChildNodes
    if ($primaryserver -eq $null -and $DPNetworktxml -eq $null) {
        Write-Time -msg "Error : the company $company was not found in the xml file, or its informations are empty." -type 3
        Throw 'lol'
    }
    Write-Time -msg "Successfully got informations for settings.xml" -type 1
    $actionsuccess++
}
Catch {
    Write-Time -msg "Cannot read required informations in settings.xml. Follow the README to fix it" -type 3
    $actionfail++
}
$actiondone++



    ## ~~~~~~ Primary Servers Network Prerequisites
$actionpsn = 0
$actionpsnyes = 0
$actionpsnno = 0
if ($primaryserver -ne "") {
    $primaryservertest = Test-UrlResolution( $primaryserver )
    if ($primaryservertest.DnsResolution) {
        $actionsuccess++
        $actionpsnyes++
    }
    else {
        $actionfail++
        $actionpsnno++
    }
}
else {
    Write-Time -msg "No Primary Server IP found to test..." -type 2
    $actionfail++
    $actionpsnno++
}


$actiondone++
$actionpsn++



    ## ~~~~~~ DP Network Prerequisites
$actiondpn = 0
$actiondpnyes = 0
$actiondpnno = 0
$actionadn = 0
$actionadnyes = 0
$actionadnno = 0

# We create a list to store the result of the tests
$globalresults = @()
Foreach ($DPUrl in $DPNetworktxml) {
    $globalresults += $false
}
$separator = ","

# We will test for each DP Url registered in the xml file under the company input
$range = 0
Foreach ($DPUrl in $DPNetworktxml) {
    $dpnurls = $null
    $locallistres = @($false, $false; $false)
    # We create another list to store the DP Network URL results
    $dpnurllocalarray = @()
    [System.Collections.ArrayList]$dpnurlres = $dpnurllocalarray
    # If there is an URL written in the settings.xml file, we test the url resolution.
    if ($DPUrl.URL -ne "") {
        $dpnetworktest = Test-UrlResolution( $DPUrl.URL )
        $dpnurlres += $dpnetworktest
        if ($dpnetworktest.DnsResolution) {
            $actionsuccess++
            $actiondpnyes++
        }
        else {
            $actionfail++
            $actiondpnno++
        }
        $actiondone++
        $actiondpn++
    }
    else {
        Write-Time -msg "No DP Urls found to test..." -type 2
        $actionfail++
        $actiondpnno++
        $actiondone++
        $actiondpn++
    }
    $locallistres[0] = $dpnurlres

    # We manage the DP Network checking for each DP Network URL
    # First, we create a new list to register all the dpnvips test results
    $dpnviparray = @()
    [System.Collections.ArrayList]$dpnvips = $dpnviparray
    # We make sure that the sentences in the xml file are correct by deleting any blank character
    $separator = ","
    $dpnetworkports = ($dpnetworkports -replace '\s','') -split $separator, 0, "simplematch"
    $DPIPs = ($DPUrl.DPIPs -replace '\s','') -split $separator, 0, "simplematch"
    # If there is at least a DPIP
    if ($DPIPs -ne "") {
        # We test for each DPIP all the DP ports registered in the xml file.
        Foreach ($dpnvip in $DPIPs) {
            Foreach ($dpnport in $dpnetworkports) {
                Write-Time -msg "Testing $dpnvip on port $dpnport with protocol TCP..."
                $localres = Test-VipPorts -Vips $dpnvip -Port $dpnport -Protocol "TCP"
                $dpnvips += $localres
        
                if ($localres.GetResponce) {
                    $actionsuccess++
                    $actiondpnyes++
                }
                else {
                    $actionfail++
                    $actiondpnno++
                }
                $actiondone++   
                $actiondpn++
            }
        }
        $locallistres[1] = $dpnvips
    }
    else {
        Write-Time -msg "No DP IPs found to test..." -type 2
        $actionfail++
        $actiondpnno++
        $actiondone++   
        $actiondpn++
    }

    # Active Directory Network Prerequisites
    # We create a list to store the results of the Active Directory IPs tests
    $ADnetworkiptest = @()
    [System.Collections.ArrayList]$ADnetworkiptestlist = $ADnetworkiptest
    # We make sure that the sentences in the xml file are correct by deleting any blank character
    $separator = ","
    $ADnetworkports = ($ADnetworkports -replace '\s','') -split $separator, 0, "simplematch"
    $ADIPs = ($DPUrl.ADIPs -replace '\s','') -split $separator, 0, "simplematch"
    # If there is at least an Active Directory IP
    if ($ADIPs -ne "") {
        # We test each Active Directory IP with each ports registered in the xml file.
        Foreach ($ADnetworkvip in $ADIPs) {
            Foreach ($ADPort in $ADnetworkports ) {
                if ($ADPort -eq "389") {
                    Write-Time -msg "Testing $ADnetworkvip on port $ADPort with protocol TCP..."
                    $localres = Test-VipPorts -Vips $ADnetworkvip -Port $ADPort -Protocol "TCP"
                    $ADnetworkiptestlist += $localres
                    if ($localres.GetResponce -and $localres.Protocol -eq "TCP") {
                        $actionsuccess++
                        $actionadnyes++
                    }
                    else {
                        $actionfail++
                        $actionadnno++
                    }
                    $actiondone++   
                    $actionadn++

                    Write-Time -msg "Testing $ADnetworkvip on port $ADPort with protocol UDP..."
                    $localres = Test-VipPorts -Vips $ADnetworkvip -Port $ADPort -Protocol "UDP"
                    $ADnetworkiptestlist += $localres
                    if ($localres.GetResponce -and $localres.Protocol -eq "TCP") {
                        $actionsuccess++
                        $actionadnyes++
                    }
                    else {
                        $actionfail++
                        $actionadnno++
                    }
                    $actiondone++   
                    $actionadn++
                }
                else {
                    Write-Time -msg "Testing $ADnetworkvip on port $ADPort with protocol TCP..."
                    $localres = Test-VipPorts -Vips $ADnetworkvip -Port $ADPort -Protocol "TCP"
                    $ADnetworkiptestlist += $localres
                    if ($localres.GetResponce -and $localres.Protocol -eq "TCP") {
                        $actionsuccess++
                        $actionadnyes++
                    }
                    else {
                        $actionfail++
                        $actionadnno++
                    }
                $actiondone++   
                $actionadn++
                }
       
            } 
        }
        $locallistres[2] = $ADnetworkiptestlist
    }
    else {
        Write-Time -msg "No Active Directory IPs found to test..." -type 2
        $actionfail++
        $actionadnno++
        $actiondone++   
        $actionadn++
    }
    $dpnurls += $locallistres
    $globalresults[$range] = $dpnurls
    $range++
}


### ~~~~~~~~ We calculate the porcentage of success of the whole checking process
if ($actiondone -ne 0) {
    $success = [math]::Round(( ($actionsuccess/$actiondone) * 100),2)
    $successmsg = "<p class='text-danger'>Unknown</p>"
    If ($success -gt 75) 
    {
        Write-Time -msg "$success% of success ($actionsuccess/$actiondone)" -type 1
        $successmsg = '<p class="text-success">' + $success + '% of success (' + $actionsuccess + '/' + $actiondone +')</p>'
    }
    Else
    {
        If ($success -le 75 -and $success -gt 50)  
        {
            Write-Time -msg "Warning : only $success% of success ($actionsuccess/$actiondone)" -type 2
            $successmsg = '<p class="text-warning">Warning : ' + $success + '% of success (' + $actionsuccess + '/' + $actiondone +')</p>'
        }
        Else 
        {
            Write-Time -msg "WARNING : ONLY $success% OF SUCCESS ($actionsuccess/$actiondone) | This computer cannot handle a safe SCCM setup for now." -type 3
            $successmsg = '<p class="text-danger">WARNING : ' + $success + '% OF SUCCESS (' + $actionsuccess + '/' + $actiondone +') : This computer cannot handle a safe SCCM setup for now.</p>'
        }
    }
}
else {
    Write-Time -msg "WARNING : ONLY 0% OF SUCCESS (0/0) | This computer cannot handle a safe SCCM setup for now." -type 3
    $successmsg = '<p class="text-danger">WARNING : 0% OF SUCCESS (0/0) : This computer cannot handle a safe SCCM setup for now.</p>'
}


    ## ~~~~~~ We calculate the primary network test sequence porcentage of success
if ($actionpsn -ne 0) {
    $successpsn = [math]::Round(( ($actionpsnyes/$actionpsn) * 100),2)
    If ($successpsn -gt 75) 
    {
        $successpsnmsg = '<p class="text-success">' + $successpsn + '% of success (' + $actionpsnyes + '/' + $actionpsn +')</p>'
    }
    Else
    {
        If ($successpsn -le 75 -and $successpsn -gt 50)  
        {
            $successpsnmsg = '<p class="text-warning">' + $successpsn + '% of success (' + $actionpsnyes + '/' + $actionpsn +')</p>'
        }
        Else 
        {
            $successpsnmsg = '<p class="text-danger">' + $successpsn + '% of success (' + $actionpsnyes + '/' + $actionpsn +')</p>'
        }
    }
}
else {
    $successpsnnmsg = '<p class="text-danger">0% of success (' + $actionpsnyes + '/' + $actionpsn +')</p>'
}

    ## ~~~~~~ We calculate the DP Network test sequence porcentage of success
if ($actiondpn -ne 0) {
    $successdpn = [math]::Round(( ($actiondpnyes/$actiondpn) * 100),2)
    If ($successdpn -gt 75) 
    {
        $successdpnmsg = '<p class="text-success">' + $successdpn + '% of success (' + $actiondpnyes + '/' + $actiondpn +')</p>'
    }
    Else
    {
        If ($successdpn -le 75 -and $successdpn -gt 50)  
        {
            $successdpnmsg = '<p class="text-warning">' + $successdpn + '% of success (' + $actiondpnyes + '/' + $actiondpn +')</p>'
        }
        Else 
        {
            $successdpnnmsg = '<p class="text-danger">' + $successdpn + '% of success (' + $actiondpnyes + '/' + $actiondpn +')</p>'
        }
    }
}
else {
    $successdpnnmsg = '<p class="text-danger">0% of success (' + $actiondpnyes + '/' + $actiondpn +')</p>'
}

    ## ~~~~~~ We calculate the Active Directory Network test sequence porcentage of success
if ($actionadn -ne 0) {
    $successadn = [math]::Round(( ($actionadnyes/$actionadn) * 100),2)
    If ($successadn -gt 75) 
    {
        $successadnmsg = '<p class="text-success">' + $successadn + '% of success (' + $actionadnyes + '/' + $actionadn +')</p>'
    }
    Else
    {
        If ($successadn -le 75 -and $successadn -gt 50)  
        {
            $successadnmsg = '<p class="text-warning">' + $successadn + '% of success (' + $actionadnyes + '/' + $actionadn +')</p>'
        }
        Else 
        {
            $successadnmsg = '<p class="text-danger">' + $successadn + '% of success (' + $actionadnyes + '/' + $actionadn +')</p>'
        }
    }
}
else {
    $successadnnmsg = '<p class="text-danger">0% of success (' + $actionadnyes + '/' + $actionadn +')</p>'
}

$endtime = Get-Date
$duration = $endtime - $begintime

#This is responsible for handling HTML/CSS display at then end
$text = 
'
<style>

body, html {
    width : 100%;
    margin : 0px;
    background-color: #d9e4ec;
}

p, a, li, ul, h1, h2, h3, h4, h5, table {
    font-family: "Hind", sans-serif;
    margin : 0px;
}

.text-danger {
    color : red;
}

.text-warning {
    color : orange;
}

.text-success {
    color : green;
}

.logo {
    margin-left : 10%;
    margin-top : 10px;
}

.title {
   width : 100%;
   border-bottom  : 2px solid rgba(0,0,0,0.3);
}

.report-info {
    width : 80%;
    margin : auto;
    margin-top : 15px;
}

.report-info .content .date {
    font-size : 1.4vh;
    margin-top : 10px;
}

.duration {
    font-size : 1.4vh;
    color : #888;
}

.no-central-server {   
    margin-top : 70px;
    color : red;
    text-align :center;
    font-size : 24px;
}

.si-internet {
    color : green;
}

.flex-line-little {
    display : flex;
    justify-content : space-between;
}

.flex-line {
    display : flex;
    justify-content : space-between;
    width : 80%;
    margin : auto;
    margin-top : 15px;
}

.flex-line-between {
    display : flex;
    justify-content : space-between;
    margin-top : 15px;
}

.item-little {
    width : 150px;
    height : 200px;
    text-align : center;
    color : white;
}

.item-little h2 {
    font-family : 32px;
}

.item-little p {
    margin-top : 25px;
}

.flex-line .server-config {
    display : block;
    width : 45%;
    background-color : #2a6496;
    color : white;
    padding : 15px;
}

.flex-line .server-config .sub-title {
    margin : 2%;
}

.flex-line .server-services {
    display : block;
    width : 45%;
    background-color : #5F9EA0;
    color : white;
    padding : 15px;
}

.flex-line .server-services .sub-title {
    margin : 2%;
}
    

.server-config .content, .server-services .content {
    font-size : 2vh;
}

.server-config .content b  {
    text-transform: uppercase;
    display:inline-block
}

.server-services .content b  {
    text-transform: uppercase;
    display:inline-block
}

.network-test {
    width : 80%;
    margin : auto;
    margin-top : 25px;
}

.network-item {
    width : 90%;
    margin : auto;
    margin-top : 20px;
}

.network-item h3 {
    border-left : 25px solid #2a6496;
    font-size : 20px;
    padding-left : 15px;
}

.network-item table {
    margin-top : 25px;
    margin-bottom : 25px;
    width : 100%;
    background-color : white;
    border-radius : 6px;
    border : 1px solid ccc;
    border-collapse: collapse;
    box-shadow : 1px 1px 0px #888;
}

.network-item table th {
    font-weight : bold;
}

.network-item table th, .network-item table td {
    width : auto;
    padding : 10px;
    padding-left : 20px;
    border-bottom : 1px solid #ccc;
}

</style>

<html>

    <head>
        <title>SCCM Check Prerequisites v2.0 | ' + $date + '</title>
        <link href="RESSOURCES\favicon.ico" rel="icon" type="image/vnd.microsoft.icon">
        <link href="https://fonts.googleapis.com/css?family=Hind" rel="stylesheet"> 
        <meta charset="UTF-8">
    </head>

    <body>

        <div class="logo">
            <img src="your-logo-url" alt="your-logo-description">
        </div>

        <div class="report-info">
            <h2 class="title">Report Info</h2>

            <div class="content">

                <div class="flex-line-little"><div class="date"><p>' +  $date + '</p></div> <div class="porcentage-success">' + $successmsg + '</div> </div>
                <div class="flex-line-little">
                <div class="server">
                    <p>Request from <b>' + $servername + '</b> owned by <b>' + $company + '</b>.</p></div>
                    <p class="duration">Checking done in ' + $duration + '</p>
                </div>
            </div>
        </div>

            <!--<div class="service-list">

                <h2 class="title">Service List</h2>

                <div class="content">
                    <div class="list">



                    </div>
                </div>

            </div>-->

            <div class="flex-line">
            
                <div class="server-config">

                    <h2 class="sub-title">Client Material Configuration</h2>

                    <div class="content">
                        <p><b>CPU:</b> ' + $cpu.Name + ' (used at ' + $cpuusage.Average.ToString() + '%)</p> 
                        <p><b>Motherboard:</b> ' + $motherboard.Manufacturer + ':' + $motherboard.Name + ' (' + $motherboard.SerialNumber + ')</p>
                        <p><b>GPU:</b> ' + $gpu.Name + '</p> 
                        <p><b>RAM:</b> ' + ([Math]::Floor($ram.Capacity / 1000000000 ) ).ToString() + ' Go (Type: ' + $ramtype + ')</p> 
                        <p><b>OS:</b> ' + $os.Name.Substring(0, $os.Name.IndexOf("|")) + ' (' + $os.Version + ')</p>  
                        <p><b>Disk(s):</b> ' + $disks + '</p> 
                    </div>

                </div>

                <div class="server-services">

                    <h2 class="sub-title">Client Services Checking</h2>

                    <div class="content">
                        <p><b>Active Directory Domain:</b> ' + ($env:USERDNSDOMAIN) + '<p>
                        <p>' + $ADCheck + '</p>
                        <p><b>SCCM Version:</b> ' + $SCCMVersion + '</p>
                        <p><b>Software Center:</b> ' + $IMVersion + '</p>
                        <p><b>Powershell Version:</b> ' + ($host.version.major) + '</p>
                    </div>


                </div>
            
            
            </div>

            <div class="network-test">

                <h2 class="title">Network Checks</h2>

                    <div class="network-item">

                        <div class="flex-line-between"><h3>Primary Servers Network Prerequisites</h3>' + $successpsnmsg + '</div>

                        <table>

                            <tr>

                                <th>URL</th>

                                <th>DNS Resolutions</th>

                            </tr>

                            <tr>

                                '
if($primaryservertest.DnsResolution -and $primaryserver -ne "") 
{ 
    $text += '<td style="width : 50%;">' + $primaryservertest.url + '</td>
    <td style="background-color : rgba(0, 153, 0, 0.2); color : rgba(0, 153, 0, 1); width : 50%;">Success</td>'
} 
else { 
    $text += '<td style="width : 50%;">No Primary Server URL Found to test</td>
    <td style="background-color : rgba(153, 0, 0, 0.2); color : rgb(153, 0, 0); width : 50%;">Fail</td>'
}
    
$text += '

                            </tr>

                        </table>

                    </div>
                 

                    <div class="network-item">

                        <div class="flex-line-between"><h3>DP Network Prerequisites</h3>' + $successdpnmsg + '</div>

                        <table>

                            <tr>

                                <th>URL</th>

                                <th>DNS Resolutions</th>

                            </tr>

                            '
Foreach($res in $globalresults) {
        Foreach($dpnurl in $res[0]) {
            $dpnetworktestres = '<tr>
                        <td style="width : 50%;">' + $dpnurl.url + '</td>'
            if($dpnurl.DnsResolution) 
            { 
                $dpnetworktestres += "<td style='background-color : rgba(0, 153, 0, 0.2); color : rgba(0, 153, 0, 1); width : 50%;'>Success</td>" 
            } 
            else { 
                $dpnetworktestres += "<td style='background-color : rgba(153, 0, 0, 0.2); color : rgb(153, 0, 0); width : 50%;'>Fail</td>" 
            }
                
            $dpnetworktestres += "</tr>"

            $text += $dpnetworktestres
        }
        if ($res[0].Count -eq 0) {
            $text += '<tr>
                            <td style="width : 50%;">No DP Network URL found to test</td>
                            <td style="background-color : rgba(153, 0, 0, 0.2); color : rgb(153, 0, 0); width : 50%;">Fail</td>
                         </tr>'
        }
}

$text += '

                            </tr>

                        </table>


                            '
Foreach($res in $globalresults) {
    $text += 

                           ' 
            <h4 style="font-size : 15px; border-left : 25px solid #2a6496; margin-left : 40px; padding-left : 15px;">' + $dpnurl.url + '</h4>
                        <table>
                           <tr>

                                <th>IP</th>

                                <th>Port</th>

                                <th>Protocol</th>

                                <th>Got a reponse</th>

                            </tr>'

    if ($res[1].Count -ne 0) {
        Foreach($DPnetvip in $res[1]) {
            $line = "<tr>
                        <td>" + $DPnetvip.IP + "</td>
                        <td>" + $DPnetvip.Port + "</td>
                        <td>" + $DPnetvip.Protocol + "</td>"
            if ($DPnetvip.GetResponce -and $DPnetvip.Protocol -eq "TCP") {
                $line += ("<td style='background-color : rgba(0, 153, 0, 0.2); color : rgba(0, 153, 0, 1);'>" + $DPnetvip.GetResponce + "</td>")
            }
            if ($DPnetvip.GetResponce -and $DPnetvip.Protocol -ne "TCP") {
                $line += ("<td>No answer</td>")
            }
            if (-not $DPnetvip.GetResponce) {
                $line += ("<td style='background-color : rgba(153, 0, 0, 0.2); color : rgb(153, 0, 0);'>" + $DPnetvip.GetResponce + "</td>")
            }
                
            $line += "</tr>"
        
        $text += $line
        }
        $text += ' </table>'
    }
    else {
        $text += ' 
                           <tr> 
                                <td>No VIP tested</td>
                           </tr>
                           
                        </table>
        ' 
    }
}

$text +=             '

                    </div>
                    

                    <div class="network-item">

                        <div class="flex-line-between"><h3>Active Directory Network Prerequisites</h3>' + $successadnmsg + '</div>

                            '
Foreach ($res in $globalresults) {
$text += 

                           ' 
            <h4 style="font-size : 15px; border-left : 25px solid #2a6496; margin-left : 40px; padding-left : 15px;">' + $dpnurl.url + '</h4>

                        <table>
                           <tr>

                                <th>IP</th>

                                <th>Port</th>

                                <th>Protocol</th>

                                <th>Got a reponse</th>

                            </tr>'
    if ($res[2] -ne $null) {
        Foreach($ADnetworktest in $res[2]) {
            $line = "<tr>
                        <td>" + $ADnetworktest.IP + "</td>
                        <td>" + $ADnetworktest.Port + "</td>
                        <td>" + $ADnetworktest.Protocol + "</td>"
            if ($ADnetworktest.GetResponce -and $ADnetworktest.Protocol -eq "TCP") {
                $line += ("<td style='background-color : rgba(0, 153, 0, 0.2); color : rgba(0, 153, 0, 1);'>" + $ADnetworktest.GetResponce + "</td>")
            }
            if ($ADnetworktest.GetResponce -and $ADnetworktest.Protocol -ne "TCP") {
                $line += ("<td>No answer</td>")
            }
            if (-not $ADnetworktest.GetResponce) {
                $line += ("<td style='background-color : rgba(153, 0, 0, 0.2); color : rgb(153, 0, 0);'>" + $ADnetworktest.GetResponce + "</td>")
            }
                
            $line += "</tr>"

            $text += $line
        }
        $text += ' </table> '
    }
    else {
        $text += '<tr> 
                                <td>No VIP tested</td>
                           </tr>
                      </table> '
    }
}


$text +=             '

                    </div>                    

            </div>

        </body>

    </html>
    '

Try {
    $text | Out-File $filepath
    Write-Time -msg ("Saved the report in " + $filepath.ToString() + ".") -type 1
}
Catch {
    Write-Time -msg ("Can't write the report in " + $filepath + ". It could be related to your access level on this folder.") -type 3
}

Try {
    Invoke-Item $filepath
    Write-Time -msg "Display the report." -type 1
}
Catch {
    Write-Time -msg ("Can't open the report in " + $filepath + ". It could be related to your access level on this folder.") -type 3
}

$objNotifyIcon.BalloonTipText = "End of SCCM Prerequisites Cheking..." 
 
$objNotifyIcon.Visible = $True 
$objNotifyIcon.ShowBalloonTip(10000)
Write-Time("End of SCCM Prerequisites Cheking...")
Start-Sleep 11
$objNotifyIcon.Visible = $False;
