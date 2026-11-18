#!/usr/bin/env bash
# Dkariio Linux App Catalog — terminal application catalog and installer.
# Copyright (c) 2026 @dkariio
set -Eeuo pipefail

APP_VERSION='1.0.1'
APP_ID='dkariio-linux-app-catalog'
PROJECT_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$PROJECT_DIR/catalog/apps.tsv" ]]; then
  DATA_DIR="$PROJECT_DIR"
elif [[ -f "$PROJECT_DIR/../share/$APP_ID/catalog/apps.tsv" ]]; then
  DATA_DIR="$PROJECT_DIR/../share/$APP_ID"
elif [[ -f "/usr/local/share/$APP_ID/catalog/apps.tsv" ]]; then
  DATA_DIR="/usr/local/share/$APP_ID"
elif [[ -f "/usr/share/$APP_ID/catalog/apps.tsv" ]]; then
  DATA_DIR="/usr/share/$APP_ID"
else
  printf 'Catalog data not found. Run from the source folder or reinstall the application.\n' >&2
  exit 1
fi

APPS_FILE="$DATA_DIR/catalog/apps.tsv"
CATEGORIES_FILE="$DATA_DIR/catalog/categories.tsv"
HINTS_FILE="$DATA_DIR/catalog/search-hints.tsv"
CONFIG_HOME="${XDG_CONFIG_HOME:-${HOME:-/tmp}/.config}/$APP_ID"
LANG_FILE="$CONFIG_HOME/language"
APP_LANG=''
COLOR=0
if [[ -t 1 && "${TERM:-dumb}" != 'dumb' && -z "${NO_COLOR:-}" ]]; then COLOR=1; fi

PRETTY_NAME=''
if [[ -r /etc/os-release ]]; then
  # shellcheck disable=SC1091
  source /etc/os-release
fi

if [[ -r "$LANG_FILE" ]]; then
  IFS= read -r APP_LANG < "$LANG_FILE" || true
fi
if [[ ! "$APP_LANG" =~ ^(es|en|ru)$ ]]; then
  case "${LANG:-en}" in es*) APP_LANG='es' ;; ru*) APP_LANG='ru' ;; *) APP_LANG='en' ;; esac
fi

# Load language strings. The locale files only define the msg() lookup function.
load_language() {
  local lang="$1"
  case "$lang" in
    es)
      # shellcheck disable=SC1090,SC1091
      source "$DATA_DIR/locales/es.sh"
      ;;
    ru)
      # shellcheck disable=SC1090,SC1091
      source "$DATA_DIR/locales/ru.sh"
      ;;
    *)
      # shellcheck disable=SC1090,SC1091
      source "$DATA_DIR/locales/en.sh"
      ;;
  esac
}
load_language "$APP_LANG"

if (( COLOR )); then
  C_RESET=$'\033[0m'; C_BOLD=$'\033[1m'; C_DIM=$'\033[2m'
  C_CYAN=$'\033[96m'; C_GREEN=$'\033[92m'
  C_RED=$'\033[91m'; C_MAGENTA=$'\033[95m'
else
  C_RESET=''; C_BOLD=''; C_DIM=''; C_CYAN=''
  C_GREEN=''; C_RED=''; C_MAGENTA=''
fi

APP_IDS=(); APP_CATS=(); APP_NAMES=()
CAT_IDS=(); CAT_ES=(); CAT_EN=(); CAT_RU=()
RESULT_IDS=(); CAND_SOURCE=(); CAND_PACKAGE=(); CAND_DESC=(); CAND_REMOTE=()
SELECTED_APP=''; PAGE_SIZE=18

load_catalog() {
  local id cat name
  while IFS=$'\t' read -r id cat name; do
    [[ -n "$id" && -n "$cat" && -n "$name" ]] || continue
    APP_IDS+=("$id"); APP_CATS+=("$cat"); APP_NAMES+=("$name")
  done < "$APPS_FILE"
  local es en ru
  while IFS=$'\t' read -r id es en ru; do
    [[ -n "$id" && -n "$es" ]] || continue
    CAT_IDS+=("$id"); CAT_ES+=("$es"); CAT_EN+=("$en"); CAT_RU+=("$ru")
  done < "$CATEGORIES_FILE"
}
load_catalog

