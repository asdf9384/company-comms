#!/bin/sh
# tincan is now Reason Network (https://github.com/reason-machines/reason-network): this installs reason-network,
# no account needed. On a machine that has tincan (tincan's updater runs this), it also leaves a copy under the old
# name, which runs as reason-network: that moves the team, the agents and the background service over.
#
#   curl -fsSL <this url> | sh                      install, then set up (start or join a team)
#   curl -fsSL <this url> | sh -s -- <team link>    install, then join that team
#   curl -fsSL <this url> | sh -s -- <team link> --as <name>     the same, without questions (for agents)
#   curl -fsSL <this url> | sh -s -- init <team> --as <name>     install and start a team, without questions
#
# Environment: TINCAN_BIN_DIR (default ~/.local/bin), TINCAN_NO_PROMPT (never ask anything: updates),
# REASON_NETWORK_VERSION (default latest).
set -eu

bin_dir="${TINCAN_BIN_DIR:-$HOME/.local/bin}"
releases="https://github.com/reason-machines/reason-network/releases"
case "${REASON_NETWORK_VERSION:-latest}" in
  latest) script="$releases/latest/download/install.sh" ;;
  *) script="$releases/download/$REASON_NETWORK_VERSION/install.sh" ;;
esac

say() { printf '%s\n' "$*"; }
die() { say "tincan install: $*; tincan is unchanged" >&2; exit 1; }
say "tincan is now Reason Network: installing reason-network."
installer="$(curl -fsSL "$script")" || die "couldn't download reason-network's installer ($script)"
printf '%s\n' "$installer" | REASON_NETWORK_BIN_DIR="$bin_dir" REASON_NETWORK_NO_PROMPT=1 sh || die "installing reason-network failed"
[ -x "$bin_dir/reason-network" ] || die "reason-network isn't in $bin_dir"
if [ -e "$bin_dir/tincan" ]; then
  # A new file renamed into place: never a moment without tincan, and never the old one changed in place (macOS kills a
  # signed binary changed in place).
  cp "$bin_dir/reason-network" "$bin_dir/.tincan.new" && chmod 755 "$bin_dir/.tincan.new" &&
    mv -f "$bin_dir/.tincan.new" "$bin_dir/tincan" || { rm -f "$bin_dir/.tincan.new"; die "couldn't put the copy in place"; }
fi

if [ -z "${TINCAN_NO_PROMPT:-}" ] && (exec </dev/tty) 2>/dev/null; then
  case "${1:-}" in
    "") exec "$bin_dir/reason-network" </dev/tty ;;
    -*|init|join|setup) exec "$bin_dir/reason-network" "$@" </dev/tty ;;
    *) exec "$bin_dir/reason-network" join "$@" </dev/tty ;;
  esac
fi
case "${1:-}" in
  "") ;;
  -*|init|join|setup) exec "$bin_dir/reason-network" "$@" ;;
  *) exec "$bin_dir/reason-network" join "$@" ;;
esac
