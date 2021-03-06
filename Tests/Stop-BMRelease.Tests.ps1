
#Requires -Version 4
Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

$session = New-BMTestSession
$app = New-BMTestApplication $session -CommandPath $PSCommandPath
$pipeline = New-BMPipeline -Session $session -Name $app.Application_name -Application $app

function GivenARelease
{
    param(
        $Name,
        $Number
    )

    New-BMRelease -Session $session -Application $app -Number $Number -Pipeline $pipeline.Pipeline_Name -Name $Name
}

function Init
{
    $script:app = $null
}

function ThenTheReleaseIsCancelled
{
    param(
        $Number
    )

    $release = Get-BMRelease -Session $session -Application $app |
        Where-Object { $_.number -eq $Number }

    It ('should cancel the release') {
        $release.status | Should -Be 'canceled'
    }
}

function WhenCancellingTheRelease
{
    param(
        $Application,
        $Number,
        $Reason
    )

    Stop-BMRelease -Session $session -Application $Application -Number $Number -Reason $Reason
}

Describe 'Stop-BMRelease.when cancelling with application object' {
    GivenARelease 'fubar' '3.4'
    WhenCancellingTheRelease $app.Application_Id '3.4'
    ThenTheReleaseIsCancelled '3.4'
}

# BuildMaster API doesn't expose a way to see the cancellation reason, so we mock the call.
Describe 'Stop-BMRelease.when passing a reason' {
    Mock -CommandName 'Invoke-BMNativeApiMethod' -ModuleName 'BuildMasterAutomation'
    GivenARelease 'snafu' '3.5'
    WhenCancellingTheRelease $app.Application_Id '3.5' 'it looked at me funny'
    It ('should pass a reason') {
        Assert-MockCalled -CommandName 'Invoke-BMNativeApiMethod' -ModuleName 'BuildMasterAutomation' -ParameterFilter { $Parameter['CancelledReason_Text'] -eq 'it looked at me funny' }
    }
}