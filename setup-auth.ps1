<#
.SYNOPSIS
    Automate the OAuthPluginVault setup for the BPA Analytics Cowork Plugin (Option C — M365
    Copilot), and provide a fast, low-risk path to update an already-deployed tenant to a
    newer version.

.DESCRIPTION
    Automates everything in the "Step 6 — Authentication" section of README.md that doesn't
    require the Teams Developer Portal UI:
      1. Prompts for the Power Platform environment ID and patches `manifest.json`'s
         `mcpServerUrl` with it.
      2. Prompts for the OAuth registration ID (`referenceId`) produced by the Teams
         Developer Portal — that step has no public API and cannot be automated.
      3. Patches `manifest.json` (`mcpServerUrl`, `authorization.referenceId`) and bumps
         the version.
      4. Appends a dated entry to CHANGELOG.md and moves any `[Unreleased]` notes into it.
      5. Re-runs package.ps1 to validate ASKILL rules and produce the ZIP.

    Unlike the Azure DevOps MCP connector, BPA's OAuthPluginVault does not require creating
    an Azure AD app registration or client secret — the Teams Developer Portal OAuth
    registration points directly at your tenant's existing token endpoint
    (`login.microsoftonline.com/{tenantId}/oauth2/v2.0/token`) with the
    `https://service.powerapps.com/.default` scope. The Teams Developer Portal OAuth client
    registration (dev.teams.microsoft.com) must still be completed manually in a browser —
    Microsoft does not expose a public API for it.

    Alternative (Option D — Cowork Connectors gallery): if you only need Cowork-wide
    access to the raw BPA MCP tools and don't need this repo's curated `agentSkills/`
    (finance persona prompts, tool filtering, branding), you can skip steps 2-5 above
    entirely and register the connector directly at
    admin.cloud.microsoft/#/copilot/connectors/add -> Create a new connector, instead of
    going through the Teams Developer Portal and the manifest.json/package.ps1/upload flow.
    See the "Alternative" callout under Step 6 in README.md for details.

    Use `-UpdateOnly` for the common "I already have auth configured from a previous run,
    I just want to push a newer version" case (e.g. upgrading an existing 1.3.1 tenant
    deployment to 1.4.0+). It skips the environment ID and Teams Developer Portal
    `referenceId` prompts entirely, leaves the existing `mcpServerUrl` and `authorization`
    block in manifest.json untouched, and only bumps the version, appends a changelog
    entry, and re-packages — the minimum needed to produce a ZIP you can upload via
    **Agents → All agents → BPA Analytics → Update**.

.PARAMETER EnvironmentId
    Power Platform environment ID (found in https://admin.powerplatform.microsoft.com ->
    your environment -> Settings -> Session details -> Environment ID). Required unless
    -UpdateOnly is used, in which case the existing value in manifest.json is kept and this
    parameter can be omitted.

.PARAMETER SkipEnvironmentPrompt
    Skip the environment ID patch (keep the existing `mcpServerUrl` in manifest.json) but
    still prompt for the Teams Developer Portal `referenceId`. Use this when you already
    have the correct environment ID configured and only need to refresh the OAuth
    registration reference. For a plain version update with no auth changes at all, use
    `-UpdateOnly` instead.

.PARAMETER UpdateOnly
    Fast update path: skips the environment ID AND the referenceId prompts, keeping
    manifest.json's existing `mcpServerUrl` and `authorization` block unchanged. Only bumps
    the version, appends a CHANGELOG.md entry, and re-runs package.ps1. Use this to move an
    already-configured tenant (e.g. one running 1.3.1 with auth already set up) to a newer
    version without re-running the Teams Developer Portal step.

.PARAMETER NewVersion
    Version string to write into manifest.json (e.g. "1.4.0"). If omitted, the patch
    segment of the current version is incremented automatically.

.EXAMPLE
    .\setup-auth.ps1 -EnvironmentId 6164e44b-836e-e82c-afc2-e4dd59ab3a49

.EXAMPLE
    .\setup-auth.ps1 -EnvironmentId 6164e44b-836e-e82c-afc2-e4dd59ab3a49 -NewVersion 1.4.0

.EXAMPLE
    # Upgrade an existing tenant deployment (auth already configured) from 1.3.1 to 1.4.0
    .\setup-auth.ps1 -UpdateOnly -NewVersion 1.4.0
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$EnvironmentId,

    [switch]$SkipEnvironmentPrompt,

    [switch]$UpdateOnly,

    [string]$NewVersion
)

if (-not $UpdateOnly -and -not $SkipEnvironmentPrompt -and -not $EnvironmentId) {
    Write-Error "-EnvironmentId is required unless -UpdateOnly or -SkipEnvironmentPrompt is used."
    exit 1
}

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root         = Split-Path -Parent $MyInvocation.MyCommand.Path
$manifestPath = Join-Path $root "manifest.json"
$changelogPath = Join-Path $root "CHANGELOG.md"
$packagePath  = Join-Path $root "package.ps1"

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host "== $Title ==" -ForegroundColor Cyan
}

if (-not (Test-Path $manifestPath)) {
    Write-Error "manifest.json not found at: $manifestPath"
    exit 1
}

$referenceId = $null

