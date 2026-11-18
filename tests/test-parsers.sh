#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# Source the application functions without launching the interactive menu.
# shellcheck source=../linux-catalog.sh
source "$ROOT/linux-catalog.sh"
APP_LANG='en'; load_language 'en'

fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }
pass() { printf 'PASS: %s\n' "$1"; }

# Multi-word app names must not degrade to a generic first word.
[[ "$(search_term_for_app 'Trilium Notes')" == 'trilium-notes' ]] || fail 'normalized fallback search term'
[[ "$(search_term_for_app 'LibreOffice Draw')" == 'libreoffice-draw' ]] || fail 'curated LibreOffice Draw hint'
pass 'application search terms'

# Flatpak: explicit columns are essential because the default table includes
# a human-readable description before the application ID.
flatpak() {
  [[ "$1" == 'search' && "$2" == '--columns=application,remotes' && "$3" == 'firefox' ]] || return 97
  printf 'Application ID  Remotes\n'
  printf 'org.mozilla.firefox  flathub\n'
  printf 'org.mozilla.firefox.beta  flathub, flathub-beta\n'
}
CAND_SOURCE=(); CAND_PACKAGE=(); CAND_DESC=(); CAND_REMOTE=()
search_flatpak firefox
[[ "${#CAND_PACKAGE[@]}" == 2 ]] || fail 'Flatpak parser candidate count'
[[ "${CAND_PACKAGE[0]}" == 'org.mozilla.firefox' ]] || fail 'Flatpak parser application ID'
[[ "${CAND_REMOTE[0]}" == 'flathub' ]] || fail 'Flatpak parser remote'
[[ "${CAND_REMOTE[1]}" == 'flathub' ]] || fail 'Flatpak parser chooses first remote'
pass 'Flatpak search output parsing'

# eopkg uses one result per line: package-name - description.
eopkg() {
  [[ "$1" == '--no-color' && "$2" == 'search' && "$3" == '--name' && "$4" == 'firefox' ]] || return 97
  printf 'firefox-esr - Mozilla Firefox Extended Support Release\n'
}
CAND_SOURCE=(); CAND_PACKAGE=(); CAND_DESC=(); CAND_REMOTE=()
search_eopkg firefox
[[ "${#CAND_PACKAGE[@]}" == 1 ]] || fail 'eopkg parser candidate count'
[[ "${CAND_PACKAGE[0]}" == 'firefox-esr' ]] || fail 'eopkg parser package name'
[[ "${CAND_DESC[0]}" == 'Mozilla Firefox Extended Support Release' ]] || fail 'eopkg parser description'
pass 'eopkg search output parsing'

# Package names may themselves contain hyphen-number fragments. Split the
# version suffix at the last version separator, not the first one.
apk() {
  [[ "$1" == 'search' && "$2" == '-v' && "$3" == 'sample' ]] || return 97
  printf 'my-tool-2-1.3.0-r0 - Example package\n'
}
CAND_SOURCE=(); CAND_PACKAGE=(); CAND_DESC=(); CAND_REMOTE=()
search_apk sample
[[ "${CAND_PACKAGE[0]:-}" == 'my-tool-2' ]] || fail 'APK package/version split'
pass 'APK package name parsing'

xbps-query() {
  [[ "$1" == '-R' && "$2" == '-s' && "$3" == 'sample' ]] || return 97
  printf 'my-tool-2-1.3.0_1 Example package\n'
  printf 'firefox-esr-140.2.0_1 Mozilla Firefox ESR\n'
}
CAND_SOURCE=(); CAND_PACKAGE=(); CAND_DESC=(); CAND_REMOTE=()
search_xbps sample
[[ "${CAND_PACKAGE[0]:-}" == 'my-tool-2' ]] || fail 'XBPS package/version split'
[[ "${CAND_PACKAGE[1]:-}" == 'firefox-esr' ]] || fail 'XBPS package name with multi-part version'
pass 'XBPS package name parsing'

# DNF/DNF5 output is package.arch : summary; the architecture suffix must not
# be passed to the installer as part of the package name.
dnf() {
  [[ "$1" == '-q' && "$2" == 'search' && "$3" == '--all' && "$4" == 'sample' ]] || return 97
  printf 'firefox.x86_64 : Mozilla Firefox web browser\n'
}
CAND_SOURCE=(); CAND_PACKAGE=(); CAND_DESC=(); CAND_REMOTE=()
search_dnf_like dnf sample
[[ "${CAND_PACKAGE[0]:-}" == 'firefox' ]] || fail 'DNF architecture suffix parsing'
pass 'DNF package result parsing'

dnf5() {
  [[ "$1" == '-q' && "$2" == 'search' && "$3" == '--all' && "$4" == 'sample' ]] || return 97
  printf 'firefox.x86_64 : Mozilla Firefox web browser\n'
}
CAND_SOURCE=(); CAND_PACKAGE=(); CAND_DESC=(); CAND_REMOTE=()
search_dnf_like dnf5 sample
[[ "${CAND_SOURCE[0]:-}" == 'dnf5' && "${CAND_PACKAGE[0]:-}" == 'firefox' ]] || fail 'DNF5 package result parsing'
pass 'DNF5 package result parsing'

pacman() {
  [[ "$1" == '-Ss' && "$2" == 'sample' ]] || return 97
  printf 'extra/firefox 145.0-1 (extra)\n    Mozilla Firefox web browser\n'
}
CAND_SOURCE=(); CAND_PACKAGE=(); CAND_DESC=(); CAND_REMOTE=()
search_pacman sample
[[ "${CAND_PACKAGE[0]:-}" == 'firefox' ]] || fail 'Pacman package result parsing'
pass 'Pacman package result parsing'