category_label() {
  local wanted="$1" i
  for i in "${!CAT_IDS[@]}"; do
    if [[ "${CAT_IDS[$i]}" == "$wanted" ]]; then
      case "$APP_LANG" in
        es) printf '%s' "${CAT_ES[$i]}" ;;
        ru) printf '%s' "${CAT_RU[$i]}" ;;
        *)  printf '%s' "${CAT_EN[$i]}" ;;
      esac
      return 0
    fi
  done
  printf '%s' "$wanted"
}

clear_screen() {
  if [[ -t 1 && "${TERM:-dumb}" != 'dumb' ]] && command -v tput >/dev/null 2>&1; then
    tput clear 2>/dev/null || printf '\n\n'
  else
    printf '\n\n'
  fi
}

header() {
  local subtitle="${1:-}"
  printf '%s╭──────────────────────────────────────────────────────────────╮%s\n' "$C_CYAN" "$C_RESET"
  printf '%s│%s  %s🐧 Dkariio Linux App Catalog%s  %s%-24s%s %s│%s\n' \
    "$C_CYAN" "$C_RESET" "$C_BOLD" "$C_RESET" "$C_DIM" "v$APP_VERSION" "$C_RESET" "$C_CYAN" "$C_RESET"
  printf '%s│%s  %s @dkariio · Instagram%s                                   %s│%s\n' \
    "$C_CYAN" "$C_RESET" "$C_MAGENTA" "$C_RESET" "$C_CYAN" "$C_RESET"
  printf '%s╰──────────────────────────────────────────────────────────────╯%s\n' "$C_CYAN" "$C_RESET"
  [[ -n "$subtitle" ]] && printf '\n%s%s%s\n' "$C_BOLD" "$subtitle" "$C_RESET"
}

pause() {
  printf '\n%s' "$(msg pause)"
  read -r -n 1 -s _ || true
  printf '\n'
}

print_catalog_summary() {
  printf '%s  %s%s %s\n' "$C_DIM" "$(msg catalog_entries)" "${#APP_IDS[@]}" "$(msg programs)"
  printf '  %s%s %s\n' "$(msg categories_count)" "${#CAT_IDS[@]}" "$(msg categories_word)"
}

show_main_menu() {
  clear_screen
  header "$(msg tagline)"
  print_catalog_summary
  printf '\n  %s1)%s %s\n' "$C_GREEN" "$C_RESET" "$(msg browse_categories)"
  printf '  %s2)%s %s\n' "$C_GREEN" "$C_RESET" "$(msg search_catalog)"
  printf '  %s3)%s %s\n' "$C_GREEN" "$C_RESET" "$(msg change_language)"
  printf '  %s4)%s %s\n' "$C_GREEN" "$C_RESET" "$(msg system_diagnostics)"
  printf '  %s5)%s %s\n' "$C_GREEN" "$C_RESET" "$(msg about)"
  printf '  %s0)%s %s\n' "$C_RED" "$C_RESET" "$(msg exit)"
  printf '\n%s' "$(msg choose_option)"
}

browse_categories() {
  local choice idx
  while true; do
    clear_screen; header "$(msg categories_title)"
    for idx in "${!CAT_IDS[@]}"; do
      printf '  %2d) %s\n' "$((idx+1))" "$(category_label "${CAT_IDS[$idx]}")"
    done
    printf '\n  b) %s\n' "$(msg back)"
    printf '\n%s' "$(msg choose_category)"
    read -r choice || return 0
    [[ "$choice" == 'b' || "$choice" == 'B' ]] && return
    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#CAT_IDS[@]} )); then
      build_category_results "${CAT_IDS[$((choice-1))]}"
      browse_results "$(category_label "${CAT_IDS[$((choice-1))]}")"
    else
      printf '%s\n' "$(msg invalid_choice)"; pause
    fi
  done
}

