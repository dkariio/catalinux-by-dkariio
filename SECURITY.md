# Security policy

## Supported versions

Security fixes are currently intended for the latest `1.x` release.

## Reporting a vulnerability

Please do not publish exploitable details in a public issue. Contact the project maintainer through the private contact method listed on the repository profile, including:

- affected version and Linux distribution;
- reproduction steps and relevant logs (remove personal data);
- expected and observed behavior;
- whether the issue could cause unintended package installation or privilege escalation.

## Design principles

- The script does not run downloaded scripts or use `eval`.
- It stores catalog metadata as tab-separated text and validates package identifiers before passing them as arguments.
- It displays candidate sources and requires an explicit confirmation before calling an installer.
- Privileged package-manager commands are run through `sudo` only when required, unless already running as root.
- Package-manager prompts and transaction summaries remain visible to the user.

No installer can make arbitrary third-party repositories safe. Review the source and the package manager's transaction before accepting it.
