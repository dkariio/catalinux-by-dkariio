# Changelog

## [1.0.1] - 2026-11-18

### Fixed
- Corrected Flatpak result parsing by requesting explicit application ID and remote columns.
- Corrected Solus eopkg search parsing to read `package - description` result lines.
- Improved APK and XBPS version parsing to preserve hyphenated package names containing digits.
- Improved fallback search terms for multi-word application names.
- Added Snap classic-confinement handling and blocked devmode Snaps rather than silently weakening confinement.
- Made the script safe to source from tests without launching the interactive menu.

### Tests
- Added parser tests for Flatpak, eopkg, APK, XBPS, DNF, DNF5, Pacman, Zypper, Portage, and Snap.
- Added mocked installation-dispatch tests for all supported backends; tests do not install packages.

## [1.0.0] - 2026-11-18

### Added
- Interactive terminal interface in Spanish, English, and Russian.
- Catalog of 970 applications grouped into 28 categories.
- Local catalog search and paginated category browsing.
- Package discovery and installation flows for APT, DNF, YUM, Pacman, Zypper, APK, XBPS, eopkg, Portage/emerge, Flatpak, and Snap.
- Candidate review and explicit confirmation before installation.
- System diagnostics, self-test, CLI help, and version flags.
- Makefile, MIT license, contribution/security guidance, and GitHub Actions workflow.

### Notes
- Package identifiers are discovered from the configured repositories at runtime; the catalog stores display names, not universal package IDs.
- Availability depends on the Linux distribution and its enabled sources.
