[CmdletBinding()]
param(
)

#Requires -RunAsAdministrator
#Requires -Version 5
Set-StrictMode -Version 'Latest'

& {
    $VerbosePreference = 'SilentlyContinue'
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'Modules\Carbon') -Force
}

$runningUnderAppVeyor = (Test-Path -Path 'env:APPVEYOR')

$version = '5.8.2'

$installerPath = Join-Path -Path $env:TEMP -ChildPath ('BuildMasterInstaller-SQL-{0}.exe' -f $version)
if( -not (Test-Path -Path $installerPath -PathType Leaf) )
{
    $uri = ('http://inedo.com/files/buildmaster/sql/{0}.exe' -f $version)
    Write-Verbose -Message ('Downloading {0}' -f $uri)
    Invoke-WebRequest -Uri $uri -OutFile $installerPath
}

$bmInstallInfo = Get-ProgramInstallInfo -Name 'BuildMaster'
if( -not $bmInstallInfo )
{
    # Under AppVeyor, use the pre-installed database.
    # Otherwise, install a SQL Express BuildMaster instance.
    $dbParam = '/InstallSqlExpress'
    if( $runningUnderAppVeyor )
    {
        $dbParam = '"/ConnectionString=Server=(local)\SQL2016;Database=BuildMaster;User ID=sa;Password=Password12!"'
    }

    $outputRoot = Join-Path -Path $PSScriptRoot -ChildPath '.output'
    New-Item -Path $outputRoot -ItemType 'Directory' -ErrorAction Ignore

    $logRoot = Join-Path -Path $outputRoot -ChildPath 'logs'
    New-Item -Path $logRoot -ItemType 'Directory' -ErrorAction Ignore

    Write-Verbose -Message ('Running BuildMaster installer {0}.' -f $installerPath)
    $logPath = Join-Path -Path $logRoot -ChildPath 'buildmaster.install.log'
    $installerFileName = $installerPath | Split-Path -Leaf
    $stdOutLogPath = Join-Path -Path $logRoot -ChildPath ('{0}.stdout.log' -f $installerFileName)
    $stdErrLogPath = Join-Path -Path $logRoot -ChildPath ('{0}.stderr.log' -f $installerFileName)
    $process = Start-Process -FilePath $installerPath `
                             -ArgumentList '/S','/Edition=Express',$dbParam,('"/LogFile={0}"' -f $logPath) `
                             -Wait `
                             -PassThru `
                             -RedirectStandardError $stdErrLogPath `
                             -RedirectStandardOutput $stdOutLogPath
    $process.WaitForExit()

    Write-Verbose -Message ('{0} exited with code {1}' -f $installerFileName,$process.ExitCode)

    if( -not (Get-ProgramInstallInfo -Name 'BuildMaster') )
    {
        if( $runningUnderAppVeyor )
        {
            Get-ChildItem -Path $logRoot |
                ForEach-Object {
                    $_
                    $_ | Get-Content
                }
        }
        Write-Error -Message ('It looks like BuildMaster {0} didn''t install. The install log might have more information: {1}' -f $version,$logPath)
    }
}
elseif( $bmInstallInfo.DisplayVersion -notmatch ('^{0}\b' -f [regex]::Escape($version)) )
{
    Write-Warning -Message ('You''ve got an old version of BuildMaster installed. You''re on version {0}, but we expected version {1}. Please *completely* uninstall version {0} using the Programs and Features control panel, then re-run this script.' -f $bmInstallInfo.DisplayVersion,$version)
}

