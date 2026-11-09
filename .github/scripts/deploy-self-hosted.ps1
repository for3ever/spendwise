[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Image,
    [int]$Port = 8080,
    [int]$CandidatePort = 18080,
    [string]$ContainerName = 'spendwise',
    [string]$CandidateName = 'spendwise-candidate',
    [string]$BackupName = 'spendwise-previous'
)

$ErrorActionPreference = 'Stop'

function Test-Container {
    param([string]$Name)
    & docker container inspect $Name *> $null
    return ($LASTEXITCODE -eq 0)
}

function Invoke-Docker {
    param([string[]]$Arguments)
    & docker @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Docker command failed: docker $($Arguments -join ' ')"
    }
}

function Get-ContainerImage {
    param([string]$Name)
    return (& docker inspect --format '{{.Config.Image}}' $Name 2>$null)
}

function Get-ContainerLabel {
    param([string]$Name, [string]$Label)
    $format = '{{ index .Config.Labels "' + $Label + '" }}'
    return (& docker inspect --format $format $Name 2>$null)
}

function Wait-HttpReady {
    param([string]$Url, [string]$Name)
    for ($attempt = 1; $attempt -le 30; $attempt++) {
        try {
            $response = Invoke-WebRequest -UseBasicParsing -Uri $Url -TimeoutSec 3
            if ([int]$response.StatusCode -ge 200 -and [int]$response.StatusCode -lt 400) {
                Write-Host "Ready: $Url"
                return
            }
        } catch {
            # The container may still be starting; keep polling.
        }
        if (-not (Test-Container $Name)) {
            throw "Container '$Name' exited before becoming ready."
        }
        Start-Sleep -Seconds 2
    }
    throw "Timed out waiting for $Url"
}

function Remove-ManagedContainer {
    param([string]$Name)
    if (Test-Container $Name) {
        Invoke-Docker @('rm', '-f', $Name)
    }
}

# Never take over a port owned by a different container.
$portRows = @(& docker ps --format '{{.Names}}|{{.Ports}}')
$otherProductionOwners = $portRows | Where-Object {
    $_ -match "(?:0\.0\.0\.0|\[::\]):$Port->" -and $_ -notlike "$ContainerName|*"
}
if ($otherProductionOwners) {
    throw "Port $Port is already published by another container: $($otherProductionOwners -join ', ')"
}

$candidateOwners = $portRows | Where-Object {
    $_ -match "(?:0\.0\.0\.0|\[::\]):$CandidatePort->"
}
if ($candidateOwners) {
    throw "Candidate port $CandidatePort is already published: $($candidateOwners -join ', ')"
}

if (Test-Container $CandidateName) {
    if ((Get-ContainerLabel $CandidateName 'com.spendwise.role') -ne 'candidate') {
        throw "Container name '$CandidateName' is already used by an unmanaged container."
    }
    Remove-ManagedContainer $CandidateName
}

if (Test-Container $BackupName) {
    if ((Get-ContainerLabel $BackupName 'com.spendwise.role') -ne 'previous') {
        throw "Container name '$BackupName' is already used by an unmanaged container."
    }
    throw "A previous deployment container already exists: $BackupName"
}

Invoke-Docker @('run', '--detach', '--name', $CandidateName, '--publish', "${CandidatePort}:80", '--label', 'com.spendwise.role=candidate', $Image)
$backupCreated = $false

try {
    Wait-HttpReady "http://127.0.0.1:$CandidatePort/" $CandidateName

    if (Test-Container $ContainerName) {
        $oldImage = Get-ContainerImage $ContainerName
        if ($oldImage -ne 'spendwise:local' -and $oldImage -notmatch '(^|/)spendwise-app:') {
            throw "Container '$ContainerName' is not a SpendWise container ($oldImage); refusing to replace it."
        }
        Invoke-Docker @('stop', $ContainerName)
        if (Test-Container $ContainerName) {
            Invoke-Docker @('rename', $ContainerName, $BackupName)
            $backupCreated = $true
        }
    }

    Invoke-Docker @('run', '--detach', '--name', $ContainerName, '--publish', "${Port}:80", '--restart', 'unless-stopped', '--label', 'com.spendwise.role=production', $Image)
    try {
        Wait-HttpReady "http://127.0.0.1:$Port/" $ContainerName
    } catch {
        Write-Host 'New production container failed readiness. Logs follow:'
        & docker logs $ContainerName
        Remove-ManagedContainer $ContainerName
        if ($backupCreated) {
            Invoke-Docker @('rename', $BackupName, $ContainerName)
            Invoke-Docker @('start', $ContainerName)
            Wait-HttpReady "http://127.0.0.1:$Port/" $ContainerName
        }
        throw
    }

    if ($backupCreated) {
        Remove-ManagedContainer $BackupName
    }
    Write-Host "SpendWise deployment succeeded: $Image"
} finally {
    Remove-ManagedContainer $CandidateName
}
