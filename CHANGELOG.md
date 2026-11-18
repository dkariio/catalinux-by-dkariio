# Changelog

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