zypper() {
  [[ "$1" == '--no-refresh' && "$2" == '--non-interactive' && "$3" == 'search' ]] || return 97
  printf 'S | Name    | Summary                 | Type    | Repository\n'
  printf '--+---------+-------------------------+---------+----------\n'
  printf '  | firefox | Mozilla Firefox browser | package | repo\n'
}
CAND_SOURCE=(); CAND_PACKAGE=(); CAND_DESC=(); CAND_REMOTE=()
search_zypper sample
[[ "${CAND_PACKAGE[0]:-}" == 'firefox' ]] || fail 'Zypper package result parsing'
pass 'Zypper package result parsing'

emerge() {
  [[ "$1" == '--search' && "$2" == 'sample' ]] || return 97
  printf '*  www-client/firefox [ Masked ]\n'
}
CAND_SOURCE=(); CAND_PACKAGE=(); CAND_DESC=(); CAND_REMOTE=()
search_emerge sample
[[ "${CAND_PACKAGE[0]:-}" == 'www-client/firefox' ]] || fail 'Portage package result parsing'
pass 'Portage package result parsing'

snap() {
  [[ "$1" == 'find' && "$2" == 'sample' ]] || return 97
  printf 'Name      Version   Publisher  Notes\n'
  printf 'firefox   145.0     mozilla    -\n'
}
CAND_SOURCE=(); CAND_PACKAGE=(); CAND_DESC=(); CAND_REMOTE=()
search_snap sample
[[ "${CAND_PACKAGE[0]:-}" == 'firefox' ]] || fail 'Snap package result parsing'
pass 'Snap package result parsing'

# Exercise every installation dispatch using shell-function stubs. No system
# package manager is run and no software is installed by these tests.
export TEST_INSTALL_LOG="$(mktemp)"
trap 'rm -f "$TEST_INSTALL_LOG"' EXIT
# The first argument is the command label; remove it before serializing args.
record_call() { local label="$1"; shift; printf '%s %s\n' "$label" "$*" >> "$TEST_INSTALL_LOG"; }
sudo() { shift; "$@"; }
apt-get() { record_call apt-get "$@"; }
dnf() { record_call dnf "$@"; }
dnf5() { record_call dnf5 "$@"; }
yum() { record_call yum "$@"; }
pacman() { record_call pacman "$@"; }
zypper() { record_call zypper "$@"; }
apk() {
  if [[ "$1" == 'add' ]]; then record_call apk "$@"; else return 97; fi
}
xbps-install() { record_call xbps-install "$@"; }
eopkg() {
  if [[ "$1" == 'install' ]]; then record_call eopkg "$@"; else return 97; fi
}
emerge() { record_call emerge "$@"; }
flatpak() {
  if [[ "$1" == 'install' ]]; then record_call flatpak "$@"; else return 97; fi
}
SNAP_CONFINEMENT='classic'
snap() {
  if [[ "${1:-}" == 'info' ]]; then
    printf 'name: test-snap\nconfinement: %s\n' "$SNAP_CONFINEMENT"
  else
    record_call snap "$@"
  fi
}

assert_install_call() {
  local source="$1" package="$2" remote="$3" expected="$4" actual
  CAND_SOURCE=("$source"); CAND_PACKAGE=("$package"); CAND_DESC=('test'); CAND_REMOTE=("$remote")
  : > "$TEST_INSTALL_LOG"
  install_candidate 0 <<< 'y' >/dev/null
  actual="$(cat "$TEST_INSTALL_LOG")"
  [[ "$actual" == "$expected" ]] || fail "$source install dispatch (got: $actual; expected: $expected)"
}
SELECTED_APP='Test application'
assert_install_call apt firefox-esr '' 'apt-get install -- firefox-esr'
assert_install_call dnf firefox '' 'dnf install firefox'
assert_install_call dnf5 firefox '' 'dnf5 install firefox'
assert_install_call yum firefox '' 'yum install firefox'
assert_install_call pacman firefox '' 'pacman -S --needed firefox'
assert_install_call zypper firefox '' 'zypper install firefox'
assert_install_call apk firefox '' 'apk add firefox'
assert_install_call xbps firefox '' 'xbps-install -S firefox'
assert_install_call eopkg firefox '' 'eopkg install firefox'
assert_install_call emerge www-client/firefox '' 'emerge --ask www-client/firefox'
assert_install_call flatpak org.mozilla.firefox flathub 'flatpak install flathub org.mozilla.firefox'
assert_install_call snap code '' 'snap install --classic code'
pass 'installation command dispatch for all supported backends'

# A devmode Snap is intentionally blocked instead of silently weakening its
# confinement. The user can choose a different source for that application.
SNAP_CONFINEMENT='devmode'
: > "$TEST_INSTALL_LOG"
CAND_SOURCE=(snap); CAND_PACKAGE=(unsafe-demo); CAND_DESC=('test'); CAND_REMOTE=('')
snap_test_output="$(mktemp)"
if install_candidate 0 <<< 'y' > "$snap_test_output"; then
  rm -f "$snap_test_output"
  fail 'devmode Snap should be blocked'
else
  status=$?
  [[ "$status" == 2 ]] || fail "devmode Snap exit status (got $status)"
fi
grep -q 'devmode' "$snap_test_output" || fail 'devmode warning message'
rm -f "$snap_test_output"
[[ ! -s "$TEST_INSTALL_LOG" ]] || fail 'devmode Snap was installed unexpectedly'
pass 'Snap devmode safety guard'

printf '\nAll parser and backend tests passed.\n'