build_category_results() {
  local category="$1" i
  RESULT_IDS=()
  for i in "${!APP_IDS[@]}"; do
    [[ "${APP_CATS[$i]}" == "$category" ]] && RESULT_IDS+=("${APP_IDS[$i]}")
  done
  return 0
}

build_search_results() {
  local query="$1" i hay
  RESULT_IDS=()
  query="${query,,}"
  for i in "${!APP_IDS[@]}"; do
    hay="${APP_NAMES[$i],,}"
    if [[ "$hay" == *"$query"* ]]; then RESULT_IDS+=("${APP_IDS[$i]}"); fi
  done
  return 0
}

app_index_from_id() {
  local wanted="$1" i
  for i in "${!APP_IDS[@]}"; do
    if [[ "${APP_IDS[$i]}" == "$wanted" ]]; then printf '%s' "$i"; return 0; fi
  done
  return 1
}

browse_results() {
  local title="$1" page=0 pages start end i id app_index choice selected
  local total=${#RESULT_IDS[@]}
  (( total == 0 )) && { printf '\n%s\n' "$(msg no_catalog_results)"; pause; return; }
  pages=$(((total + PAGE_SIZE - 1) / PAGE_SIZE))
  while true; do
    clear_screen; header "$title"
    printf '%s\n' "$(msg results_count) $total"
    start=$((page * PAGE_SIZE)); end=$((start + PAGE_SIZE)); (( end > total )) && end=$total
    for ((i=start; i<end; i++)); do
      id="${RESULT_IDS[$i]}"; app_index="$(app_index_from_id "$id")"
      printf '  %2d) %s\n' "$((i-start+1))" "${APP_NAMES[$app_index]}"
    done
    printf '\n  n) %s' "$(msg next_page)"
    printf '   p) %s' "$(msg previous_page)"
    printf '   b) %s\n' "$(msg back)"
    printf '\n%s' "$(msg choose_program)"
    read -r choice || return 0
    case "${choice,,}" in
      b|q) return ;;
      n) (( page + 1 < pages )) && ((page+=1)) || { printf '%s\n' "$(msg last_page)"; pause; } ;;
      p) if (( page > 0 )); then page=$((page-1)); else printf '%s\n' "$(msg first_page)"; pause; fi ;;
      *)
        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= end-start )); then
          selected=$((start + choice - 1)); id="${RESULT_IDS[$selected]}"
          app_index="$(app_index_from_id "$id")"
          install_flow "${APP_NAMES[$app_index]}"
        else
          printf '%s\n' "$(msg invalid_choice)"; pause
        fi
        ;;
    esac
  done
}

search_menu() {
  local query
  clear_screen; header "$(msg search_title)"
  printf '%s' "$(msg enter_search_term)"
  IFS= read -r query || return 0
  [[ -z "${query//[[:space:]]/}" ]] && return
  build_search_results "$query"
  browse_results "$(msg search_results_for) '$query'"
}

change_language() {
  local choice
  clear_screen; header "$(msg language_title)"
  printf '  1) Español\n  2) English\n  3) Русский\n\n%s' "$(msg choose_option)"
  read -r choice || return 0
  case "$choice" in
    1) APP_LANG='es' ;; 2) APP_LANG='en' ;; 3) APP_LANG='ru' ;;
    *) printf '%s\n' "$(msg invalid_choice)"; pause; return ;;
  esac
  mkdir -p "$CONFIG_HOME"
  printf '%s\n' "$APP_LANG" > "$LANG_FILE"
  load_language "$APP_LANG"
  printf '%s\n' "$(msg language_saved)"
  pause
}

system_diagnostics() {
  clear_screen; header "$(msg diagnostics_title)"
  printf '%s\n' "$(msg os_detected): ${PRETTY_NAME:-$(uname -s)}"
  printf '%s\n' "$(msg architecture): $(uname -m)"
  printf '\n%s\n' "$(msg package_managers)"
  local found=0 cmd
  for cmd in apt-get dnf dnf5 yum pacman zypper apk xbps-install eopkg emerge flatpak snap; do
    if command -v "$cmd" >/dev/null 2>&1; then
      printf '  %s✓%s %s\n' "$C_GREEN" "$C_RESET" "$cmd"; found=1
    fi
  done
  (( found )) || printf '  %s\n' "$(msg no_manager_found)"
  printf '\n%s\n' "$(msg optional_tools)"
  for cmd in sudo dialog whiptail fzf; do
    if command -v "$cmd" >/dev/null 2>&1; then printf '  ✓ %s\n' "$cmd"; else printf '  - %s\n' "$cmd"; fi
  done
  printf '\n%s\n' "$(msg safe_install_notice)"
  [[ "${1:-}" == '--noninteractive' ]] || pause
}

