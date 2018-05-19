<###########################################################################

Copyright 2017 Marco Obinu - www.omegamadlab.com

Software release under MIT License

Permission is hereby granted, free of charge, to any person obtaining a 
copy of this software and associated documentation files (the "Software"), 
to deal in the Software without restriction, including without limitation 
the rights to use, copy, modify, merge, publish, distribute, sublicense, 
and/or sell copies of the Software, and to permit persons to whom the 
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included 
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS 
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE 
SOFTWARE.
############################################################################>

########################################################################
## Menu and input management helper functions
########################################################################

function Show-Header {
    [CmdletBinding()]
    param (
        [parameter(Mandatory=$false)]
        [ValidateLength(0,111)]
        [string]
        $Title
    )

    $ConsoleWidth = 115

    if($Title.Length -eq 0) {
        $string = "=" * $ConsoleWidth
    }
    else {
        $BarLenght = $ConsoleWidth - $Title.Length - 2
        if (($BarLenght % 2) -eq 0) {
            $string = "$("=" * ($BarLenght / 2)) $Title $("=" * ($BarLenght / 2))"
        }
        else {
            $string = "$("=" * ($BarLenght / 2)) $Title $("=" * (($BarLenght / 2) - 1))"
        }
    }

    Write-host $string`n -ForegroundColor Cyan
    
}

function Show-Menu {
    [CmdletBinding()]
    param (
        [parameter(Mandatory=$false)]
        [ValidateLength(0,115)]
        [string]
        $Title,

        [parameter(Mandatory=$true)]
        [System.Collections.Specialized.OrderedDictionary]
        $MenuItem
    )
    if ($Title.Length -gt 0) {
        Write-Host "$Title" -ForegroundColor Cyan
    }
    $MenuItem.Keys | ForEach-Object {Write-Host "[$($_)]: $($menuItems["$($_)"])"}
}

Function Get-UserInput {
    
    param (
        [string] $Text = "Choose an option:",
        [System.Collections.Specialized.OrderedDictionary]$AllowedInput,
        [string] $Default,
        [String[]] $ExitChar
    )

    Write-host ""
    if(-not [string]::isNullOrEmpty($Default)) {
        $Text += " [$($Default)]"
    }

    Do {
        $input = Read-Host $Text

        if([string]::isNullOrEmpty($input)) {
            $input = $default
        }
    
        foreach ($key in $AllowedInput.Keys) {
            if($key.indexOf('..') -gt -1) {
                $splitRange = $key.split('..')
                if($input -ge $splitRange[0] -and $input -le $splitRange[2]) {
                    Return $input
                }
            }
            elseif($input -eq $key)
            {
                Return $input
            }
        }
    } Until ($input -in $ExitChar)
	Return $input
}

function Get-NumericInput {
    
    param (
        [string]$TextToPrompt,
        [int]$Default
    )

    $number=0
    if($Default) {
        $TextToPrompt = "$TextToPrompt [$($Default.toString())]"
    }
    Do {
        $outValue = Read-Host -Prompt $textToPrompt
        if(-not $outValue) {
            $outValue = $Default
        }
    } Until ([System.Int32]::TryParse($outValue, [ref]$number))
    Return $outValue
}

function Get-YN {
    param (
        [string]$Question,
        [string]$YesText,
        [string]$NoText,
        [string]$Default = 'Y'
    )

        $YoNMenu = [ordered]@{
            "Y" = "$($YesText)";
            "N" = "$($NoText)";
        }
        
        if(-not($YesText) -and -not($NoText)) {
            $text = "$Question (Y/N)"
            $action = Get-UserInput -AllowedInput $YoNMenu -Text $Text -Default $Default -ExitChar @("Y","N")
        }
        else {
            $text = $Question
            if($YesText) {
                $text += "`n`t[Y]es - $YesText"
            }
            else {
                $text += "`n`t[Y]es"
            }
            if($NoText) {
                $text += "`n`t[N]o - $NoText"
            }
            else {
                $text += "`n`t[N]o"
            }
            Write-Host $Text
            $action = Get-UserInput -AllowedInput $YoNMenu -Default $Default -ExitChar @("Y","N")
        }
        $ReturnValue = $false
        if($action -eq 'Y') {
            $ReturnValue = $true
        }
        $ReturnValue
}

function Get-UserInputForStorage {

	param (
		[switch]$StoragePool,
		[switch]$VirtualDisk,
		[switch]$Volume,
        [string]$usedLetter
	)

	$StorageParams = New-Object -TypeName PSObject
	$StorageParams | Add-Member -NotePropertyName 'StoragePoolFriendlyName' -NotePropertyValue ""
	$StorageParams | Add-Member -NotePropertyName 'LUN' -NotePropertyValue ""
	$StorageParams | Add-Member -NotePropertyName 'SingleDiskSizeGB' -NotePropertyValue ""
	$StorageParams | Add-Member -NotePropertyName 'VirtualDiskFriendlyName' -NotePropertyValue ""
	$StorageParams | Add-Member -NotePropertyName 'WorkloadType' -NotePropertyValue ""
	$StorageParams | Add-Member -NotePropertyName 'DriveLetter' -NotePropertyValue ""
    $StorageParams | Add-Member -NotePropertyName 'VolumeLabel' -NotePropertyValue ""
	$StorageParams | Add-Member -NotePropertyName 'FileSystem' -NotePropertyValue ""

	if($StoragePool) {
		
		$availableDisk = Get-PoolableDiskInfo -OnlyEmpty
		Write-Host "You can new a storage pool with following disks:"
		$availableDisk | ForEach-Object { Write-Host "LUN $($_.ScsiLun) - $($_.Size) GB"}
        $LunToBePooled = @()
		Do {
  
        	#$defaultValue = $availableDisk.ScsiLun | Where-Object $_ -NotIn $LunToBePooled | Select-Object -First 1
			Do {
                if($LunToBePooled.Count -eq 0) { 
                    $value = Read-Host "Insert the LUN number of the first disk which will compose the storage pool, or Q to abort"
                }
                else {
                    $value = Read-Host "Insert the LUN number of an additional disk which will added to the storage pool, or C to abort"
                }
            } Until ($value -notin @("Q", "C") -or $value -notin $availableDisk.ScsiLun)
            if($value -eq "Q") {
                Return
            }
            else {
                if($Value -eq "C") {
                    if($LunToBePooled.Count -eq 0) {
                        Write-Host "Select at least one of the proposed LUNs to continue"
                    }
                    else {
                        break
                    }
                }
                $LunToBePooled += $value
            }
        }	
        Until (1 -eq 0)
        $StorageParams.LUN = $LunToBePooled

		$count = Get-StoragePool -IsPrimordial:$false -ErrorAction Ignore | Measure-Object | Select-Object -expandProperty Count
		$defaultValue = "SQLVMStoragePool$count"
		Do {
			$value = Read-Host "Insert storage pool friendly name [$defaultValue]"
			if(-not $value) {
				$value = $defaultValue
			}
		} Until (-not [string]::isNullOrEmpty($value))
		$StorageParams.StoragePoolFriendlyName = $value

		$VirtualDisk = $true
		$Volume = $true
	}
	if($VirtualDisk) {
        $defaultValue = "VirtualDisk$((Get-VirtualDisk).Count + 1)"
		Do {
			$value = Read-Host "Insert virtual disk friendly name [$defaultValue]"
			if(-not $value) {
				$value = $defaultValue
			}
		} Until (-not [string]::isNullOrEmpty($value))
		$StorageParams.VirtualDiskFriendlyName = $value
		$defaultValue = 1
		Do {
			$value = Read-Host "Insert virtual disk workload type (1 for OLTP, 2 for DW or 3 for Generic) [$defaultValue]"
			if(-not $value) {
				$value = $defaultValue
			}
		} Until ($value -in ('1','2','3'))
		switch ($value) {
			"2" {$StorageParams.WorkloadType = 'DW'}
			"3" {$StorageParams.WorkloadType = 'Generic'}
			default {$StorageParams.WorkloadType = 'OLTP'}
		}
	
		$Volume = $true
	}
	if($Volume) {
		$availLetters = Get-AvailableDriveLetter
        if($usedLetter) {
            $defaultValue = $usedLetter
        }
        else {
		    $defaultValue = $availLetters | Select-Object -First 1
        }
		Do {
			$value = Read-Host "Insert new drive letter assigned to volume [$defaultValue]"
			if(-not $value) {
				$value = $defaultValue
			}
            elseif($value -notin $availLetters) {
                Write-Host "Drive letter already in use!"
            }
		} Until (($value -in $availLetters) -or ($value -eq $defaultValue) )
		$StorageParams.DriveLetter = $value
		$defaultValue = 'Data disk'
		Do {
			$value = Read-Host "Insert new label assigned to volume [$defaultValue]"
            if(-not $value) {
				$value = $defaultValue
			}
		} Until (-not [string]::isNullOrEmpty($value))
		$StorageParams.VolumeLabel = $value
		$defaultValue = '1'
		Do {
			$value = Read-Host "Choose file system for new volume (1 for NTFS, 2 for ReFS) [$defaultValue]"
			if(-not $value) {
				$value = $defaultValue
			}
		} Until ($value -in ('1','2'))
		if($value -eq '2') {
			$StorageParams.FileSystem = 'ReFS'
		}
		else {
			$StorageParams.FileSystem = 'NTFS'
		}
	}

	Return [PSObject]$storageParams
}

########################################################################
## SQL Server helper functions
########################################################################

function Start-SqlService {
    
    param (
        [Parameter(Mandatory=$true)]
        [Microsoft.SqlServer.Management.Smo.Wmi.Service]$SqlService, 
        [Microsoft.SqlServer.Management.Smo.Wmi.ServiceStartMode]$StartupType
    )

    if($StartupType) {
        $SqlService.StartMode = $StartupType
        $sqlService.Alter()
    }

    Write-Verbose -Message "Starting '$($sqlService.name)' ..."
    [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.WmiEnum') | Out-Null
    if ($SqlService.ServiceState -eq [Microsoft.SqlServer.Management.Smo.Wmi.ServiceState]::Stopped)
    {
        Start-Service -Name $SqlService.Name
        $SqlService.Refresh()
		while ($SqlService.ServiceState -ne [Microsoft.SqlServer.Management.Smo.Wmi.ServiceState]::Running)
		{
			$SqlService.Refresh()
		}
    }
}

function Stop-SqlService {

    param (
        [Parameter(Mandatory=$true)]
        [Microsoft.SqlServer.Management.Smo.Wmi.Service]$SqlService, 
        [Microsoft.SqlServer.Management.Smo.Wmi.ServiceStartMode]$StartupType
    )

    if($StartupType) {
        $SqlService.StartMode = $StartupType
        $sqlService.Alter()
    }

    Write-Verbose -Message "Stopping '$($SqlService.name)' ..."
    [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.WmiEnum") | Out-Null
    Stop-Service -Name $SqlService.Name -Force
    $SqlService.Refresh()
    while ($SqlService.ServiceState -ne [Microsoft.SqlServer.Management.Smo.Wmi.ServiceState]::Stopped)
    {
        $SqlService.Refresh()
    }
}

function Restart-SqlService {

    param (
        [Parameter(Mandatory=$true)]
        [Microsoft.SqlServer.Management.Smo.Wmi.Service]$SqlService
    )

    Write-Verbose -Message "Restarting '$($SqlService.name)' ..."
    [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.WmiEnum") | Out-Null
    Stop-SqlService -SqlService $sqlService
    Start-SqlService -SqlService $sqlService
}

function Convert-SqlServerInstanceName {

	param (
        [Parameter(Mandatory=$false)]
        [String]$SqlInstanceName='MSSQLSERVER'
    )

    $InstanceName = $env:COMPUTERNAME
	if($SqlInstanceName -ne 'MSSQLSERVER') {
		if($SqlInstanceName.IndexOf('$') -ne -1) {
			$InstanceName = "$env:COMPUTERNAME\$($SqlInstanceName.Split('$')[1])"
		} 
		$InstanceName = "$env:COMPUTERNAME\$SqlInstanceName"
    }
    $InstanceName

}

function Get-SQLService {

    # Return a single Microsoft.SqlServer.Management.Smo.Wmi.Service object related
    # to SqlInstanceName or ServiceName parameters, or a collection of Services if
    # -All parameter is present

    param (
        [Parameter(Mandatory=$False)]
        [String]$SqlInstanceName='MSSQLSERVER',

        [Parameter(Mandatory=$False)]
        [String]$ServiceName,

        [Parameter(Mandatory=$False)]
        [Switch]$All
    )
    
    [reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.SqlWmiManagement") | Out-Null

    $mc = new-object Microsoft.SQLServer.Management.SMO.WMI.ManagedComputer localhost

    if($All) {
        Return [Microsoft.SqlServer.Management.Smo.Wmi.ServiceCollection]$mc.Services
    }
    elseif ($ServiceName) {
        Return [Microsoft.SqlServer.Management.Smo.Wmi.Service]$mc.Services[$ServiceName]
    }
    else {
        if($SqlInstanceName -ne 'MSSQLSERVER') {
            Return [Microsoft.SqlServer.Management.Smo.Wmi.Service]$mc.Services["MSSQL`$$SqlInstanceName"]
        }
        else {
            Return [Microsoft.SqlServer.Management.Smo.Wmi.Service]$mc.Services[$SqlInstanceName]
        }
    }

}

