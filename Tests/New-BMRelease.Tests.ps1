
#Requires -Version 4
Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

$session = New-BMTestSession 
$app = New-BMTestApplication -Session $session -CommandPath $PSCommandPath
$pipelineName = ('{0}.{1}' -f (Split-Path -Path $PSCommandPath -Leaf),[IO.Path]::GetRandomFileName())
$pipeline = New-BMPipeline -Session $session -Name $pipelineName -Application $app -Color '#ffffff'

function Assert-Release
{
    param(
        [Parameter(ValueFromPipeline=$true)]
        $Release,
        $HasNumber,
        $HasName
    )

    process
    {
        It 'should return the release' {
            $Release | Should -Not -BeNullOrEmpty
        }

        It 'should create the release' {
            $newRelease = $Release | Get-BMRelease -Session $session 
            $newRelease | Should -Not -BeNullOrEmpty
            $newRelease.id | Should -Be $Release.id
        }

        It 'should set application' {
            $Release.applicationId | Should -Be $app.Application_Id
        }

        It 'should set release number' {
            $Release.number | Should -Be $HasNumber
        }

        It 'should set pipeline' {
            $Release.pipelineId | Should -Be $pipeline.Pipeline_Id
        }

        if( -not $HasName )
        {
            $HasName = $HasNumber
        }

        It 'should set name' {
            $Release.name | Should -Be $HasName
        }
    }
}

function New-TestReleaseNumber
{
    [IO.Path]::GetRandomFileName()
}

Describe 'New-BMRelease.when piping application and passing pipeline' {
    $releaseNumber = New-TestReleaseNumber
    $app | 
        New-BMRelease -Session $session -Number $releaseNumber -Pipeline $pipeline | 
        Assert-Release -HasNumber $releaseNumber 
}

Describe 'New-BMRelease.when piping application ID and passing pipeline ID' {
    $releaseNumber = New-TestReleaseNumber
    $app.Application_Id | 
        New-BMRelease -Session $session -Number $releaseNumber -Pipeline $pipeline.Pipeline_Id | 
        Assert-Release -HasNumber $releaseNumber 
}

Describe 'New-BMRelease.when piping application name and passing pipeline name' {
    $releaseNumber = New-TestReleaseNumber
    $app.Application_Name | 
        New-BMRelease -Session $session -Number $releaseNumber -Pipeline $pipeline.Pipeline_Name | 
        Assert-Release -HasNumber $releaseNumber 
}

<#
Describe 'New-BMRelease.when customizing release name' {
    $releaseNumber = New-TestReleaseNumber
    $releaseName = New-TestReleaseNumber
    $app |
        New-BMRelease -Session $session -Number $releaseNumber -Name $releaseName -Pipeline $pipeline |
        Assert-Release -HasNumber $releaseNumber -HasName $releaseName
}
#>