about_screen() {
  clear_screen; header "$(msg about)"
  printf '%s\n\n' "$(msg about_text)"
  printf '%s\n' "$(msg about_license)"
  pause
}

# Package discovery helpers. Output candidates are always stored as data, never eval'ed.
valid_native_package() {
  [[ "$1" =~ ^[A-Za-z0-9][A-Za-z0-9._+:-]*$ ]]
}
valid_flatpak_id() {
  [[ "$1" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*\.[A-Za-z0-9._-]+$ ]]
}

candidate_add() {
  local source="$1" package="$2" description="${3:-}" remote="${4:-}" i
  [[ -n "$package" ]] || return 0
  if [[ "$source" == 'flatpak' ]]; then
    valid_flatpak_id "$package" || return 0
    [[ -n "$remote" && "$remote" =~ ^[A-Za-z0-9_.-]+$ ]] || return 0
  elif [[ "$source" == 'emerge' ]]; then
    [[ "$package" =~ ^[A-Za-z0-9+_.-]+/[A-Za-z0-9+_.-]+$ ]] || return 0
  else
    valid_native_package "$package" || return 0
  fi
  for i in "${!CAND_SOURCE[@]}"; do
    [[ "${CAND_SOURCE[$i]}" == "$source" && "${CAND_PACKAGE[$i]}" == "$package" && "${CAND_REMOTE[$i]}" == "$remote" ]] && return 0
  done
  (( ${#CAND_SOURCE[@]} < 60 )) || return 0
  CAND_SOURCE+=("$source"); CAND_PACKAGE+=("$package"); CAND_DESC+=("${description:0:110}"); CAND_REMOTE+=("$remote")
}

search_term_for_app() {
  local app="$1" hint
  if [[ -f "$HINTS_FILE" ]]; then
    hint="$(awk -F '\t' -v name="$app" 'tolower($1)==tolower(name){print $2; exit}' "$HINTS_FILE")"
    if [[ -n "$hint" ]]; then printf '%s' "$hint"; return; fi
  fi
  app="${app,,}"
  app="${app#gnu }"; app="${app#gnome }"; app="${app#kde }"
  app="${app#apache }"; app="${app#microsoft }"; app="${app#google }"
  app="${app#the }"; app="${app#mozilla }"
  # Use the complete normalized name rather than only its first word. The
  # previous fallback searched for generic tokens such as "visual" or "web",
  # which often returned unrelated packages. A slug is a safer search seed;
  # explicit exceptions belong in catalog/search-hints.tsv.
  app="${app//[^a-z0-9+._ -]/ }"
  app="${app//[[:space:]]/-}"
  while [[ "$app" == *--* ]]; do app="${app//--/-}"; done
  app="${app#-}"; app="${app%-}"
  printf '%s' "$app"
}

trim_text() { sed 's/^[[:space:]]*//; s/[[:space:]]*$//'; }

search_apt() {
  local term="$1" line pkg desc
  while IFS= read -r line; do
    [[ "$line" == *' - '* ]] || continue
    pkg="${line%% - *}"; desc="${line#* - }"
    candidate_add 'apt' "$pkg" "$desc"
  done < <(apt-cache search --names-only "$term" 2>/dev/null || true)
}

search_dnf_like() {
  local manager="$1" term="$2" line left desc pkg
  while IFS= read -r line; do
    [[ "$line" == *:* ]] || continue
    [[ "$line" == *'Matched:'* ]] && continue
    left="${line%%:*}"; left="${left//[[:space:]]/}"
    [[ "$left" =~ ^[A-Za-z0-9][A-Za-z0-9._+:-]*$ ]] || continue
    pkg="$left"
    pkg="$(printf '%s' "$pkg" | sed -E 's/\.(x86_64|aarch64|i686|i586|noarch|ppc64le|s390x|armv7hl|src)$//')"
    desc="${line#*:}"; desc="$(printf '%s' "$desc" | trim_text)"
    candidate_add "$manager" "$pkg" "$desc"
  done < <("$manager" -q search --all "$term" 2>/dev/null || "$manager" -q search "$term" 2>/dev/null || true)
}

search_pacman() {
  local term="$1" line spec pkg
  while IFS= read -r line; do
    if [[ "$line" =~ ^[^[:space:]]+/[^[:space:]]+ ]]; then
      spec="${line%%[[:space:]]*}"; pkg="${spec##*/}"
      candidate_add 'pacman' "$pkg" "$spec"
    fi
  done < <(pacman -Ss "$term" 2>/dev/null || true)
}

search_zypper() {
  local term="$1" line pkg summary
  local -a columns
  while IFS= read -r line; do
    [[ "$line" == *'|'* ]] || continue
    IFS='|' read -r -a columns <<< "$line"
    pkg="$(printf '%s' "${columns[1]:-}" | trim_text)"
    summary="$(printf '%s' "${columns[2]:-}" | trim_text)"
    [[ "$pkg" == 'Name' || "$pkg" == '---' || -z "$pkg" ]] && continue
    candidate_add 'zypper' "$pkg" "$summary"
  done < <(zypper --no-refresh --non-interactive search --type package "$term" 2>/dev/null || true)
}

search_apk() {
  local term="$1" line pkg desc
  while IFS= read -r line; do
    [[ "$line" == ERROR* || "$line" == WARNING* || -z "$line" ]] && continue
    pkg="${line%%[[:space:]]*}"
    # APK versions are split at the last "-<digit>" separator. Keep earlier
    # hyphen-number portions because they may be part of the package name.
    pkg="$(printf '%s' "$pkg" | sed -E 's/^(.*)-[0-9][A-Za-z0-9.+_~:-]*$/\1/')"
    desc=''
    [[ "$line" == *' - '* ]] && desc="${line#* - }"
    candidate_add 'apk' "$pkg" "$desc"
  done < <(apk search -v "$term" 2>/dev/null || apk search "$term" 2>/dev/null || true)
}

search_xbps() {
  local term="$1" line first pkg desc
  while IFS= read -r line; do
    first="${line%%[[:space:]]*}"
    first="${first#\[-\]}"
    first="${first#\[\*\]}"
    first="${first#\[?\]}"
    first="$(printf '%s' "$first" | trim_text)"
    [[ -n "$first" ]] || continue
    # XBPS results are pkgver strings (name-version); split at the last
    # version separator so names containing hyphenated numbers survive.
    pkg="$(printf '%s\n' "$first" | sed -E 's/^(.*)-[0-9][^ ]*$/\1/')"
    desc="${line#* }"
    candidate_add 'xbps' "$pkg" "$desc"
  done < <(xbps-query -R -s "$term" 2>/dev/null || true)
}

search_eopkg() {
  local term="$1" line pkg desc
  while IFS= read -r line; do
    # eopkg search prints one result per line as: package-name - description.
    # Older releases may not support --name, so retry the broader search.
    if [[ "$line" =~ ^([^[:space:]]+)[[:space:]]+-[[:space:]]+(.+)$ ]]; then
      pkg="${BASH_REMATCH[1]}"; desc="${BASH_REMATCH[2]}"
      candidate_add 'eopkg' "$pkg" "$desc"
    fi
  done < <(eopkg --no-color search --name "$term" 2>/dev/null || eopkg --no-color search "$term" 2>/dev/null || true)
}

search_emerge() {
  local term="$1" line pkg
  while IFS= read -r line; do
    if [[ "$line" =~ ^\*[[:space:]]+([A-Za-z0-9+_.-]+/[A-Za-z0-9+_.-]+) ]]; then
      pkg="${BASH_REMATCH[1]}"; candidate_add 'emerge' "$pkg" ''
    fi
  done < <(emerge --search "$term" 2>/dev/null || true)
}

search_flatpak() {
  local term="$1" line pkg remotes remote
  while IFS= read -r line; do
    [[ -z "$line" || "$line" == *'---'* ]] && continue
    [[ "$line" =~ ^[[:space:]]*Application[[:space:]]+Remotes([[:space:]]|$) ]] && continue
    # Request only stable machine-relevant columns. Parsing Flatpak's default
    # table used to mistake the description for the app ID.
    read -r pkg remotes _ <<< "$line"
    [[ -n "$pkg" && -n "$remotes" ]] || continue
    # If multiple remotes are listed, use the first one shown by Flatpak.
    remote="${remotes%%,*}"
    remote="${remote%,}"
    candidate_add 'flatpak' "$pkg" 'Flatpak application' "$remote"
  done < <(flatpak search --columns=application,remotes "$term" 2>/dev/null || true)
}

search_snap() {
  local term="$1" line pkg
  while IFS= read -r line; do
    [[ "$line" =~ ^Name[[:space:]] ]] && continue
    [[ "$line" =~ ^No[[:space:]] || "$line" =~ ^error: ]] && continue
    [[ "$line" =~ ^-+[[:space:]] ]] && continue
    pkg="${line%%[[:space:]]*}"
    candidate_add 'snap' "$pkg" "${line#*  }"
  done < <(snap find "$term" 2>/dev/null || true)
}

discover_candidates() {
  local app="$1" term
  CAND_SOURCE=(); CAND_PACKAGE=(); CAND_DESC=(); CAND_REMOTE=()
  term="$(search_term_for_app "$app")"
  [[ -n "$term" ]] || return 0
  printf '%s\n' "$(msg searching_repositories) '$term'" >&2
  if command -v apt-cache >/dev/null 2>&1 && command -v apt-get >/dev/null 2>&1; then search_apt "$term"; fi
  if command -v dnf >/dev/null 2>&1; then search_dnf_like dnf "$term"; elif command -v dnf5 >/dev/null 2>&1; then search_dnf_like dnf5 "$term"; fi
  if command -v yum >/dev/null 2>&1 && ! command -v dnf >/dev/null 2>&1; then search_dnf_like yum "$term"; fi
  if command -v pacman >/dev/null 2>&1; then search_pacman "$term"; fi
  if command -v zypper >/dev/null 2>&1; then search_zypper "$term"; fi
  if command -v apk >/dev/null 2>&1; then search_apk "$term"; fi
  if command -v xbps-query >/dev/null 2>&1; then search_xbps "$term"; fi
  if command -v eopkg >/dev/null 2>&1; then search_eopkg "$term"; fi
  if command -v emerge >/dev/null 2>&1; then search_emerge "$term"; fi
  if command -v flatpak >/dev/null 2>&1; then search_flatpak "$term"; fi
  if command -v snap >/dev/null 2>&1; then search_snap "$term"; fi
}

source_label() {
  case "$1" in
    apt) printf 'APT / DEB' ;; dnf) printf 'DNF / RPM' ;; dnf5) printf 'DNF5 / RPM' ;; yum) printf 'YUM / RPM' ;;
    pacman) printf 'Pacman' ;; zypper) printf 'Zypper / RPM' ;; apk) printf 'APK' ;;
    xbps) printf 'XBPS' ;; eopkg) printf 'eopkg / Solus' ;; emerge) printf 'Portage / Gentoo' ;; flatpak) printf 'Flatpak' ;; snap) printf 'Snap' ;;
    *) printf '%s' "$1" ;;
  esac
}

