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
  $env:REASON_NETWORK_BIN_DIR = $bin
  $env:REASON_NETWORK_NO_PROMPT = '1'
  try { & ([scriptblock]::Create((Invoke-RestMethod -UseBasicParsing $script))) } finally {
    Remove-Item Env:REASON_NETWORK_BIN_DIR, Env:REASON_NETWORK_NO_PROMPT -ErrorAction SilentlyContinue
  }
  $exe = Join-Path $bin 'reason-network.exe'
  $old = Join-Path $bin 'tincan.exe'
  if (Test-Path $old) {
    # A running tincan.exe can't be replaced, but it can be renamed: move it aside, and delete the ones set aside
    # before once nothing runs them.
    Get-ChildItem $bin -Filter 'tincan.*.old' | Remove-Item -Force -ErrorAction SilentlyContinue
    Move-Item $old (Join-Path $bin "tincan.$(Get-Random).old")
    Copy-Item $exe $old
  }

  if ($args.Count -eq 0) {
    if ($env:TINCAN_NO_PROMPT -or [Console]::IsInputRedirected) {
      if (-not $env:TINCAN_NO_PROMPT) { Write-Host ''; Write-Host 'Next, in a terminal: reason-network' }
      return
    }
    & $exe
  } elseif ($args[0] -match '^(-.*|init|join|setup)$') {
    & $exe @args
  } else {
    & $exe join @args
  }
  if ($LASTEXITCODE) { throw "reason-network exited with code $LASTEXITCODE" }
} @args