function Get-SQLServer {

    param (
        [Parameter(Mandatory=$false)]
        [String]$SqlInstanceName='MSSQLSERVER'
    )

    [reflection.assembly]::LoadWithPartialName('Microsoft.SqlServer.Smo') | Out-Null

    $connStr = Convert-SqlServerInstanceName -SqlInstanceName $SqlInstanceName

    Return (new-object Microsoft.SqlServer.Management.Smo.Server $connStr)

}

function Get-SqlServiceSIDName {

	param (
        [Parameter(Mandatory=$true)]
        [string]$SqlInstanceName
	)

	if($SqlInstanceName -eq 'MSSQLSERVER') {
            Return "NT SERVICE\MSSQLSERVER"
        }
        else {
            Return "NT SERVICE\MSSQL`$$($SqlInstanceName)"
        }
}

function Add-SqlServiceSIDtoLocalPrivilege {

    param (
		[Parameter(Mandatory=$true)]
        [string]$SqlInstanceName,
		[Parameter(Mandatory=$true)]
        [string]$privilege
    )

	$serviceSid = Get-SqlServiceSIDName -SqlInstanceName $SqlInstanceName

    #Generating a temporary file to hold new configuration
    $configFile = New-Item -Path (Join-Path -Path $env:TEMP -ChildPath "$((New-Guid).Guid.Substring(0,8)).inf") -ItemType File

    $fileHeader = @"
[Unicode]
Unicode=yes
[Version]
signature="`$CHICAGO$"
Revision=1
[Privilege Rights]
"@

    $fileHeader | Out-File $configFile -Force

    #Generating a temporary file to hold secedit export
    $tempFile = New-Item -Path (Join-Path -Path $env:TEMP -ChildPath "$((New-Guid).Guid.Substring(0,8)).inf") -ItemType File

    #Export current local policy (user right assignment area)
    secedit /export /areas USER_RIGHTS /cfg $tempFile | Out-Null

    #Looking for privilege in exported file and write config file
    $tempFileContent = Get-Content $tempFile -Encoding Unicode

    $found = $false
    for($idx=0;$idx -lt $tempFileContent.GetUpperBound(0);$idx++) {
        if($tempFileContent[$idx].StartsWith($privilege)) {
            "$($tempFileContent[$idx]),$($serviceSid)" | Out-File $configFile -Append unicode -Force
            $found = $true
        }
    }
    if(-not $found) {
        "$($privilege) = $($serviceSid)" | Out-File $configFile -Append unicode -Force
    }

    #Import config
    secedit /configure /db secedit.sdb /cfg $configFile | Out-Null

    #Removing temp file
    $tempFile | Remove-Item -force
    $configFile | Remove-Item -force

}

function Set-SqlInstanceOptimization {
    
    param (
		[Parameter(Mandatory=$true)]
        [string]$SqlInstanceName,
        [bool]$EnableIFI,
        [bool]$EnableLockPagesInMemory,
        [string[]]$TraceFlag,
		[int]$MaxServerMemoryMB
	)

    if($enableIFI) {
        Add-SQLServiceSIDtoLocalPrivilege -SqlInstanceName $SqlInstanceName -privilege "SeManageVolumePrivilege"
    }

    if($enableLockPages) {
        Add-SQLServiceSIDtoLocalPrivilege -SqlInstanceName $SqlInstanceName -privilege "SeLockMemoryPrivilege"
    }

    if($TraceFlag) {
        Add-SqlStartupParameter -SqlInstanceName $SqlInstanceName -value $traceFlag
    }

	if($MaxServerMemoryMB) {
		Set-SqlMaxServerMemory -SqlInstanceName $SqlInstanceName -MaxServerMemoryMB $MaxServerMemoryMB
	}
}

function Get-DBPath {

    param (
        [Parameter(Mandatory=$true)]
        [string]$SqlInstanceName
	)

    If (!(Get-module SqlPs)) {
        Push-Location
        Import-Module SqlPs -DisableNameChecking
        Pop-Location
    }

    $sqlQry = @"
                select	db.name as [Database],
		                mf.name as [Logical file name],
		                mf.type_desc as [File type],
		                mf.physical_name as [File path] 
                from	sys.databases db inner join sys.master_files mf
                on		db.database_id = mf.database_id
                Order by db.database_id
"@
    
    Invoke-SQLCmd -ServerInstance (Convert-SqlServerInstanceName -SqlInstanceName $SqlInstanceName) -Database "Master" -Query $sqlQry

}

function New-SqlFolder {

    param (
		[Parameter(Mandatory=$true)]
        [string]$FolderPath,
		[Parameter(Mandatory=$true)]
        [string]$SqlInstanceName
    )

    Do {

        try {
            if(-not(Test-Path $FolderPath )) {
                $folder = New-Item $FolderPath -ItemType Directory
            }
            else {
                $folder = Get-Item $FolderPath
            }
        }
        catch {
            Write-Error 'Please insert a well-formed path'
        }
    } Until (Test-Path $FolderPath)

	$Username = Get-SqlServiceSIDName -SqlInstanceName $SqlInstanceName

    foreach ($subFolder in $folder) {
        $Path = $subFolder.FullName
        $Acl = (Get-Item $Path).GetAccessControl('Access')
        <#if($InstanceName -eq 'MSSQLSERVER') {
            $Username = "NT SERVICE\MSSQLSERVER"
        }
        else {
            $Username = "NT SERVICE\MSSQL`$$($InstanceName)"
        }#>
        $Ar = New-Object System.Security.AccessControl.FileSystemAccessRule($Username, 'FullControl', 'ContainerInherit,ObjectInherit', 'None', 'Allow')
        $Acl.SetAccessRule($Ar)
        Set-Acl -path $Path -AclObject $Acl
    }
}

function Invoke-DynSqlQry {

    param (
		[Parameter(Mandatory=$true)]
        [string]$DynSqlStmt,
		[Parameter(Mandatory=$true)]
        [string]$SqlInstanceName
    )

    #Checking for SQLPs module loaded
    If (!(Get-module SqlPs)) {
        Push-Location
        Import-Module SqlPs -DisableNameChecking
        Pop-Location
    }

    $InstanceName = Convert-SqlServerInstanceName -SqlInstanceName $SqlInstanceName
    $DynSqlOut = Invoke-SQLCmd -ServerInstance $InstanceName -Query $DynSqlStmt
    $DynSqlOut | ForEach-Object {Invoke-SqlCmd -ServerInstance $InstanceName -query $_.Column1}
}


function Set-UserDatabaseState {
    
    param (
        [ValidateSet('offline','online')]
        [string]$State = 'offline',
		[Parameter(Mandatory=$true)]
        [string]$SqlInstanceName
    )

    $sqlQryOffline = @"
    select	'ALTER DATABASE [' + db.name + '] SET OFFLINE WITH ROLLBACK IMMEDIATE;'
    from	sys.databases db 
    where	db.database_id > 4
		    and db.name <> 'distribution'
    Order by db.database_id
"@
    
    $sqlQryOnline = @"
    select	'ALTER DATABASE [' + db.name + '] SET ONLINE;'
    from	sys.databases db 
    where	db.database_id > 4
		    and db.name <> 'distribution'
    Order by db.database_id
"@

    if($state -eq 'offline')
    {
        $qry = $sqlQryOffline
    }
    else {
        $qry = $sqlQryOnline
    }

    Invoke-DynSqlQry -DynSqlStmt $qry -SqlInstanceName $SqlInstanceName
}