run_privileged() {
  if (( EUID == 0 )); then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo -- "$@"
  else
    printf '%s\n' "$(msg sudo_missing)" >&2
    return 127
  fi
}

install_candidate() {
  local source="${CAND_SOURCE[$1]}" package="${CAND_PACKAGE[$1]}" remote="${CAND_REMOTE[$1]}" result
  printf '\n%s%s%s\n' "$C_BOLD" "$(msg install_confirmation)" "$C_RESET"
  printf '  %s: %s\n' "$(msg application)" "$SELECTED_APP"
  printf '  %s: %s\n' "$(msg source)" "$(source_label "$source")"
  if [[ "$source" == 'flatpak' ]]; then
    printf '  %s: %s (%s)\n' "$(msg package_id)" "$package" "$remote"
  else
    printf '  %s: %s\n' "$(msg package_id)" "$package"
  fi
  printf '\n%s' "$(msg confirm_yes_no)"
  local answer; read -r answer || return 0
  [[ "${answer,,}" == 'y' || "${answer,,}" == 's' || "${answer,,}" == 'д' ]] || { printf '%s\n' "$(msg cancelled)"; return; }
  printf '\n%s\n' "$(msg running_install)"
  case "$source" in
    apt) run_privileged apt-get install -- "$package" ;;
    dnf) run_privileged dnf install "$package" ;;
    dnf5) run_privileged dnf5 install "$package" ;;
    yum) run_privileged yum install "$package" ;;
    pacman) run_privileged pacman -S --needed "$package" ;;
    zypper) run_privileged zypper install "$package" ;;
    apk) run_privileged apk add "$package" ;;
    xbps) run_privileged xbps-install -S "$package" ;;
    eopkg) run_privileged eopkg install "$package" ;;
    emerge) run_privileged emerge --ask "$package" ;;
    flatpak) flatpak install "$remote" "$package" ;;
    snap)
      local confinement
      confinement="$(snap info "$package" 2>/dev/null | awk -F':[[:space:]]*' '$1 == "confinement" {print tolower($2); exit}')"
      case "$confinement" in
        classic) run_privileged snap install --classic "$package" ;;
        devmode)
          printf '%s\n' "$(msg snap_devmode_blocked)"
          return 2
          ;;
        *) run_privileged snap install "$package" ;;
      esac
      ;;
    *) printf '%s\n' "$(msg unsupported_source)"; return 2 ;;
  esac
  result=$?
  if (( result == 0 )); then printf '\n%s\n' "$(msg install_success)"; else printf '\n%s %s\n' "$(msg install_failed)" "$result"; fi
  return "$result"
}

