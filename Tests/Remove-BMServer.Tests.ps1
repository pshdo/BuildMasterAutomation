
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

$session = New-BMTestSession

function Init
{
    $Global:Error.Clear()
    Get-BMServer -Session $session | Remove-BMServer -Session $session
}

function GivenServer
{
    param(
        [Parameter(Mandatory)]
        [string]$Named
    )

    New-BMServer -Session $session -Name $Named -Windows
}

function ThenServerExists
{
    param(
        [Parameter(Mandatory)]
        [string]$Named
    )

    Get-BMServer -Session $session -Name $Named | Should -Not -BeNullOrEmpty
}

function ThenServerDoesNotExist
{
    param(
        [Parameter(Mandatory)]
        [string]$Named
    )

    Get-BMServer -Session $session -Name $Named -ErrorAction Ignore | Should -BeNullOrEmpty
}

function WhenRemovingServer
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Named,

        [Switch]
        $WhatIf
    )

    $optionalParams = @{ }
    if( $WhatIf )
    {
        $optionalParams['WhatIf'] = $true
    }

    $result = Remove-BMServer -Session $session -Name $Named @optionalParams
    $result | Should -BeNullOrEmpty
}

Describe 'Remove-BMServer.when server exists' {
    It ('should remove the server') {
        Init
        GivenServer -Named 'Fubar'
        WhenRemovingServer -Named 'Fubar'
        ThenNoErrorWritten
        ThenServerDoesNotExist -Named 'Fubar'
    }
}

Describe 'Remove-BMServer.when server does not exist' {
    It ('should not write any errors') {
        Init
        WhenRemovingServer -Named 'IDoNotExist'
        ThenNoErrorWritten
        ThenServerDoesNotExist -Named 'IDoNotExist'
    }
}

Describe 'Remove-BMServer.when using -WhatIf' {
    It ('should not remove the server') {
        Init
        GivenServer -Named 'One'
        WhenRemovingServer -Named 'One' -WhatIf
        ThenNoErrorWritten
        ThenServerExists -Named 'One'
    }
}

Describe 'Remove-BMServer.when name contains URI senstive characters' {
    It 'should encode the name' {
        Init
        Mock -CommandName 'Invoke-BMRestMethod' -ModuleName 'BuildMasterAutomation'
        WhenRemovingServer -Named 'u r i?&'
        Assert-MockCalled -CommandName 'Invoke-BMRestMethod' -ModuleName 'BuildMasterAutomation' -ParameterFilter { $Name -eq 'infrastructure/servers/delete/u%20r%20i%3F%26' }
    }
}