function Move-UserDatabase {
    param (
		[Parameter(Mandatory=$true)]
        [string] $SqlInstanceName,
		[Parameter(Mandatory=$true)]
        [string] $DataPath,
        [string] $LogPath = $dataPath
    )

    #Checking for SQLPs module loaded
    If (!(Get-module SqlPs)) {
        Push-Location
        Import-Module SqlPs -DisableNameChecking
        Pop-Location
    }

    #Prepare file move statement
    $getDBpathQry = @"
        select	db.name,
		        mf.physical_name,
		        case mf.type when 0 then '{0}' else '{1}' end +
		        RIGHT(mf.physical_name, CHARINDEX('\', REVERSE(mf.physical_name))) as DestPath
        from	sys.databases db inner join sys.master_files mf
        on		db.database_id = mf.database_id
        where	db.database_id > 4
		        and db.name <> 'distribution'
        Order by db.database_id
"@

    $dbFileList = Invoke-SQLCmd -ServerInstance (Convert-SqlServerInstanceName -SqlInstanceName $SqlInstanceName) -Query $getDBpathQry
    
    $moveStmt = @()
    foreach($dbFile in $dbFileList) {
        $moveStmt += "Move-Item -path '$($dbFile.physical_name)' -destination '$($dbFile.DestPath)' -force" -f $dataPath, $logPath
    } 

    #Put user database offline
    Set-UserDatabaseState -State offline -SqlInstanceName $SqlInstanceName
    
    #Alter Database move file
    $alterDBQry = @"
        select	'ALTER DATABASE [' + db.name + '] MODIFY FILE ' +
		        '(NAME = N''' + mf.name +''', ' +
		        'FILENAME = ''' + 
		        case mf.type when 0 then '{0}' else '{1}' end +
		        RIGHT(mf.physical_name, CHARINDEX('\', REVERSE(mf.physical_name)))  + ''');'
        from	sys.databases db inner join sys.master_files mf
        on		db.database_id = mf.database_id
        where	db.database_id > 4
		        and db.name <> 'distribution'
        Order by db.database_id
"@

	$qry = $alterDBQry -f $dataPath, $logPath

    Invoke-DynSqlQry -DynSqlStmt $qry -SqlInstanceName $SqlInstanceName

    #Phisically move db files
    $moveStmt | ForEach-Object {Invoke-Expression $_}

    #Put user database online
    Set-UserDatabaseState -state online -SqlInstanceName $SqlInstanceName
}

function Move-SystemDatabaseAndTrace {
    param (
		[Parameter(Mandatory=$true)]
        [string] $SqlInstanceName,
		[Parameter(Mandatory=$true)]
        [string] $DataPath,
        [string] $LogPath,
        [string] $TempDBDataPath,
        [string] $TempDBLogPath,
        [string] $ErrorLogPath
    )

    #Prepare file move statemets
    $getDBpathQry = @"
        select	db.name,
		        mf.physical_name,
		        case mf.type when 0 then '{0}' else '{1}' end +
		        RIGHT(mf.physical_name, CHARINDEX('\', REVERSE(mf.physical_name))) as DestPath
        from	sys.databases db inner join sys.master_files mf
        on		db.database_id = mf.database_id
        where	db.database_id <= 4
        Order by db.database_id
"@

    $dbFileList = Invoke-SQLCmd -ServerInstance (Convert-SqlServerInstanceName -SqlInstanceName $SqlInstanceName) -Query $getDBpathQry

    $moveStmt = @()
    foreach($dbFile in $dbFileList) {
        $moveStmt += "Move-Item -path '$($dbFile.physical_name)' -destination '$($dbFile.DestPath)' -force" -f $dataPath, $logPath, $tempDBDataPath, $tempDBLogPath
    } 

    #Alter Database move file
    $alterDBQry = @"
        select	'ALTER DATABASE [' + db.name + '] MODIFY FILE ' +
		        '(NAME = N''' + mf.name +''', ' +
		        'FILENAME = ''' + 
		        case 
			        when (db.name = 'tempdb' and mf.type = 0) then '{2}'
			        when (db.name = 'tempdb' and mf.type = 1) then '{3}'
			        when (db.name <> 'tempdb' and mf.type = 0) then '{0}'
			        when (db.name <> 'tempdb' and mf.type = 1) then '{1}'
			        else '{0}'
		        end +
		        RIGHT(mf.physical_name, CHARINDEX('\', REVERSE(mf.physical_name)))  + ''');'
        from	sys.databases db inner join sys.master_files mf
        on		db.database_id = mf.database_id
        where	db.database_id <= 4
		        and db.name <> 'master'
        Order by db.database_id
"@

	$qry = $alterDBQry -f $DataPath, $LogPath, $TempDBDataPath, $TempDBLogPath

    Invoke-DynSqlQry -DynSqlStmt $qry -SqlInstanceName $SqlInstanceName

    #Stop SQL Server
	$sqlSvc = Get-SQLService -SqlInstanceName $SqlInstanceName
	Stop-SqlService -SqlService $sqlSvc

    #Phisically move db files
    $moveStmt | ForEach-Object {Invoke-Expression $_}

    #Alter Startup Parameters for master and errorlog
    [string[]]$currParameters = ($sqlSvc.StartupParameters).Split(';')
    for($idx=0;$idx -le $currParameters.GetUpperBound(0);$idx++) {
        Switch -Wildcard ($currParameters[$idx]) {
            "-d*" {$currParameters[$idx] = "-d$($dataPath)\master.mdf"}
            "-l*" {$currParameters[$idx] = "-l$($logPath)\mastlog.ldf"}
            "-e*" {$currParameters[$idx] = "-e$($errorLogPath)\ERRORLOG"}
        }
    }
    
    $newParameters = $currParameters -join ';'
    $sqlSvc.StartupParameters = $newParameters
    $sqlSvc.Alter()
    $sqlSvc.Refresh()
    
    #Start SQL Server
	Start-SqlService -SqlService $sqlSvc
}

function Add-SqlStartupParameter {
    
    param (
		[Parameter(Mandatory=$true)]
        [string]$SqlInstanceName,
		[Parameter(Mandatory=$true)]
        [string[]]$value
    )

    $sqlSvc = Get-SQLService -SqlInstanceName $SqlInstanceName

    $Parameters = @()

    $sqlSvc = Get-SQLService -SqlInstanceName $SqlInstanceName
    [string[]]$currParameters = ($sqlSvc.StartupParameters).Split(';')
    $value | ForEach-Object { if($_ -notin $currParameters) { $Parameters += $_} }
        
    if($Parameters) {
        $Parameters | ForEach-Object { $currParameters += $_ }
    }
    $newParameters = $currParameters -join ';'

	$sqlSvc.StartupParameters = $newParameters
    $sqlSvc.Alter()
    $sqlSvc.Refresh()

	#Restart SQL Server
    Restart-SqlService -SqlService $sqlSvc
}

function Set-TempDB {
    
    param (
		[Parameter(Mandatory=$true)]
        [string]$SqlInstanceName,
		[Parameter(Mandatory=$true)]
        [int]$numOfDataFile,
		[int]$DataInitialSizeMB = 8,
		[int]$DataAutogrowMB = 64,
		[int]$LogInitialSizeMB = 8,
		[int]$LogAutogrowMB = 64
    )

	$alterTempDBQry = @"
		DECLARE @fileNumber int
		DECLARE @filePath nvarchar(256)
		DECLARE @table table (Column1 nvarchar(4000)) 

        INSERT INTO @table
			SELECT	'ALTER DATABASE [tempdb] 
					MODIFY FILE ( 
						NAME = N''' + name + ''', 
						SIZE = {1}MB , 
						FILEGROWTH = {2}MB 
					)'
			FROM sys.master_files
			WHERE	database_id = DB_ID('TempDB') 
			AND type = 0

		SELECT @filePath = LEFT(a.physical_name, LEN(a.physical_name) - CHARINDEX('\', REVERSE(a.physical_name)))
		FROM (
			SELECT	TOP 1 physical_name
			FROM	sys.master_files
			WHERE	database_id = DB_ID('TempDB') 
					AND type = 0
		) a

        SELECT	@fileNumber = count(*) 
		FROM	sys.master_files 
		WHERE	database_id = DB_ID('TempDB') 
		AND type = 0;

		WHILE @fileNumber < {0}
		BEGIN
			INSERT INTO @table VALUES (
				   'ALTER DATABASE [tempdb] 
		 			ADD FILE ( NAME = N''tempdev' + CAST((@fileNumber+1) as NVARCHAR) + ''', 
					FILENAME = N''' + @filePath + '\tempdb_mssql_' + CAST((@fileNumber+1) as NVARCHAR) + '.ndf'', 
					SIZE = {1}MB , FILEGROWTH = {2}MB );'
					);

			SELECT @fileNumber = @fileNumber + 1
		END

		INSERT INTO @table VALUES (
				'ALTER DATABASE [tempdb] 
				 MODIFY FILE ( 
					NAME = N''templog'', 
					SIZE = {3}MB , 
					FILEGROWTH = {4}MB 
				 )')

		SELECT * FROM @table
"@
    
	$qry = $alterTempDBQry -f $numOfDataFile, $DataInitialSizeMB, $DataAutogrowMB, $LogInitialSizeMB, $LogAutogrowMB

	Invoke-DynSqlQry -DynSqlStmt $qry -SqlInstanceName $SqlInstanceName | Format-Table

}

function Show-SqlServiceMenuAccount {

    param (
        [Parameter(Mandatory=$true)]
        [Microsoft.SqlServer.Management.Smo.Wmi.Service]$SqlService,

        [Parameter(Mandatory=$true)]
        [PSCredential]$AccountCreds
    )

    [reflection.assembly]::LoadWithPartialName('Microsoft.SqlServer.SqlWmiManagement') | Out-Null

    $SqlService.SetServiceAccount($AccountCreds.UserName, $AccountCreds.GetNetworkCredential().Password)
    $SqlService.Alter()
    $SqlService.Refresh() 
}

function Set-SQLServerDefaultPath {

	param(
		[Parameter(Mandatory=$true)]
        [string]$SqlInstanceName,
		[string]$DataPath,
		[string]$LogPath,
		[string]$BackupPath
	)

	$srv = Get-SQLServer -SqlInstanceName $SqlInstanceName
	$changed = $false

	if($DataPath) {
		$srv.DefaultFile = $dataPath
		$changed = $true
	}
	if($logPath) {
		$srv.DefaultLog = $logPath
		$changed = $true
	}
	if($BackupPath) {
		$srv.BackupDirectory = $BackupPath
		$changed = $true
	}

    if($changed) {
		$srv.Alter()
		Restart-SqlService -SqlService (Get-SQLService -SqlInstanceName $SqlInstanceName)
	}
    
}

function Set-SqlMaxServerMemory {
	
	param (
        [Parameter(Mandatory=$true)]
        [string]$SqlInstanceName,

        [Parameter(Mandatory=$true)]
        [int]$MaxServerMemoryMB
    )

	$srv = Get-SQLServer -SqlInstanceName $SqlInstanceName

	$srv.Configuration.MaxServerMemory.ConfigValue = $MaxServerMemoryMB
	$srv.Alter()
	$srv.Refresh()

}

function Get-VolumeUsedBySqlServer {

	$qryGetDBVolume = @"
		WITH cte AS (
		SELECT LEFT(physical_name, CHARINDEX(Physical_name, ':') + 1) as [DriveLetter]
		FROM sys.master_files 
		)

		SELECT DriveLetter
		FROM cte
		GROUP BY DriveLetter
		ORDER BY DriveLetter
"@

	$sqlSvcs = Get-SQLService -All | Where-Object Type -eq 'SqlServer'

	$result = [ordered]@{}

	forEach($sqlSvc in $sqlSvcs) {

		$srv = Get-SQLServer -SqlInstanceName $sqlSvc.Name
		#Default backup location
		$result.Add("$($sqlSvc.Name)_backup",($srv.BackupDirectory).Substring(0, ($srv.BackupDirectory).IndexOf(':')))
		#Default data path
		$result.Add("$($sqlSvc.Name)_data",($srv.DefaultFile).Substring(0, ($srv.DefaultFile).IndexOf(':')))
		#Default log path
		$result.Add("$($sqlSvc.Name)_log",($srv.DefaultLog).Substring(0, ($srv.DefaultLog).IndexOf(':')))
		#Existing database
		$dbVolume = Invoke-SQLCmd -ServerInstance (Convert-SqlServerInstanceName -SqlInstanceName $sqlSvc.Name) `
								  -Database "Master" `
								  -Query $qryGetDBVolume

        for($idx=0; $idx -lt $dbVolume.Count; $idx++) {
		    $result.Add("$($sqlSvc.Name)_db_$($idx)",$dbVolume[$idx].DriveLetter)
        }
	}

	$result
}

function Get-PathUsedBySqlServer {

    [CmdletBinding()]
    [OutputType([string[]])]
    param (
        [switch]$OnlyRootFolder = $false
    )

	$QryGetDBPath = @"
		WITH cte AS (
            SELECT LEFT(physical_name, LEN(physical_name) - CHARINDEX('\', REVERSE(physical_name))) as Path
            FROM sys.master_files 
		)

		SELECT Path
		FROM cte
		GROUP BY Path
		ORDER BY Path
"@

	$SqlSvcs = Get-SQLService -All | Where-Object Type -eq 'SqlServer'

	$Results = @()

	forEach($sqlSvc in $sqlSvcs) {

		$Srv = Get-SQLServer -SqlInstanceName $sqlSvc.Name
		#Default backup location
		$Results += ($srv.BackupDirectory).Trim('\')
		#Default data path
		$Results += ($srv.DefaultFile).Trim('\')
		#Default log path
        $Results += ($srv.DefaultLog).Trim('\')
        #Existing database
        
        $Params = @{
            "ServerInstance" = "$(Convert-SqlServerInstanceName -SqlInstanceName $SqlSvc.Name)";
            "Database" = "master";
            "Query" = $QryGetDBPath;
        }

		Invoke-SQLCmd @Params | ForEach-Object { $Results += $_.Path }
	}

    if($OnlyRootFolder) {
        $RootOnlyResults = @()
        foreach ($Result in $Results) {
            $RootOnlyResults += "{0}\{1}" -f $Result.Split("\")
        }
        $RootOnlyResults | Select-Object -Unique
    }
    else {
        $Results | Select-Object -Unique
    }
	
}

function Move-Folder {

    [CmdletBinding()]

    param(
        [string[]]$SourcePath,
        [string]$TargetPath,
        [switch]$isTemporarySource
    )

    if(-not(Test-Path $TargetPath)) {
        New-Item $TargetPath -ItemType Directory | Out-Null
    }

    #Check space required
    foreach($Path in $SourcePath) {
        if(Test-Path $Path) {
            [float]$SpaceRequired += Get-ChildItem $Path -Recurse | Measure-Object -Sum Length | Select-Object -ExpandProperty Sum
        }
    }
    [float]$SpaceAvailable = (Get-Volume -DriveLetter ($SourcePath.Substring(0,1))).SizeRemaining

    if($SpaceRequired -gt $SpaceAvailable) {
        Write-Error "Not enough space on target path. Please try with another location." -ErrorAction Stop
    }

    foreach($Path in $SourcePath) {
        if(Test-Path $Path) {
            #Get ACL on source
            $SourceAcl = Get-Acl $Path 
            #Move files
            Try {
                #if source is a temporary folder, skip its name while composing target path
                if($IsTemporarySource) {
                    $Destination = "$TargetPath\$($Path.Substring($Path.IndexOf("\",3)))"
                }
                else {
                    $Destination = "$TargetPath\$($Path.Substring(3))"
                }
                Copy-Item -Path $Path -Destination $Destination -Force -Recurse

                #Set ACL on target
                $SourceAcl | Set-Acl -path $Destination
            }
            Catch {
                Write-Error "Error while copying files." -ErrorAction Stop
            }
            Remove-Item $Path -Recurse -Force -Confirm:$false
        }
    }

}

########################################################################
## Storage helper functions
########################################################################

function Get-PhysicalDiskExt {
    [CmdletBinding(DefaultParameterSetName='Disk')]
    [OutputType([psobject[]])]
    param (
        [parameter(Mandatory=$false, ParameterSetName='Disk')]
        [ValidateNotNullOrEmpty()]
        [int]
        $DiskNumber,

        [parameter(Mandatory=$false, ParameterSetName='Pipeline', ValueFromPipeline)]
        [CimInstance]
        $PipedObj
    )

    $OutObj = @()

    if($PsCmdLet.ParameterSetName -eq 'Pipeline') {
        $Disks = $PipedObj | Get-PhysicalDisk
    }
    else {
        if($DiskNumber)  {
            $Disks = Get-PhysicalDisk | Where-Object DeviceId -eq $DiskNumber
        }
        else {
            $Disks = Get-PhysicalDisk
        }
    }

    foreach($Disk in $Disks) {
        $WmiDiskDrive = Get-WmiObject -Class Win32_DiskDrive | Where-Object Index -eq $Disk.DeviceId

        $Properties = [ordered]@{
            DeviceId = $Disk.DeviceId
            ScsiLun =$WmiDiskDrive.SCSILogicalUnit
            PhysicalLocation = $Disk.PhysicalLocation
            Size = [math]::Round($Disk.Size / 1GB, 2)
            CanPool = $Disk.CanPool
            CannotPoolReason = $Disk.CannotPoolReason
        }

        $OutObj += New-Object -Property $Properties -TypeName psobject

    }

    $OutObj

}

function Get-AvailableDriveLetter {

    $usedLetters = Get-Volume | Select-Object -ExpandProperty DriveLetter | Sort-Object
    for ([byte]$c = [char]'C'; $c -le [char]'Z'; $c++)  
    {  
        if([char]$c -notin $usedLetters) {
            [string[]]$driveLetters += [char]$c
        }
    }  
    Return $driveLetters
}

function Get-SqlServerVolumeUsage {
	param (
		[Parameter(Mandatory=$true)]
		[string]$DriveLetter
	)

	$volumeUsed = Get-VolumeUsedBySqlServer

	if($volumeUsed) {
		$result = @()
		foreach ($key in $volumeUsed.Keys) {
			if(($volumeUsed[$key]).ToString() -eq $DriveLetter) {
				$result += $key.ToString()
			}
		}
		Return $result
	}
	Return
}

function Get-VolumeRemovalConfirm {

	# Return true if volume is not used by SQL Server or if user decided to go on with volume removal
	# Return false if user aborts activity or if volume is hosting live databases

	param (
		[Parameter(Mandatory=$true)]
		[string]$DriveLetter
	)

	$usedBy = Get-SqlServerVolumeUsage -DriveLetter $DriveLetter

	if($usedBy) {
	
		$backup = @()
		$data = @()
		$log = @()
		$existingDB = @()

		for($idx=0;$idx -le $usedBy.GetUpperBound(0);$idx++) {
			switch -Wildcard ($usedBy[$idx]) {
				"*_backup" {$backup += ($usedBy[$idx]).Split('_')[0]}
				"*_data" {$data += ($usedBy[$idx]).Split('_')[0]}
				"*_log" {$log += ($usedBy[$idx]).Split('_')[0]}
				"*_db*" {$existingDB += ($usedBy[$idx]).Split('_')[0]}
			}
		}
		Write-Host "Warning: the operation you chose is trying to remove volume $($DriveLetter), which is currently used as:" -ForegroundColor Yellow
		$alsoForDB = $false
		if($existingDB) {
			Write-host "`tStorage for existing databases by instance $($log -join '; ')"
			$alsoForDB = $true
		}
		if($data) {
			Write-host "`tDefault database data file path for instance $($data -join '; ')"
		}
		if($log) {
			Write-host "`tDefault database log file path for instance $($log -join '; ')"
		}
		if($backup) {
			Write-host "`tDefault backup location for instance $($backup -join '; ')"
		}
		if($alsoForDB) {
			Write-Host "`nOperation is aborted to preserve your data." -ForegroundColor Red
			Write-Host "Use appropriate menus to move listed instances databases to an alternate location, and then try again. `n" -ForegroundColor Red
			Pause
			Return $false
		}
		Write-Host "`nRemove a volume defined in SQL Server configuration paramters may lead to unwanted behaviour." -ForegroundColor Yellow
		Write-Host "Use appropriate menu to alter reported instances configuration parameters when done.`n" -ForegroundColor Yellow
		Write-Host "Other data may also be contained on this disk, proceed at your own risk.`n" -ForegroundColor Yellow
		Write-Host "PAY ATTENTION! This operation may destroy your data!" -ForegroundColor Red
		$action = Get-YN -Question "Do you want to continue?" `
							-YesText "Remove volume with possible data lost" `
							-NoText "Go back to previous menu" `
							-Default 'N'
		if($action) {
			Return $true
		}
		Return $false
	}
	Return $true
}

function Format-VolumeForSql {
	param (
		[Parameter(
			Position=0, 
			Mandatory=$true, 
			ValueFromPipeline=$true,
			ValueFromPipelineByPropertyName=$true)
		]
		[string]$DriveLetter,
		[string]$NewDriveLetter,
		[string]$VolumeLabel = 'Data disk',
		[ValidateSet('NTFS','ReFS')]
		[string]$FileSystem,
		[int]$AllocationUnitSizeKB = 64,
		[switch]$Force
	)

	if(-not $Force) {
		$confirm = Get-VolumeRemovalConfirm -DriveLetter $DriveLetter
		if(-not $confirm) {
			Return $false
		}
	}

	if(($NewDriveLetter) -and ($NewDriveLetter -ne $DriveLetter)) {
		Get-Volume -DriveLetter $DriveLetter | Get-Partition | Set-Partition -NewDriveLetter $NewDriveLetter
	}
    else {
        $NewDriveLetter = $DriveLetter
    }
	
	Format-Volume -DriveLetter $NewDriveLetter `
				  -FileSystem $FileSystem `
				  -NewFileSystemLabel $VolumeLabel `
				  -AllocationUnitSize ([int]$AllocationUnitSizeKB*1024) `
				  -Force `
				  -Confirm:$Force | Out-Null
	
	Return $true
}

function New-VolumeForSql {
	param (
		[Parameter(
			Position=0, 
			Mandatory=$true, 
			ValueFromPipeline=$true,
			ValueFromPipelineByPropertyName=$true)
		]
		[cimInstance]$Disk,
		[string]$DriveLetter,
		[string]$VolumeLabel = 'Data disk',
		[ValidateSet('NTFS','ReFS')]
		[string]$FileSystem = 'NTFS',
		[int]$AllocationUnitSizeKB = 64
	)

	if($Disk.PartitionStyle -eq 'RAW') {
		$Disk | Initialize-Disk -PartitionStyle GPT
	}

	if($DriveLetter) {
		$Disk | New-Partition -UseMaximumSize -DriveLetter $DriveLetter | Out-Null
        Format-VolumeForSql -DriveLetter $DriveLetter `
                            -Force `
							-VolumeLabel $VolumeLabel `
							-FileSystem $FileSystem `
							-AllocationUnitSizeKB $AllocationUnitSizeKB
}
	else {
		$Disk | New-Partition -UseMaximumSize -AssignDriveLetter | Out-Null
        Format-VolumeForSql -DriveLetter ($Disk | Get-Partition).DriveLetter `
                            -Force `
							-VolumeLabel $VolumeLabel `
						    -FileSystem $FileSystem `
							-AllocationUnitSizeKB $AllocationUnitSizeKB
	}
	
}

function New-VirtualDiskForSql {
	param (
		[Parameter(Mandatory=$true)]
		[string]$FriendlyName,
		[Parameter(Mandatory=$true)]
		[ciminstance]$StoragePool,
		[ValidateSet('OLTP','DW','Generic')]
		[string]$WorkLoadType = 'OLTP',
		[string]$DriveLetter,
		[string]$VolumeLabel = 'Data disk',
		[ValidateSet('NTFS','ReFS')]
		[string]$FileSystem = 'NTFS'
	)

    
	$numberOfCols = $StoragePool | Get-PhysicalDisk | Measure-Object | Select-Object -ExpandProperty Count

	switch ($WorkLoadType) {
		"Generic" {
                    $interleaveKB='256'
                    $AllocationUnitSizeKB='4'
                  }
		"DW"      { 
                    $interleaveKB='256'
                    $AllocationUnitSizeKB='64'
                  }
		default   { 
                    $interleaveKB='64'
                    $AllocationUnitSizeKB='64'
                  }
	}

	$Vdisk = New-VirtualDisk -FriendlyName $FriendlyName `
				        -StoragePoolUniqueId $StoragePool.UniqueId `
					    -NumberOfColumns $numberOfCols `
					    -Interleave $([int]$interleaveKB*1024) `
					    -ResiliencySettingName Simple `
					    -UseMaximumSize

	Initialize-Disk -VirtualDisk $Vdisk -ErrorAction Ignore | Out-Null
	$disk = $Vdisk| Get-Disk 
	New-VolumeForSql -Disk $disk `
					 -DriveLetter $DriveLetter `
					 -VolumeLabel $VolumeLabel `
					 -FileSystem $FileSystem `
				     -AllocationUnitSizeKB $AllocationUnitSizeKB
}

function New-StoragePoolForSql {
	param (
		[Parameter(Mandatory=$true)]
		[string]$StoragePoolFriendlyName,
		[string[]]$LUN,
		[string]$VirtualDiskFriendlyName = "$($FriendlyName)_VirtualDisk",
		[ValidateSet('OLTP','DW','Generic')]
		[string]$WorkLoadType = 'OLTP',
		[string]$DriveLetter,
		[string]$VolumeLabel = 'Data disk',
		[ValidateSet('NTFS','ReFS')]
		[string]$FileSystem = 'NTFS'
	)

    $storSubSys = Get-StorageSubSystem
    $DiskInfo = Get-PhysicalDiskExt | Where-Object ScsiLun -in $LUN
	$diskToPool = Get-PhysicalDisk -CanPool $true | Where-Object DeviceId -in $DiskInfo.DeviceId

	$StoragePool = New-StoragePool -StorageSubSystemUniqueId $storSubSys.UniqueId `
					    -FriendlyName $StoragePoolFriendlyName `
					    -PhysicalDisks $diskToPool

	New-VirtualDiskForSql -StoragePool $StoragePool `
						  -FriendlyName $VirtualDiskFriendlyName `
						  -DriveLetter $DriveLetter `
						  -VolumeLabel $VolumeLabel `
						  -FileSystem $FileSystem `
						  -WorkLoadType $WorkLoadType
}

Function Remove-EveryVolume {
    [CmdletBinding()]
    param (
		[Parameter(
			Position=0, 
			Mandatory=$true, 
			ValueFromPipeline=$true,
			ValueFromPipelineByPropertyName=$true)
		]
		[cimInstance]$Disk,
		[switch]$Force
	)

	if(-not $Force) {
		$DriveLetters = $Disk | Get-Partition | Select-Object -ExpandProperty DriveLetter

		foreach($driveLetter in $driveLetters) {
			$confirm = Get-VolumeRemovalConfirm -DriveLetter $driveLetter
			if(-not $confirm) {
				Return $false
			}
		}
	}
	$Disk | Clear-Disk -RemoveData -Confirm:$Force
	Return $true
}

Function Clear-StoragePool {
	param (
        [Parameter(
            Mandatory=$true,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)
        ]
		[ciminstance]$StoragePool,
		[switch]$Force
	)

    $vDisks = $StoragePool | Get-VirtualDisk
    $Cleared = $true
	foreach ($vDisk in $vDisks) {	
		$vDiskRemoved = Clear-VirtualDisk -VirtualDisk $vDisk -Force:$Force
		if(-not $vDiskRemoved) { 
			$Cleared = $false
		}
	}
    $Cleared
}

Function Clear-VirtualDisk {
	param (
		[Parameter(
			Position=0, 
			Mandatory=$true, 
			ValueFromPipeline=$true,
			ValueFromPipelineByPropertyName=$true)
		]
		[cimInstance]$VirtualDisk,
		[switch]$Force
	)

	if(-not $Force) { 
			$disk = $VirtualDisk | Get-Disk 
			$volRemoved = Remove-EveryVolume -Disk $disk
			if(-not $volRemoved)
			{
				Return $false
			}
		}
	Remove-VirtualDisk -InputObject $VirtualDisk -Confirm:$false
	Return $true
}

function Clear-SingleDisk {
	param (
		[Parameter(
			Position=0, 
			Mandatory=$true, 
			ValueFromPipeline=$true,
			ValueFromPipelineByPropertyName=$true)
		]
		[cimInstance]$Disk,
		[switch]$Force
	)

	$volRemoved = Remove-EveryVolume -Disk ($Disk | Get-Disk) -Force:$Force
    $volRemoved
}

function New-SingleDiskForSql {
	param (
		[Parameter(
			Position=0, 
			Mandatory=$true, 
			ValueFromPipeline=$true,
			ValueFromPipelineByPropertyName=$true)
		]
		[cimInstance]$Disk,
		[switch]$Force,
		[string]$DriveLetter,
		[string]$VolumeLabel = 'Data disk',
		[ValidateSet('NTFS','ReFS')]
		[string]$FileSystem = 'NTFS'
	)

	$cleared = Clear-SingleDisk -Disk $Disk -Force:$Force
	if($cleared) {
		New-VolumeForSql -Disk $disk `
					-DriveLetter $DriveLetter `
					-VolumeLabel $VolumeLabel `
					-FileSystem $FileSystem
		Return $true
	}
	Return $false
}

function Get-PoolableDiskSize {

    param (
        [switch]$OnlyEmpty
    )

    $pooledDisks = @()
    $storagePoolList = Get-StoragePool -IsPrimordial:$false -ErrorAction Ignore
    foreach($storagePool in $storagePoolList) {
        $diskData = $storagePool | Get-PhysicalDisk | Select-Object DeviceId
        $diskData | ForEach-Object {$pooledDisks += $_.DeviceId}
    }

	$RetVal = @()
    $remainingDisks = Get-PhysicalDiskExt | Where-Object {$_.DeviceId -notin $pooledDisks -and $_.DeviceId -ge 2} | Sort-Object ScsiLun
	
	for($idx=0; $idx -lt ($remainingDisks | Measure-Object | Select-Object -ExpandProperty Count); $idx++) {
		if(-not $OnlyEmpty) {
			$RetVal += $remainingDisks[$idx] | Select-Object @{Label = "Size"; Expression = {"$([math]::Round($_.Size / 1GB,2))"}}
		}
		elseif(($remainingDisks[$idx] | Get-Disk | Get-Partition).Count -eq 0) {
			$RetVal += $remainingDisks[$idx] | Select-Object @{Label = "Size"; Expression = {"$([math]::Round($_.Size / 1GB,2))"}}
		}
	}
	Return $retVal | Select-Object -ExpandProperty Size | Sort-Object
}

function Get-PoolableDiskInfo {

    param (
        [switch]$OnlyEmpty
    )

    $pooledDisks = @()
    $storagePoolList = Get-StoragePool -IsPrimordial:$false -ErrorAction Ignore
    foreach($storagePool in $storagePoolList) {
        $diskData = $storagePool | Get-PhysicalDisk | Select-Object DeviceId
        $diskData | ForEach-Object {$pooledDisks += $_.DeviceId}
    }

	$RetVal = @()
    $remainingDisks = Get-PhysicalDiskExt | Where-Object {$_.DeviceId -notin $pooledDisks -and $_.DeviceId -ge 2} | Sort-Object ScsiLun
	
	for($idx=0; $idx -lt ($remainingDisks | Measure-Object | Select-Object -ExpandProperty Count); $idx++) {
		if(-not $OnlyEmpty) {
			$RetVal += $remainingDisks[$idx]
		}
		elseif(-not (Get-PhysicalDisk | Where-Object DeviceId -eq $remainingDisks[$idx].DeviceId | Test-StorageVolumeDefined)) {
			$RetVal += $remainingDisks[$idx]
		}
	}
	$retVal
}

########################################################################
## Interactive functions
########################################################################

function Show-SqlServiceMenu {

    param (
        [Parameter(Mandatory=$True)]
        [Microsoft.SqlServer.Management.Smo.Wmi.Service]$SqlService
    )

    [reflection.assembly]::LoadWithPartialName('Microsoft.SqlServer.SqlWmiManagement') | Out-Null

    $menuItems = [ordered]@{
    "1" = "Change service account and restart service";
    "2" = "Stop and disable service";
    "3" = "Enable automatic startup and start service";
    "Q" = "Back to previous menu";
    }

    Do {
        Clear-Host
        Show-Header -Title "Manage service $($SqlService.Name)"
        Write-Host "Service name: `t`t$($SqlService.Name) - $($SqlService.DisplayName)"
        Write-Host "Service status: `t$($SqlService.ServiceState)"
        Write-Host "Start mode: `t`t$($SqlService.StartMode)"
        Write-Host "Service account: `t$($SqlService.ServiceAccount)"
        Show-Menu -Title "`nEdit service properties:" -MenuItem $menuItems
        $action = Get-UserInput -AllowedInput $menuItems -Default "Q" -ExitChar "Q"

        Switch($action) {
            "1" {
                    
                    $askForCredential = $true

                    if($global:svcAcctn) {
                        $askForCredential = $false
                        $action = Get-YN -Question "Would you like to reuse previously inserted credential ($($global:svcAcctn.UserName))?" `
                                        -YesText "Reuse same credential" `
                                        -NoText "Prompt for new credential"
                        if(-not $action) {
                            $askForCredential = $true
                        }
                    }

                    if($askForCredential) {
                        $global:svcAcctn = Get-Credential -Message "Insert Service Account credential (DOMAIN\USERNAME)"
                        #https://gallery.technet.microsoft.com/scriptcenter/Test-Credential-dda902c6
                    }
                    Show-SqlServiceMenuAccount -SqlService $sqlService -AccountCreds $global:svcAcctn
                    Start-Sleep 2
                }
            "2" { 
                    Write-Host "Stopping service $($sqlService.Name)..."
                    Stop-SqlService -SqlService $sqlService -StartupType Disabled
                    Write-Host "Service stopped"
                    Start-Sleep 2
    
                }
            "3" { 
                    Write-Host "Starting service $($sqlService.name)..."
                    Start-SqlService -SqlService $sqlService -StartupType Auto
                    Write-Host "Service started"
                    Start-Sleep 2
                }
            "Q" {Return}
        }
    } While (0 -eq 0)
}

function Show-SqlServiceEditMenu {
    
    #[reflection.assembly]::LoadWithPartialName(“Microsoft.SqlServer.SqlWmiManagement”) | Out-Null

    Do {
        Clear-Host                

        Show-Header -Title "Manage SQL Server services"
        Write-Host "SQL Related Services available on this server:" -ForegroundColor Yellow
        $global:idx = 1
        $SqlSvcs = Get-SQLService -All | Select-Object @{label = '#'; Expression = {$global:idx; $global:idx++;}}, Name, DisplayName, ServiceState, StartMode, ServiceAccount
        $SqlSvcs | format-table

        $menuItems = [ordered]@{
        "1..$($sqlSvcs.GetUpperBound(0)+1)" = "Modify selected service";
        "C" = "Continue with next steps";
        "Q" = "Go back to previous menu";
        }

        Show-Menu -Title "Edit SQL Server services:" -MenuItem $menuItems
        $action = Get-UserInput -AllowedInput $menuItems -Default "C" -ExitChar "C"

        Switch($action) {
            "Q" {Return}
            "C" {Show-SqlInstanceEditMenu}
            #default {modify-SQLService($mc.Services[$sqlSvcs[$action-1].Name])}
            default {Show-SqlServiceMenu(Get-SQLService -ServiceName $sqlSvcs[$action-1].Name)}
        }
    } While (1 -eq 1)
    
}

function Show-PathAndDBMenu {

    param (
        [Parameter(Mandatory=$True)]
        [string]$SqlInstanceName
    )

    Write-Host "Current databases path:"
    $DBPath = Get-DBPath -SqlInstanceName $SqlInstanceName
    $DBPath | Format-Table

    Write-Host "Available volumes:"
    $volumeList = Get-Volume | Where-Object {$_.DriveType -eq 'Fixed'} | Select-Object DriveLetter, `
                                                                     FileSystemLabel, `
                                                                     @{Label="Size"; Expression = {[math]::Round(($_.Size/1GB),2)}}, `
                                                                     @{Label="SizeRemaining"; Expression = {[math]::Round(($_.SizeRemaining/1GB), 2)}}                                                      
    $volumeList | Format-Table
    
    $dataVolume = $volumeList | Where-Object {$_.FileSystemLabel -eq 'SQLData'} | Select-Object DriveLetter -ErrorAction Ignore
    if($dataVolume) {
        $proposedDataPath = "$($dataVolume.DriveLetter):\SQLData"
    }
    
    $logVolume = $volumeList | Where-Object {$_.FileSystemLabel -eq 'SQLLog'} | Select-Object DriveLetter -ErrorAction Ignore
    if($logVolume) {
        $proposedLogPath = "$($logVolume.DriveLetter):\SQLLog"
    }
    
    if($proposedDataPath) {            
        $dataPath = Read-Host -Prompt "Please specify default path for database data files [$proposedDataPath]"
    }
    else {
        $dataPath = Read-Host -Prompt "Please specify default path for database data files"
    }

    if(-not $dataPath) {
        $dataPath = $proposedDataPath
    }
    New-SqlFolder -FolderPath $dataPath -SqlInstanceName $SqlInstanceName

    $tempdbPath = Read-Host -Prompt "Please specify a path for TempDB data files [$dataPath]"
    if(-not $tempdbPath) {
        $tempdbPath = $dataPath
    }
    New-SqlFolder -FolderPath $tempDBPath -SqlInstanceName $SqlInstanceName
    
    if($proposedLogPath) {
        $logPath = Read-Host -Prompt "Please specify a path for database log files [$proposedLogPath]"
    }
    else {
        $logPath = Read-Host -Prompt "Please specify a path for database log files [$dataPath]"  
    }
    if(-not $logPath) {
        $logPath = $dataPath
    }
    New-SqlFolder -FolderPath $logPath -SqlInstanceName $SqlInstanceName
    
    $tempDBLogPath = Read-Host -Prompt "Please specify a path for TempDB log files [$logPath]"
    if(-not $tempDBLogPath) {
        $tempDBLogPath = $logPath
    }
    New-SqlFolder -FolderPath $tempDBLogPath -SqlInstanceName $SqlInstanceName
    
    $proposedErrorPath = "$($logPath.Split("\")[0])\SQLErrorLog"
    $errorLogPath = Read-Host -Prompt "Please specify a path for instance log and tracec files [$proposedErrorPath]"
    if(-not $errorLogPath) {
        $errorLogPath = $proposedErrorPath
    }
    New-SqlFolder -FolderPath $errorLogPath -SqlInstanceName $SqlInstanceName

    $proposedBackupPath = "$($logPath.Split("\")[0])\SQLBackup"
    $backupPath = Read-Host -Prompt "Please specify a path for instance backups [$proposedBackupPath]"
    if(-not $backupPath) {
        $backupPath = $proposedBackupPath
    }
    New-SqlFolder -FolderPath $backupPath -SqlInstanceName $SqlInstanceName

	Set-SQLServerDefaultPath -SqlInstanceName $SqlInstanceName `
							   -DataPath $dataPath `
							   -LogPath $logPath `
							   -BackupPath $backupPath

    $action = Get-YN -Question "Move existing databases to specified path?"

    if($action) {

        #Move User DBs
        Move-UserDatabase -SqlInstanceName $SqlInstanceName `
                          -DataPath $dataPath `
                          -LogPath $logPath

        #Move system DBs and errorlog
        Move-SystemDatabaseAndTrace -SqlInstanceName $SqlInstanceName `
                                    -DataPath $dataPath `
                                    -LogPath $logPath `
                                    -TempDBDataPath $tempDBDataPath `
                                    -TempDBLogPath $tempDBLogPath `
                                    -ErrorLogPath $errorLogPath

    }
    #$srv.Databases[1] | select *
    
}

function Show-TempDBMenu {

    param (
        [Parameter(Mandatory=$True)]
        [string]$SqlInstanceName
    )

    $proposedFileNumber = Get-WmiObject -class Win32_processor | Select-Object -expandProperty NumberOfLogicalProcessors
        
    $numOfDataFile = Get-NumericInput -TextToPrompt "Insert total number of data files" -Default $proposedFileNumber
    $DataInitialSizeMB = Get-NumericInput -TextToPrompt "Insert inital file size in MB for data files" -Default 8
	$DataAutogrowMB = Get-NumericInput -TextToPrompt "Insert file autogrowth in MB for data files" -Default 64
	$LogInitialSizeMB = Get-NumericInput -TextToPrompt "Insert inital file size in MB for t-log file" -Default 8
    $LogAutogrowMB = Get-NumericInput -TextToPrompt "Insert file autogrowth in MB for t-log file" -Default 64

    Write-Host "New TempDB configuration:"
    Write-Host "`t$numOfDataFile Data files with:"
    Write-Host "`t`tInitial file size $DataInitialSizeMB MB"
    Write-Host "`t`tAutogrowth $DataAutogrowMB MB"
    Write-Host "`t1 t-log file with:"
    Write-Host "`t`tInitial file size $LogInitialSizeMB MB"
    Write-Host "`t`tAutogrowth $LogAutogrowMB MB"

    $confirm = Get-YN -Question "Confirm changes?"
    if($confirm) {
        Write-Host "`nApplying configuration changes to TempDB..."
        Set-TempDB -SqlInstanceName $SqlInstanceName `
                     -NumOfDataFile $numOfDataFile `
                     -DataInitialSizeMB $DataInitialSizeMB `
                     -DataAutogrowMB $DataAutogrowMB `
                     -LogInitialSizeMB $LogInitialSizeMB `
                     -LogAutogrowMB $LogAutogrowMB
        Write-Host "Configuration changes applied"
        Start-Sleep 2
    }
}

function Optimize-SQLInstance {

    param (
        [Parameter(Mandatory=$True)]
        [string]$SqlInstanceName    
    )
	#Instant File Initialization
    $enableIFI = Get-YN -Question "Enable Instant File Initialization?"
    
	#Lock Pages in memory
    $enableLockPages = Get-YN -Question "Enable Lock Pages in Memory?"


	$maxServerMem = Get-NumericInput -TextToPrompt "Specify Max Server Memory Value in MB:" -Default 2147483647
    
    $menuItems = [ordered]@{
        "1" = "Optimize for OLTP workload (enable trace flags -T1117 and -T1118)";
        "2" = "Optimize for DW workload (enable trace flags -T1117 and -T610)";
        "C" = "Skip this optimization";
    }
    Show-Menu -Title "Do you want to add trace flags to instance configuration?" -MenuItem $menuItems
    $action = Get-UserInput -AllowedInput $menuItems -Default "1" -ExitChar "1", "2", "C"

    Switch ($action) {
        "1" {$traceFlag = @("-T1117", "-T1118")}
        "2" {$traceFlag = @("-T1117", "-T610")}
    }

    Set-SQLInstanceOptimization -SqlInstanceName $SqlInstanceName `
                                -EnableIFI $enableIFI `
                                -EnableLockPagesInMemory $enableLockPages `
                                -TraceFlag $traceFlag `
								-MaxServerMemoryMB $maxServerMem

}

function Show-SqlInstanceMenu {
    param (
        [Parameter(Mandatory=$True)]
        [string]$SqlInstanceName
    )

    $menuItems = [ordered]@{
    "1" = "Change default paths for DBs / Log and Trace / Backup";
    "2" = "Optimize TempDB";
    "3" = "Optimize instance";
    "Q" = "Go back to previous menu";
    }

	Do {
        Clear-Host
        Show-Header "Manage instance $($SqlInstanceName)"
		Show-Menu -Title "Change instance parameters:" -MenuItem $menuItems
		$action = Get-UserInput -AllowedInput $menuItems -Default "Q" -ExitChar "Q"

		Switch($action) {
			"1" { 
					Show-PathAndDBMenu -SqlInstanceName $SqlInstanceName
				}
			"2" { 
					Show-TempDBMenu -SqlInstanceName $SqlInstanceName
				}
			"3" { 
					Optimize-SQLInstance -SqlInstanceName $SqlInstanceName
				}
			"Q" {Return}
		}
	} While (1 -eq 1)
}

function Show-SqlInstanceEditMenu {

    $global:idx = 1
    $sqlInstances = Get-SQLService -All | Where-Object { $_.Type -eq 'SqlServer'}
    $sqlList = $sqlInstances | ForEach-Object {$_ | Select-Object @{Label = '#'; Expression = {$global:idx; $global:Idx++;}}, `
                                              @{Label = 'InstanceName'; Expression = {$_.Name}}, `
                                              @{Label = 'Description'; Expression = {$_.DisplayName}}}
    Clear-Host
    Show-Header "Manage SQL Server Instances"
    $sqlList | Format-table

    If($sqlInstances.Length -eq 1) {
        $action = Get-YN -Question "Would you like to modify instance ($($sqlInstances[0].Name))?" `
                         -YesText "Change instance parameters" `
                         -NoText "Go back to previous menu"
        if(-not $action) {
            Return
        }
        Show-SqlInstanceMenu($sqlInstances[0].Name)
    }
    else {
        $menuItems = [ordered]@{
        "1..$($sqlInstances.GetUpperBound(0)+1)" = "Modify selected instance";
        "Q" = "Go back to previous menu";
        }
        Show-Menu -Title "Manage SQL Server Instances" -MenuItem $menuItems
        $action = Get-UserInput -AllowedInput $menuItems -Default "Q" -ExitChar "Q"

        Switch($action) {
            "Q" {Return}
            default {Show-SqlInstanceMenu -SqlInstance $sqlInstances[$action-1].Name}
        }
    }
}

function Show-StoragePoolDetail {
    [CmdLetBinding()]
    param (
        [Parameter(Mandatory=$True, Position=1, ValueFromPipeline)]
        $StoragePool
    )

    #$diskData = $storagePool | Get-PhysicalDisk | Select DeviceId, FriendlyName, @{Name="Size";Expression={"$([math]::Round($_.Size / 1GB,2)) GB"}} | Sort-Object DeviceId
    $diskData = $storagePool | Get-PhysicalDiskExt
    $OutTable = $diskData | Select-Object @{Name="Disk`#";Expression={$_.DeviceId}}, PhysicalLocation, @{Name="Size";Expression={"$($_.Size) GB"}} 
    $DiskData | Foreach-Object { $TotalSize += [int]$_.Size }
    Write-Host "`n$($storagePool.FriendlyName)" -ForegroundColor Yellow -NoNewline
    Write-Host " (Size $($TotalSize) GB) composed by disks:"
    $OutTable | Sort-Object DeviceId | Format-Table
    Write-Host "Virtual disks hosted by this storage pool:"
    $VirtualDisk = $storagePool | Get-VirtualDisk
    if($VirtualDisk) {
        Write-Host "`t$($VirtualDisk.FriendlyName) (#ofCol = $($VirtualDisk.NumberOfColumns), Interleave = $($VirtualDisk.Interleave / 1KB) KB)" 
    }
    else {
        Write-Host "`tNone"
    }

    $HostedVolume = $StoragePool | Get-HostedVolume -Detailed
    Write-Host "`nVolumes hosted by this storage pool:"
    $HostedVolume | ForEach-Object { Write-host "`t$_" }
}

function Show-PhysicalDiskDetail {
    
    param (
        [Parameter(Mandatory=$True, Position=1)]
        $PhysicalDisk
    )

    $HostedVolume = $PhysicalDisk | Get-HostedVolume -Detailed
    $ExtendedInfo = $PhysicalDisk | Get-PhysicalDiskExt
    Write-Host "Disk $($ExtendedInfo.DeviceId) - LUN $($ExtendedInfo.ScsiLun) (Size $($ExtendedInfo.Size) GB) hosts following volumes:"
    #Write-host "`t$($PhysicalDisk | Get-HostedVolume -Detailed)"
    $HostedVolume | ForEach-Object { Write-host "`t$_" }    
}

function Get-HostedVolume {
    [CmdLetBinding()]
    [OutputType([string[]])]

    param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [CimInstance]
        $StorageEntity,

        [Parameter(Mandatory = $false)]
        [switch]
        $Detailed = $false        
    )

    if($StorageEntity.CimClass.CimClassName -eq 'MSFT_PhysicalDisk') {
        $VolumeList = $StorageEntity | Get-Disk | Get-Partition | Get-Volume
    }
    else {
        $VolumeList = Get-Volume -StoragePool $StorageEntity
    }
    
    $OutArray = @()

    if($VolumeList) {
        foreach($Volume in $VolumeList) {
            if($Detailed) {
                $OutString = "Volume $($volume.DriveLetter) ($($volume.FileSystemLabel))"
                $OutString += " size $([math]::Round($volume.Size / 1MB, 0)) MB"
                $OutString += " formatted $($volume.FileSystem) $($volume.AllocationUnitSize / 1KB) KB"
                $OutArray += $OutString
            } 
            else {
                $OutArray += "$($volume.DriveLetter)"    
            }
        }
    }
    else {
        $OutArray += 'None'
    }

    $OutArray
}

function Test-UnallocatedSpace {
    [CmdLetBinding()]
    [OutputType([bool])]

    param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [CimInstance]
        $StorageEntity
    )

    switch ($StorageEntity.CimClass.CimClassName) {
        'MSFT_PhysicalDisk' { $Disk = $StorageEntity | Get-Disk }
        Default { $Disk = $StorageEntity | Get-VirtualDisk | Get-Disk }
    }

    $OutFlag = $false
    if($Disk.Size -gt $Disk.AllocatedSize) {
        $OutFlag = $true
    }
    $OutFlag
}

function Test-StorageVolumeDefined {
    [CmdLetBinding()]
    [OutputType([bool])]

    param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [CimInstance]
        $StorageEntity
    )

    switch ($StorageEntity.CimClass.CimClassName) {
        'MSFT_PhysicalDisk' { $Volume = $StorageEntity | Get-Disk | Get-Partition | Get-Volume }
        Default { $Volume = $StorageEntity | Get-Volume }
    }

    $OutFlag = $false
    if($Volume) {
        $OutFlag = $true
    }
    $OutFlag
}

function Show-StorageStatus {

    [CmdletBinding()]
    param (
        [switch]$All,
        [switch]$StoragePoolOnly,
        [switch]$NonPooledDiskOnly,
        [switch]$ShowIndex    )

    if($All) {
        $StoragePoolOnly = $true
        $NonPooledDiskOnly = $true
    }

    
    $pooledDisks = @()
    if($StoragePoolOnly) {
        Write-Host "Following storage pools are currently defined on this machine:" -ForegroundColor Cyan
    }
    $StoragePoolList = Get-StoragePool -IsPrimordial:$false -ErrorAction Ignore | Sort-Object -Property FriendlyName, UniqueId
    $global:idx = 1 
    foreach($StoragePool in $StoragePoolList) {
        $DiskData = $StoragePool | Get-PhysicalDiskExt
        $DiskData | ForEach-Object { $PooledDisks += $_.DeviceId }
        if($StoragePoolOnly) {
            $OutText = "`n"
            if($ShowIndex) {
                $OutText += $global:idx
                $global:idx += 1
            }
            $OutText += "`t$($StoragePool.FriendlyName)"
            $TotalSize = 0
            $DiskData | Foreach-Object { $TotalSize += [int]$_.Size }
            $DetailsText =  " (Size $TotalSize GB) Volumes: $(($StoragePool | Get-HostedVolume) -join ";")" 
            Write-Host $OutText -ForegroundColor Yellow -NoNewline
            Write-Host $DetailsText
        }
    }

    if($NonPooledDiskOnly) {
        #$remainingDisks = Get-PhysicalDisk | ? {$_.DeviceId -notin $pooledDisks -and $_.DeviceId -ge 2} | Sort-Object DeviceId
        $RemainingDisks = Get-PhysicalDiskExt | Where-Object {$_.DeviceId -notin $pooledDisks -and $_.DeviceId -ge 2} | Sort-Object DeviceId
        Write-Host "`nNon-pooled disks (excluding OS and temporary disks):" -ForegroundColor Cyan
        if(-not $remainingDisks) {
            Write-Host "`n`tNone`n"
        }
        else {
            $global:idx = 1
            
            $remainingDisks | ForEach-Object {
                    $OutText = "`n"
                    if($ShowIndex) {
                        $OutText += $global:idx
                        $global:idx += 1
                    }
                    $OutText += "`t[LUN = $($_.ScsiLun)"
                    $OutText += " | Disk# = $($_.DeviceId)" 
                    $OutText += " | Size = $($_.Size) GB"
                    $OutText += " | Volume = $((Get-HostedVolume -StorageEntity (Get-PhysicalDisk | Where-Object DeviceId -eq $_.DeviceId)) -join ";")]"
                    Write-Host $OutText
                    if($_.CanPool -ne $false) {
                        Write-Host "`tCan join a storage pool" -ForegroundColor Green
                    }
                    else {
                        Write-Host "`tCan't join a storage pool: $($_.CannotPoolReason)" -ForegroundColor Red
                    }
                }
        }
    }
}

function Show-StoragePoolEditMenu {

    param (
        [cimInstance]$StoragePool
    )

    Do {

        $VolumeDefined = $StoragePool | Test-StorageVolumeDefined
        $UnallocatedSpace = $StoragePool | Test-UnallocatedSpace
        $VirtualDisk = $StoragePool | Get-VirtualDisk

        $menuItems = [ordered]@{ "1" = "Remove storage pool with related virtual disks and volumes"; }
        if($VirtualDisk) {
            $menuItems.Add("2", "Remove existing virtual disks and create a new sql optimized virtual disk")
            if($VolumeDefined) {
                $menuItems.Add("3", "Format an existing volume with sql optimization")
                if($UnallocatedSpace) {
                    $menuItems.Add("4","Add a new volume with sql optimization")    
                }
            }
            else {
                $menuItems.Add("3","Add a new volume with sql optimization")  
            }
        }
        else {
            $menuItems.Add("2", "Create a new sql optimized virtual disk")
        }
        $menuItems.Add("Q", "Back to previous menu")

        Clear-Host
        Write-Host "Storage pool details:" -ForegroundColor Cyan
        Show-StoragePoolDetail -StoragePool $StoragePool
        Show-Menu -MenuItem $menuItems -Title "`nEdit storage pool:"
        $action = Get-UserInput -AllowedInput $menuItems -Default 1
        Switch ($action) {
            "1" {
					Write-Host "Removing storage pool $($StoragePool.FriendlyName)..."
					$cleared = $StoragePool | Clear-StoragePool
					if(-not $cleared) {
						Write-Host "Unable to remove virtual disks from selected storage pool" -ForegroundColor Yellow
						Start-sleep -Seconds 3
						Break
					}
                    
                    $physDisks = $storagePool | Get-PhysicalDisk
					Remove-StoragePool -UniqueId $StoragePool.UniqueId -Confirm:$false
                    foreach ($physDisk in $physDisks) {
                        $physDisk | Reset-PhysicalDisk
	                }

					Write-Host "Storage pool removed"
					Start-sleep -Seconds 3
                    Return
				}
            "2" {
                    if($VirtualDisk) {
                        Write-Host "Removing virtual disks from storage pool $($StoragePool.FriendlyName)..."

                        $vDisks = $StoragePool | Get-VirtualDisk
                        $previousLetter = ($vDisks | Get-Disk | Get-Partition | Get-Volume).DriveLetter | Select -First 1 
                        forEach($vDisk in $vDisks) {
                            $cleared = Clear-VirtualDisk -VirtualDisk $vDisks	
                            if(-not $cleared) {
                                Write-Host "Unable to remove virtual disks from selected storage pool" -ForegroundColor Yellow
                                Start-Sleep -Seconds 3
                                Break
                            }
                        }
                        Write-Host "Virtual disks removed. Insert details for new virtual disk:`n"
                    }
                    $storParams = Get-UserInputForStorage -VirtualDisk -usedLetter $previousLetter
                    Write-Host "`nCreating a new virtual disk optimized for SQL Server..."
					$out = New-VirtualDiskForSql -StoragePool $StoragePool `
							       			     -FriendlyName $storParams.VirtualDiskFriendlyName `
										         -WorkLoadType $storParams.WorkloadType `
										         -DriveLetter $storParams.DriveLetter `
										         -VolumeLabel $storParams.VolumeLabel `
										         -FileSystem $storParams.FileSystem
										  
					Write-Host "Virtual disk created"
					Start-sleep -Seconds 3
				}
            "3" {
                    if($VolumeDefined) {
                        $driveLetters = (Get-Volume -StoragePool $storagePool).DriveLetter
                        Write-Host "`nAvailable volumes on storage pool $($StoragePool.FriendlyName): $(($driveLetters -join '; '))"
                        
                        Do {
                            $defaultValue = $DriveLetters | Select-Object -first 1
                            $value = Read-Host "Choose the volume you want to format: [$defaultValue]"
                            if(-not $value) {
                                $value = $defaultValue
                            } 
                        } Until ($value -in $driveLetters)

                        $storParams = Get-UserInputForStorage -Volume -usedLetter $value

                        Write-Host "`Formatting volume $($storParams.DriveLetter)..."

                        Format-VolumeForSql -DriveLetter $value `
                                            -NewDriveLetter $storParams.DriveLetter `
                                            -VolumeLabel $storParams.VolumeLabel `
                                            -FileSystem $storParams.FileSystem
                        Write-Host "Volume formatted with 64KB unit allocation size"
                    }
                    else {
                        if($VirtualDisk.Count -gt 1) {
                            Write-Host "Unable to manage multiple virtual disks scenario" -ForegroundColor Red
                            Break
                        }
                        $storParams = Get-UserInputForStorage -Volume
                        $Created = New-VolumeForSql -Disk ($VirtualDisk | Get-Disk) `
                                         -DriveLetter $storParams.DriveLetter `
                                         -VolumeLabel $storParams.VolumeLabel `
                                         -FileSystem $storParams.FileSystem
                        if(-not $Created) {
                            Write-Host "Unable to create volume" -ForegroundColor Yellow
                            Pause
                        }
                        Write-Host 'Volume created'
                        Update-StorageProviderCache
                    }
                }
            "4" {
                if($VirtualDisk.Count -gt 1) {
                    Write-Host "Unable to manage multiple virtual disks scenario" -ForegroundColor Red
                    Break
                }
                $storParams = Get-UserInputForStorage -Volume
                $Created = New-VolumeForSql -Disk ($VirtualDisk | Get-Disk) `
                                 -DriveLetter $storParams.DriveLetter `
                                 -VolumeLabel $storParams.VolumeLabel `
                                 -FileSystem $storParams.FileSystem
                if(-not $Created) {
                    Write-Host "Unable to create volume" -ForegroundColor Yellow
                    Pause
                }
                Write-Host 'Volume created'
                Update-StorageProviderCache
            }
            "Q" {Return}
		}
    } While (1 -eq 1)
}

function Show-StoragePoolMenu {

    Do {
        Clear-Host
        
        Show-StorageStatus -StoragePoolOnly -ShowIndex

        $StoragePool = Get-StoragePool -IsPrimordial:$false -ErrorAction Ignore | Sort-Object -Property FriendlyName, UniqueId

        $PoolCount = $StoragePool | Measure-Object | Select-Object -ExpandProperty Count
        if(($PoolCount) -eq 1) {
            $action = Get-YN -Question "`nEdit storage pool $($StoragePool[0].FriendlyName)?" `
                            -NoText "No, go backup to previous menu"

            if(-not $action) {
                break
            }
            Show-StoragePoolEditMenu -StoragePool $StoragePool[0]
        }
        else {
            $menuItems = [ordered]@{
            "1..$($PoolCount)" = "Edit selected storage pool";
            "Q" = "Back to previous menu";
            }
            Show-Menu -MenuItem $menuItems -Title "`nEdit storage pool:"
            $action = Get-UserInput -AllowedInput $menuItems -Default "Q" -ExitChar "Q"

            if($action -eq 'Q') {
                break
            }
            Show-StoragePoolEditMenu -StoragePool $StoragePool[$action-1]
        }
    } While (0 -eq 0)
    Return
}

function Show-SingleDiskMenu {

    Do {
        Clear-Host

        Show-StorageStatus -NonPooledDiskOnly -ShowIndex

        $SingleDisk = Get-PhysicalDisk | Where-Object DeviceId -In (Get-PoolableDiskInfo).DeviceId | Sort-Object DeviceId
        $DiskCount = $SingleDisk | Measure-Object | Select-Object -ExpandProperty Count

        switch ($DiskCount) {
            "0" {
                    Write-Host "There aren't non-pooled disks available.`n"
                    Start-Sleep 3
                    Break
                }
            "1" {
                    $action = Get-YN -Question "`nClear this disk and prepare it for SQL Server?" `
                            -NoText "No, go backup to previous menu"

                    if(-not $action) {
                        Return
                    }
                    Show-ClearSingleDiskMenu -Disk $SingleDisk[0]
                }
            default {
                        $menuItems = [ordered]@{ "1..$($DiskCount)" = "Edit selected disk" }
                        $CanPool = $false
                        $SingleDisk | Foreach-Object { $CanPool = $CanPool -or $_.CanPool }
                        if($CanPool) {
                            $menuItems.Add("C", "Create a new storage pool")
                        }
                        $menuItems.add("Q", "Back to previous menu")
                        
                        Show-Menu -MenuItem $menuItems -Title "`nEdit disk configuration:"
                        $action = Get-UserInput -AllowedInput $menuItems -Default "Q" -ExitChar "Q"

                        switch ($action) {
                            "C" {
                                    $poolableDisk = Get-PoolableDiskInfo -OnlyEmpty
                                    if($poolableDisk) {
                                        $storParams = Get-UserInputForStorage -StoragePool
                                        if($storParams) {
                                            Write-Host 'Creating new storage pool...'
                                            New-StoragePoolForSql -StoragePoolFriendlyName $storParams.StoragePoolFriendlyName `
                                                                -LUN $storParams.LUN `
                                                                -VirtualDiskFriendlyName $storParams.VirtualDiskFriendlyName `
                                                                -WorkLoadType $storParams.WorkloadType `
                                                                -DriveLetter $storParams.DriveLetter `
                                                                -VolumeLabel $storParams.VolumeLabel `
                                                                -FileSystem $storParams.FileSystem | Out-Null
                                            Write-Host 'Storage pool created'
                                            Update-StorageProviderCache
                                            Start-Sleep -Seconds 2
                                        }
                                    }
                                    else {
                                        Write-Host "There aren't empty disks available for pooling. Please clear some of the existing disks." -ForegroundColor Yellow
                                        Start-Sleep -Seconds 3
                                        Break
                                    }
                                }
                            "Q" {Return}
                            default {Show-SingleDiskEditMenu -Disk $SingleDisk[$action-1]}
                        }
                }

        }
    } While (0 -eq 0)
}

function Show-SingleDiskEditMenu {

    [CmdLetBinding()]
    
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [cimInstance]$Disk
    )

    Do {
        Clear-Host

        $VolumeDefined = $Disk | Test-StorageVolumeDefined
        $UnallocatedSpace = $Disk | Test-UnallocatedSpace
        if($VolumeDefined) {
            $menuItems = [ordered]@{
                "1" = "Remove all existing volumes";
                "2" = "Format an existing volume with sql optimization";  
                }
            if($UnallocatedSpace) {
                $menuItems.Add("3","Add a new volume with sql optimization")    
            }
        }
        else {
            $menuItems = [ordered]@{ "1" = "Add a new volume with sql optimization" }  
        }
      
        $menuItems.Add("Q","Back to previous menu")
        Write-Host "Disk details:" -ForegroundColor Cyan
        Show-PhysicalDiskDetail -PhysicalDisk $Disk
        Show-Menu -MenuItem $menuItems -Title "`nEdit current disk:"
        $action = Get-UserInput -AllowedInput $menuItems -Default 1
        Switch ($action) {
            {@("1","3" -contains $_)} {
                    if(-not $VolumeDefined -or $UnallocatedSpace) {
                        $storParams = Get-UserInputForStorage -Volume
                        $Newd = New-VolumeForSql -Disk ($Disk | Get-Disk) `
                                         -DriveLetter $storParams.DriveLetter `
                                         -VolumeLabel $storParams.VolumeLabel `
                                         -FileSystem $storParams.FileSystem
                        if(-not $Newd) {
                            Write-Host "Unable to create volume" -ForegroundColor Yellow
                            Pause
                        }
                        Write-Host 'Volume created'
                        Update-StorageProviderCache
                    }
                    else {
                        Write-Host "Removing all existing volumes..."
                        
                        $cleared = Clear-SingleDisk -Disk $Disk
                        if(-not $cleared) {
                            Write-Host "Unable to remove volumes" -ForegroundColor Yellow
                            Pause
                            Return
                        }
                        
                        Write-Host "Volumes removed"
                        Update-StorageProviderCache
                        Return
                    }
				}
            "2" {
					$driveLetters = ($SingleDisk | Get-HostedVolume) -join ";"
					Write-Host "`nAvailable volumes on disk: $($driveLetters)"
					
					Do {
						$defaultValue = $DriveLetters | Select-Object -first 1
						$value = Read-Host "Choose the volume you want to format: [$defaultValue]"
						if(-not $value) {
							$value = $defaultValue
						} 
					} Until ($value -in $driveLetters)

					$storParams = Get-UserInputForStorage -Volume -usedLetter $value

					Write-Host "`Formatting volume $($storParams.DriveLetter)..."

					Format-VolumeForSql -DriveLetter $value `
                                        -NewDriveLetter $storParams.DriveLetter `
										-VolumeLabel $storParams.VolumeLabel `
										-FileSystem $storParams.FileSystem
					Write-Host "Volume formatted with 64KB unit allocation size"
				}
            "Q" {Return}
		}
    } While (1 -eq 1)
}

function Show-ClearSingleDiskMenu {

	Param(
		[cimSession]$disk
	)

	Write-Host 'Clearing selected disk...'
	$cleared = Clear-SingleDisk -Disk $disk
	if($cleared) {
		Write-Host 'Disk cleared`n'
		$storParams = Get-UserInputForStorage -Volume
		New-SingleDiskForSql -Disk $disk `
							 -DriveLetter $storParams.DriveLetter `
							 -VolumeLabel $storParams.VolumeLabel `
							 -FileSystem $storParams.FileSystem
		Write-Host 'Disk prepared for SQL Server'
	}
	else {
		Write-Host 'Unable to clear selected disk'
	}
}

function Show-StorageConfigMenu {

    Do {

        Clear-Host

        Show-Header -Title "Manage storage layout"
        Show-StorageStatus -All

        $menuItems = [ordered]@{
        "1" = "Alter existing storage pool configuration"
        "2" = "Add new storage pool or alter non-pooled disk configuration";
        "Q" = "Back to previous menu";
        }
        Write-Host ""
        Show-Menu -MenuItem $menuItems -Title "Edit current configuration:"
        $action = Get-UserInput -AllowedInput $menuItems -Default "1" -ExitChar "Q"

        Switch($action) {
            "1" {Show-StoragePoolMenu}
            "2" {Show-SingleDiskMenu}
            "Q" {Return}
            default {Show-StoragePoolMenu}
        }
    } While (1 -eq 1)
}

function Optimize-SqlIaasVm {
    
    param (

        [switch]$Interactive

    )

	$disclaimer = @"
This script is intended to be used on a newly created SQL Server VM on Azure IaaS.
It can works also in other scenario, but please keep in mind it can drive you to unwanted data loss. If you're
unsure about what it does, please have a look at the code. 
I'm not responsible for any incovenience it may causes.

This script is released under MIT License, feel free to adapt it to your needs and to share it, but please keep a
reference to the original source.

Copyright 2017 - Marco Obinu - www.omegamadlab.com

"@

    if($Interactive) {
        Clear-Host
        Show-Header -Title "SQL Azure IaaS VM optimization tool"

        Write-host $disclaimer -ForegroundColor Yellow
        
        Read-Host "Press ENTER to continue"

        Do {
            
            Clear-Host
            
            Show-Header -Title "SQL Azure IaaS VM optimization tool"

            $menuItems = [ordered]@{
            "1" = "Edit storage layout"
            "2" = "Edit Sql Server configuration";
            "Q" = "Quit to prompt";
            }

            Show-Menu -MenuItem $menuItems
            $action = Get-UserInput -AllowedInput $menuItems -Default "1" -ExitChar "Q"

            Switch($action) {
                "1" {Show-StorageConfigMenu}
                "2" {Show-SqlServiceEditMenu}
                "Q" {Exit}
                default {Show-StorageConfigMenu}
            }

			

        } While (1 -eq 1)

    }
}

Optimize-SqlIaasVm -Interactive