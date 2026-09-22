param([Parameter(Mandatory=$true)][string]$AppStage)
$ErrorActionPreference = 'Stop'
& npm.cmd ci --omit=dev --ignore-scripts --no-audit --no-fund --prefix $AppStage
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
exit 0
