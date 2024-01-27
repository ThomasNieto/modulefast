﻿# Copyright (c) Thomas Nieto - All Rights Reserved
# You may use, distribute and modify this code under the
# terms of the MIT license.

using module AnyPackage
using namespace AnyPackage.Provider
using namespace NuGet.Versioning
using namespace System.Management.Automation

[PackageProvider('ModuleFast')]
class ModuleFastProvider : PackageProvider, IInstallPackage {
    [void] InstallPackage([PackageRequest] $request) {
        $installModuleFast = @{ }

        if ($request.DynamicParameters.Destination) {
            $installModuleFast['Destination'] = $request.DynamicParameters.Destination
        }

        if ($request.DynamicParameters.ThrottleLimit) {
            $installModuleFast['ThrottleLimit'] = $request.DynamicParameters.ThrottleLimit
        }

        if ($request.DynamicParameters.CILockFilePath) {
            $installModuleFast['CILockFilePath'] = $request.DynamicParameters.CILockFilePath
        }

        if ($request.DynamicParameters.Update) {
            $installModuleFast['Update'] = $request.DynamicParameters.Update
        }

        if ($request.DynamicParameters.NoPathUpdate) {
            $installModuleFast['NoPathUpdate'] = $request.DynamicParameters.NoPathUpdate
        }

        if ($request.DynamicParameters.NoPSModulePathUpdate) {
            $installModuleFast['NoPSModulePathUpdate'] = $request.DynamicParameters.NoPSModulePathUpdate
        }

        if ($request.Source) {
            $installModuleFast['Source'] = $request.Source
        }

        $spec = ''

        if ($request.Prerelease) {
            $spec += '!'
        }

        $spec += $request.Name

        if ($request.Version) {
            $spec += ":$($request.Version)"
        }

        Install-ModuleFast $spec @installModuleFast -ErrorAction Stop -PassThru |
        Write-Package -Request $request
    }

    [object] GetDynamicParameters([string] $commandName) {
        return $(switch ($commandName) {
            'Install-Package' { [InstallPackageDynamicParameters]::new() }
            default { $null }
        })
    }
}

class InstallPackageDynamicParameters {
    [Parameter()]
    [string] $Destination

    [Parameter()]
    [int] $ThrottleLimit

    [Parameter()]
    [string] $CILockFilePath

    [Parameter()]
    [switch] $Update

    [Parameter()]
    [switch] $NoPathUpdate

    [Parameter()]
    [switch] $NoPSModulePathUpdate
}

[guid] $id = '853fb009-a8f3-4ecf-9f72-9f81e0c32144'
[PackageProviderManager]::RegisterProvider($id, [ModuleFastProvider], $MyInvocation.MyCommand.ScriptBlock.Module)

$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
    [PackageProviderManager]::UnregisterProvider($id)
}

function Write-Package {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $Name,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $ModuleVersion,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $Location,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $Guid,

        [Parameter(Mandatory)]
        [PackageRequest]
        $Request
    )

    process {
        $source = [PackageSourceInfo]::new($Location, $Location, $Request.ProviderInfo)
        $package = [PackageInfo]::new($Name, $ModuleVersion, $source, '', $null, @{ Guid = $Guid }, $Request.ProviderInfo)
        $Request.WritePackage($package)
    }
}
