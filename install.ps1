# tincan is now Reason Network (https://github.com/reason-machines/reason-network): this installs reason-network,
# no account needed. On a machine that has tincan (tincan's updater runs this), it also leaves a copy under the old
# name, which runs as reason-network: that moves the team, the agents and the logon entry over. In PowerShell:
#
#   irm <this url> | iex                                                  install, then set up (start or join a team)
#   & ([scriptblock]::Create((irm <this url>))) <team link>               install, then join that team
#   & ([scriptblock]::Create((irm <this url>))) <team link> --as <name>   the same, without questions (for agents)
#   & ([scriptblock]::Create((irm <this url>))) init <team> --as <name>   install and start a team, without questions
#
# Environment: TINCAN_BIN_DIR (default ~\.local\bin), TINCAN_NO_PROMPT (never ask anything: updates),
# REASON_NETWORK_VERSION (default latest).
& {
  $ErrorActionPreference = 'Stop'
  $bin = if ($env:TINCAN_BIN_DIR) { $env:TINCAN_BIN_DIR } else { Join-Path $HOME '.local\bin' }
  $releases = 'https://github.com/reason-machines/reason-network/releases'
  $script = if ($env:REASON_NETWORK_VERSION) { "$releases/download/$($env:REASON_NETWORK_VERSION)/install.ps1" } else { "$releases/latest/download/install.ps1" }

  Write-Host 'tincan is now Reason Network: installing reason-network.'
  $saved = @{ BIN = $env:REASON_NETWORK_BIN_DIR; PROMPT = $env:REASON_NETWORK_NO_PROMPT }
  $env:REASON_NETWORK_BIN_DIR = $bin
  $env:REASON_NETWORK_NO_PROMPT = '1'
  try { & ([scriptblock]::Create((Invoke-RestMethod -UseBasicParsing $script))) } finally {
    $env:REASON_NETWORK_BIN_DIR = $saved.BIN
    $env:REASON_NETWORK_NO_PROMPT = $saved.PROMPT
  }
  $exe = Join-Path $bin 'reason-network.exe'
  if (-not (Test-Path $exe)) { throw "tincan install: reason-network isn't in $bin; tincan is unchanged" }
  $old = Join-Path $bin 'tincan.exe'
  if (Test-Path $old) {
    # A running tincan.exe can't be replaced, but it can be renamed: the copy goes in first as tincan.new, then the old
    # one moves aside and the copy into place (back again if that fails). Ones set aside before go once nothing runs them.
    $new = Join-Path $bin 'tincan.new'
    Copy-Item $exe $new -Force
    Get-ChildItem $bin -Filter 'tincan.*.old' | Remove-Item -Force -ErrorAction SilentlyContinue
    $aside = Join-Path $bin "tincan.$(Get-Random).old"
    Move-Item $old $aside
    try { Move-Item $new $old } catch { Move-Item $aside $old; Remove-Item $new -Force -ErrorAction SilentlyContinue; throw }
  }

  if ($args.Count -eq 0) {
    if ($env:TINCAN_NO_PROMPT -or [Console]::IsInputRedirected) { return }
    & $exe
  } elseif ($args[0] -match '^(-.*|init|join|setup)$') {
    & $exe @args
  } else {
    & $exe join @args
  }
  if ($LASTEXITCODE) { throw "reason-network exited with code $LASTEXITCODE" }
} @args
