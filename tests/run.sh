#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

bash -n linux-catalog.sh
bash -n locales/es.sh
bash -n locales/en.sh
bash -n locales/ru.sh
bash -n tests/run.sh

./linux-catalog.sh --self-test
[[ "$(./linux-catalog.sh --version)" == '1.0.0' ]]
./linux-catalog.sh --help >/dev/null
search_output="$(./linux-catalog.sh --search Firefox)"
grep -q $'001\tFirefox' <<< "$search_output"

# Exercise category navigation without requiring a TTY.
ui_output="$(printf '1\n1\nb\nb\n0\n' | ./linux-catalog.sh --lang en)"
grep -q 'See you next time' <<< "$ui_output"

# Mock APT metadata to verify candidate discovery without installing anything.
mock_dir="$(mktemp -d)"
trap 'rm -rf "$mock_dir"' EXIT
mkdir -p "$mock_dir/bin"
cat > "$mock_dir/bin/apt-cache" <<'MOCK_APT_CACHE'
#!/usr/bin/env bash
printf 'firefox-esr - Mozilla Firefox Extended Support Release\n'
MOCK_APT_CACHE
cat > "$mock_dir/bin/apt-get" <<'MOCK_APT_GET'
#!/usr/bin/env bash
printf 'Unexpected package installation in test\n' >&2
exit 99
MOCK_APT_GET
for manager in dnf dnf5 yum pacman zypper apk xbps-query eopkg emerge flatpak snap; do
  printf '#!/usr/bin/env bash\nexit 0\n' > "$mock_dir/bin/$manager"
done
chmod +x "$mock_dir/bin/"*
mock_output="$(printf '2\nfirefox\n1\n1\nn\n' | PATH="$mock_dir/bin:/usr/bin:/bin" ./linux-catalog.sh --lang en)"
grep -q 'firefox-esr' <<< "$mock_output"
grep -q 'Installation cancelled' <<< "$mock_output"
if grep -q 'Unexpected package installation in test' <<< "$mock_output"; then
  printf 'FAIL: mock package installer was unexpectedly executed\n' >&2
  exit 1
fi

printf '\nAll tests passed.\n'
