
Add-Type -AssemblyName 'System.Web'

$functionsDir = Join-Path -Path $PSScriptRoot -ChildPath 'Functions'
if( (Test-Path -Path $functionsDir -PathType Container) )
{
    foreach( $item in (Get-ChildItem -Path $functionsDir -Filter '*.ps1') )
    {
        . $item.FullName
    }
}