if ($UpdateOnly) {
    Write-Section "Update-only mode (-UpdateOnly)"
    Write-Host "Skipping the environment ID and Teams Developer Portal prompts."
    Write-Host "manifest.json's existing 'mcpServerUrl' and 'authorization' block will be kept as-is."
    Write-Host "Use this when auth is already configured (e.g. upgrading an existing 1.3.1 tenant deployment)."
} else {
    # -------------------------------------------------------------------------
    # Step 2 — Teams Developer Portal OAuth client registration (manual, no public API)
    # -------------------------------------------------------------------------
    Write-Section "Teams Developer Portal (manual step)"
    Write-Host "Go to https://dev.teams.microsoft.com -> Connectors -> OAuth registrations -> Register"
    Write-Host "using token endpoint https://login.microsoftonline.com/{tenantId}/oauth2/v2.0/token"
    Write-Host "and scope https://service.powerapps.com/.default (see README.md Step 2 for field-by-field guidance)."
    Write-Host "This step has no public REST/PowerShell API and cannot be automated."
    Write-Host ""

    $referenceId = Read-Host "Paste the OAuth registration ID (referenceId) from Teams Developer Portal"
    if ([string]::IsNullOrWhiteSpace($referenceId)) {
        Write-Error "referenceId is required to update manifest.json. Re-run once you have it."
        exit 1
    }
}

# ---------------------------------------------------------------------------
# Patch manifest.json
# ---------------------------------------------------------------------------
Write-Section "Patching manifest.json"

$manifest = [IO.File]::ReadAllText($manifestPath) | ConvertFrom-Json

if ($UpdateOnly) {
    Write-Host "  Keeping existing mcpServerUrl and authorization block unchanged."
} else {
    if ($EnvironmentId) {
        $manifest.agentConnectors[0].toolSource.remoteMcpServer.mcpServerUrl = "https://agent365.svc.cloud.microsoft/mcp/environments/$EnvironmentId/servers/msdyn_ERPAnalyticsMCPServer"
    } else {
        Write-Host "  Keeping existing mcpServerUrl unchanged (-SkipEnvironmentPrompt)."
    }
    $manifest.agentConnectors[0].toolSource.remoteMcpServer.authorization.type = "OAuthPluginVault"
    $manifest.agentConnectors[0].toolSource.remoteMcpServer.authorization.referenceId = $referenceId
}

$currentVersion = $manifest.version
if (-not $NewVersion) {
    $parts = $currentVersion.Split('.')
    if ($parts.Count -eq 3) {
        $parts[2] = [string]([int]$parts[2] + 1)
        $NewVersion = [string]::Join('.', $parts)
    } else {
        Write-Error "Cannot auto-increment version '$currentVersion'. Pass -NewVersion explicitly."
        exit 1
    }
}
$manifest.version = $NewVersion

($manifest | ConvertTo-Json -Depth 20) | Set-Content -Path $manifestPath -Encoding utf8
if ($UpdateOnly) {
    Write-Host ("  manifest.json updated: version {0} -> {1} (mcpServerUrl/authorization unchanged)." -f $currentVersion, $NewVersion) -ForegroundColor Green
} else {
    Write-Host ("  manifest.json updated: version {0} -> {1}, referenceId set." -f $currentVersion, $NewVersion) -ForegroundColor Green
}

# ---------------------------------------------------------------------------
# Update CHANGELOG.md
# ---------------------------------------------------------------------------
Write-Section "Updating CHANGELOG.md"

if (Test-Path $changelogPath) {
    $changelog = Get-Content $changelogPath -Raw
    $today = (Get-Date).ToString("yyyy-MM-dd")

    $unreleasedPattern = '(?s)## \[Unreleased\]\s*(.*?)(\r?\n---)'
    $match = [regex]::Match($changelog, $unreleasedPattern)

    $unreleasedNotes = if ($match.Success) { $match.Groups[1].Value.Trim() } else { '' }
    if ([string]::IsNullOrWhiteSpace($unreleasedNotes) -or $unreleasedNotes -eq '_Nothing yet._') {
        $unreleasedNotes = if ($UpdateOnly) {
            "- Version bump only — no auth or skill changes (via ``setup-auth.ps1 -UpdateOnly``)"
        } else {
            "- Configured OAuthPluginVault authentication via ``setup-auth.ps1``"
        }
    }

    $newEntry = @"
## [$NewVersion] — $today

### Changed
$unreleasedNotes

---

## [Unreleased]

_Nothing yet._
"@

    if ($match.Success) {
        $changelog = $changelog.Substring(0, $match.Index) + $newEntry
    } else {
        $changelog = $changelog.TrimEnd() + "`n`n---`n`n" + $newEntry
    }

    Set-Content -Path $changelogPath -Value $changelog -Encoding utf8
    Write-Host "  CHANGELOG.md updated with entry for $NewVersion." -ForegroundColor Green
} else {
    Write-Warning "CHANGELOG.md not found - skipping changelog update."
}

# ---------------------------------------------------------------------------
# Re-run package.ps1 (ASKILL validation + zip)
# ---------------------------------------------------------------------------
Write-Section "Packaging"

if (Test-Path $packagePath) {
    & $packagePath
} else {
    Write-Warning "package.ps1 not found - skipping validation/packaging step."
}

Write-Host ""
Write-Host "Done. Next manual step: upload bpa-analytics-cowork.zip in admin.microsoft.com -> Agents -> All agents -> Update." -ForegroundColor Cyan
