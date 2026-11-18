# Contributing / Cómo contribuir

Thanks for helping improve Dkariio Linux App Catalog! / ¡Gracias por ayudar a mejorar Dkariio Linux App Catalog!

## Useful contributions

- Correct package search hints in `catalog/search-hints.tsv`.
- Add or improve translations in `locales/`.
- Improve package-manager search parsers and installation backends.
- Report distribution-specific issues with exact distro/version, architecture, command output, and package source.
- Keep catalog records as display names; place distribution-specific package identifiers in a separately reviewed mapping/hint mechanism.

## Rules

1. Never install a package based on an unreviewed fuzzy match.
2. Never add `curl | bash`, `wget | sh`, unverified binary downloads, or automatic third-party repository setup.
3. Do not disable signature checks, TLS verification, sandboxing, or package-manager safety features.
4. Keep all package names as quoted arguments; do not build shell commands with `eval`.
5. Update tests and documentation for behavior changes.

## Before opening a pull request

```bash
bash -n linux-catalog.sh
./tests/run.sh
```

ShellCheck is recommended:

```bash
shellcheck linux-catalog.sh locales/*.sh tests/run.sh
```