install_flow() {
  local app="$1" i choice
  SELECTED_APP="$app"
  clear_screen; header "$(msg app_details)"
  printf '\n%s\n\n' "$app"
  printf '%s\n' "$(msg app_category): $(category_for_app "$app")"
  printf '\n%s\n' "$(msg repository_search_explain)"
  discover_candidates "$app"
  if (( ${#CAND_SOURCE[@]} == 0 )); then
    printf '\n%s\n' "$(msg no_candidates)"
    printf '%s\n' "$(msg no_candidates_tip)"
    pause; return
  fi
  printf '\n%s\n' "$(msg found_candidates)"
  for i in "${!CAND_SOURCE[@]}"; do
    printf '  %2d) %-13s %s' "$((i+1))" "$(source_label "${CAND_SOURCE[$i]}")" "${CAND_PACKAGE[$i]}"
    [[ -n "${CAND_REMOTE[$i]}" ]] && printf '  [%s]' "${CAND_REMOTE[$i]}"
    [[ -n "${CAND_DESC[$i]}" ]] && printf ' — %s' "${CAND_DESC[$i]}"
    printf '\n'
  done
  printf '\n  b) %s\n' "$(msg back)"
  printf '\n%s' "$(msg choose_candidate)"
  read -r choice || return 0
  [[ "${choice,,}" == 'b' ]] && return
  if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#CAND_SOURCE[@]} )); then
    install_candidate "$((choice-1))" || true
    pause
  else
    printf '%s\n' "$(msg invalid_choice)"; pause
  fi
}

category_for_app() {
  local app="$1" i
  for i in "${!APP_NAMES[@]}"; do
    if [[ "${APP_NAMES[$i]}" == "$app" ]]; then category_label "${APP_CATS[$i]}"; return; fi
  done
  printf '%s' '-'
}

self_test() {
  local errors=0 count
  count="$(awk -F '\t' 'NF==3 && $1 ~ /^[0-9][0-9][0-9]$/ && $2 ~ /^[0-9][0-9]$/ {n++} END{print n+0}' "$APPS_FILE")"
  if [[ "$count" -lt 500 ]]; then printf 'FAIL: only %s catalog entries\n' "$count"; errors=1; else printf 'PASS: %s catalog entries\n' "$count"; fi
  if [[ "${#CAT_IDS[@]}" -lt 1 ]]; then printf 'FAIL: no categories\n'; errors=1; else printf 'PASS: %s categories\n' "${#CAT_IDS[@]}"; fi
  local dupes
  dupes="$(cut -f1 "$APPS_FILE" | sort | uniq -d | wc -l | tr -d ' ')"
  if [[ "$dupes" != '0' ]]; then printf 'FAIL: duplicate application IDs (%s)\n' "$dupes"; errors=1; else printf 'PASS: application IDs are unique\n'; fi
  local name_dupes
  name_dupes="$(cut -f3 "$APPS_FILE" | tr '[:upper:]' '[:lower:]' | sort | uniq -d | wc -l | tr -d ' ')"
  if [[ "$name_dupes" != '0' ]]; then printf 'FAIL: duplicate application names (%s)\n' "$name_dupes"; errors=1; else printf 'PASS: application names are unique\n'; fi
  local missing_categories bad_hints
  missing_categories="$(awk -F '\t' 'NR==FNR {valid[$1]=1; next} NF==3 && !($2 in valid) {print $1; exit}' "$CATEGORIES_FILE" "$APPS_FILE")"
  if [[ -n "$missing_categories" ]]; then printf 'FAIL: application references unknown category (ID %s)\n' "$missing_categories"; errors=1; else printf 'PASS: all applications reference known categories\n'; fi
  bad_hints="$(awk -F '\t' 'NF!=2 || $1=="" || $2=="" {print NR; exit}' "$HINTS_FILE")"
  if [[ -n "$bad_hints" ]]; then printf 'FAIL: malformed search hint on line %s\n' "$bad_hints"; errors=1; else printf 'PASS: search hints are well formed\n'; fi
  for f in "$DATA_DIR"/locales/{es,en,ru}.sh; do
    if [[ -r "$f" ]] && bash -n "$f"; then printf 'PASS: locale syntax %s\n' "$(basename "$f")"; else printf 'FAIL: locale syntax %s\n' "$f"; errors=1; fi
  done
  return "$errors"
}

usage() {
  printf 'Dkariio Linux App Catalog %s\n' "$APP_VERSION"
  printf 'Usage: %s [--lang es|en|ru] [--search QUERY] [--doctor] [--self-test] [--version] [--help]\n' "${0##*/}"
}

main() {
  local arg query
  while (($#)); do
    case "$1" in
      --lang)
        [[ $# -ge 2 && "$2" =~ ^(es|en|ru)$ ]] || { usage >&2; exit 2; }
        APP_LANG="$2"; load_language "$APP_LANG"; shift 2 ;;
      --search)
        [[ $# -ge 2 ]] || { usage >&2; exit 2; }
        query="$2"; build_search_results "$query"
        printf '%s\n' "$(msg search_results_for) '$query'"
        for arg in "${RESULT_IDS[@]}"; do
          local i; i="$(app_index_from_id "$arg")"
          printf '%s\t%s\n' "${APP_IDS[$i]}" "${APP_NAMES[$i]}"
        done
        exit 0 ;;
      --doctor) system_diagnostics --noninteractive; exit 0 ;;
      --self-test) self_test; exit $? ;;
      --version|-v) printf '%s\n' "$APP_VERSION"; exit 0 ;;
      --help|-h) usage; exit 0 ;;
      *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
    esac
  done
  while true; do
    show_main_menu
    local choice
    read -r choice || break
    case "$choice" in
      1) browse_categories ;;
      2) search_menu ;;
      3) change_language ;;
      4) system_diagnostics ;;
      5) about_screen ;;
      0|q|Q) clear_screen; printf '%s\n' "$(msg goodbye)"; break ;;
      *) printf '%s\n' "$(msg invalid_choice)"; pause ;;
    esac
  done
}

# Allow tests to source the functions without starting the interactive UI.
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
