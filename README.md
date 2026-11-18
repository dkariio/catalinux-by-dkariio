# 🐧 Dkariio Linux App Catalog

**A multilingual Linux application catalog and terminal installer — created by [@dkariio](https://www.instagram.com/dkariio/).**

> **Version:** 1.0.1 · **Catalog:** 970 applications · **Categories:** 28 · **Languages:** Español / English / Русский

---

## 🇪🇸 Español

### ✨ ¿Qué es?

Dkariio Linux App Catalog es un catálogo interactivo de aplicaciones para Linux escrito en Bash. Permite explorar categorías, buscar programas por nombre y localizar posibles paquetes en los gestores y fuentes configurados en tu sistema.

La interfaz está disponible en **español, inglés y ruso**. No necesita `dialog`, `whiptail`, `fzf`, `gum` ni una interfaz gráfica: funciona directamente en la terminal con Bash.

### 📦 Gestores y fuentes compatibles en v1.0.1

| Gestor / fuente | Familias / ejemplos | Búsqueda | Instalación |
|---|---|:---:|:---:|
| APT | Debian, Ubuntu, Linux Mint, Pop!_OS y derivadas | ✅ | ✅ |
| DNF / DNF5 | Fedora y distribuciones compatibles con DNF | ✅ | ✅ |
| YUM | Sistemas RPM que todavía usan YUM | ✅ | ✅ |
| Pacman | Arch Linux y derivadas | ✅ | ✅ |
| Zypper | openSUSE | ✅ | ✅ |
| APK | Alpine Linux | ✅ | ✅ |
| XBPS | Void Linux | ✅ | ✅ |
| eopkg | Solus | ✅ | ✅ |
| Portage / emerge | Gentoo | ✅ | ✅ |
| Flatpak | Distribuciones con Flatpak y remotos configurados | ✅ | ✅ |
| Snap | Distribuciones con `snapd` habilitado | ✅ | ✅ |

**Importante:** detectar un gestor no garantiza que una aplicación exista en sus repositorios. Las búsquedas consultan los índices y fuentes configurados en el equipo; la disponibilidad cambia según la distribución, versión, arquitectura, repositorios, región y permisos.

### 🚀 Inicio rápido

```bash
git clone https://github.com/TU_USUARIO/dkariio-linux-app-catalog.git
cd dkariio-linux-app-catalog
chmod +x linux-catalog.sh
./linux-catalog.sh
```

No instales el script con `sudo` para ejecutarlo. El programa solicita privilegios solamente cuando el gestor seleccionado los necesita.

### 🧭 Uso

```bash
./linux-catalog.sh                 # Abrir la interfaz interactiva
./linux-catalog.sh --lang es       # Forzar español
./linux-catalog.sh --lang en       # Forzar inglés
./linux-catalog.sh --lang ru       # Forzar ruso
./linux-catalog.sh --search firefox # Buscar en el catálogo local
./linux-catalog.sh --doctor        # Diagnóstico del sistema
./linux-catalog.sh --self-test     # Validar el catálogo y los idiomas
./linux-catalog.sh --version       # Mostrar versión
./linux-catalog.sh --help          # Ayuda
```

### 🖥️ Flujo de instalación

1. Explora una categoría o busca una aplicación por nombre.
2. Selecciona el programa deseado.
3. El programa consulta las fuentes disponibles (APT, DNF/DNF5/YUM, Pacman, Zypper, APK, XBPS, eopkg, Portage, Flatpak y Snap, según lo que tengas instalado).
4. Revisa los candidatos y selecciona el identificador que corresponda a la aplicación.
5. Confirma la instalación. El gestor nativo realizará su propia comprobación/transacción.

El instalador **no ejecuta coincidencias aproximadas sin que las revises**, no añade repositorios automáticamente, no descarga scripts remotos y no usa `curl | bash`.

### 🧰 Instalación opcional en el sistema

```bash
make
sudo make install
```

Esto instala el ejecutable en `/usr/local/bin/dkariio-catalog` y los datos en `/usr/local/share/dkariio-linux-app-catalog/`.

Para desinstalar:

```bash
sudo make uninstall
```

### 📁 Estructura del proyecto

```text
.
├── linux-catalog.sh
├── catalog/
│   ├── README.md
│   ├── apps.tsv
│   ├── categories.tsv
│   ├── search-hints.tsv
│   └── initial-catalog.txt
├── locales/
│   ├── es.sh
│   ├── en.sh
│   └── ru.sh
├── tests/
│   ├── run.sh
│   └── test-parsers.sh
├── .github/workflows/ci.yml
├── Makefile
├── LICENSE
├── GITHUB_DESCRIPTION.txt
├── .gitignore
├── CHANGELOG.md
├── CONTRIBUTING.md
└── SECURITY.md
```

### 🛠️ Correcciones de la versión 1.0.1

- Flatpak solicita columnas explícitas `application,remotes` para leer el identificador real de la aplicación.
- La búsqueda de Solus `eopkg` interpreta ahora las líneas `paquete - descripción`.
- APK y XBPS separan la versión desde el último separador, conservando nombres de paquete con guiones y números.
- Los Snap que requieren confinamiento `classic` se instalan con `--classic`; los paquetes `devmode` se bloquean por seguridad.
- Las búsquedas de nombres compuestos usan el nombre normalizado completo en lugar de una primera palabra demasiado genérica.

### ⚠️ Alcance y limitaciones de la versión 1.0.1

- Los 970 nombres proceden del catálogo inicial incluido en este proyecto. Son nombres visibles, **no** identificadores de paquetes garantizados.
- La búsqueda usa un nombre normalizado y pistas mantenidas en `catalog/search-hints.tsv`; por ello puede no encontrar algunas aplicaciones o mostrar más de un candidato.
- El usuario debe comprobar el nombre, fuente y descripción del candidato antes de confirmar.
- No se instala desde AUR, repositorios PPA/RPM de terceros, archivos DEB/RPM descargados, AppImage, scripts del fabricante ni binarios externos.
- No se habilitan repositorios, no se importan claves, no se actualiza todo el sistema ni se resuelven licencias automáticamente.
- No se garantiza soporte de todas las distribuciones o arquitecturas existentes. v1.0.1 implementa los gestores indicados en la tabla; Nix/Guix y AUR quedan fuera de esta versión.
- La instalación es de una aplicación por operación; todavía no hay cola de instalación múltiple.
- Algunas aplicaciones del catálogo son servidores, servicios, complementos o herramientas especializadas, y su disponibilidad puede ser limitada.

### 🛡️ Seguridad

Consulta [`SECURITY.md`](SECURITY.md). Instala software solamente desde fuentes que conozcas y revisa la operación presentada por el gestor de paquetes. Los errores de una fuente no se deben resolver desactivando la seguridad del sistema.

### 🤝 Contribuir

Las contribuciones para mejorar identificadores, pistas de búsqueda, traducciones y soporte de gestores son bienvenidas. Consulta [`CONTRIBUTING.md`](CONTRIBUTING.md).

---

## 🇬🇧 English

### ✨ What is it?

Dkariio Linux App Catalog is an interactive Linux software catalog written in Bash. Browse categories, search applications by name, and discover package candidates in the package managers and sources configured on your system.

The interface supports **Spanish, English, and Russian**. It does not require `dialog`, `whiptail`, `fzf`, `gum`, or a graphical desktop: it runs directly in your terminal using Bash.

### 📦 Package managers and sources supported in v1.0.1

| Package manager / source | Families / examples | Search | Install |
|---|---|:---:|:---:|
| APT | Debian, Ubuntu, Linux Mint, Pop!_OS and derivatives | ✅ | ✅ |
| DNF / DNF5 | Fedora and DNF-compatible distributions | ✅ | ✅ |
| YUM | RPM systems still using YUM | ✅ | ✅ |
| Pacman | Arch Linux and derivatives | ✅ | ✅ |
| Zypper | openSUSE | ✅ | ✅ |
| APK | Alpine Linux | ✅ | ✅ |
| XBPS | Void Linux | ✅ | ✅ |
| eopkg | Solus | ✅ | ✅ |
| Portage / emerge | Gentoo | ✅ | ✅ |
| Flatpak | Distributions with Flatpak and configured remotes | ✅ | ✅ |
| Snap | Distributions with `snapd` enabled | ✅ | ✅ |

**Important:** detecting a package manager does not mean every catalog entry exists in its repositories. Searches use the indexes and sources configured on the local machine. Availability varies by distribution, release, architecture, repositories, region, and permissions.

### 🚀 Quick start

```bash
git clone https://github.com/YOUR_USERNAME/dkariio-linux-app-catalog.git
cd dkariio-linux-app-catalog
chmod +x linux-catalog.sh
./linux-catalog.sh
```

Do not run the script itself with `sudo`. It requests elevated privileges only when the selected package manager requires them.

### 🧭 Usage

```bash
./linux-catalog.sh                  # Launch the interactive interface
./linux-catalog.sh --lang es        # Force Spanish
./linux-catalog.sh --lang en        # Force English
./linux-catalog.sh --lang ru        # Force Russian
./linux-catalog.sh --search firefox # Search the local catalog
./linux-catalog.sh --doctor         # System diagnostics
./linux-catalog.sh --self-test      # Validate catalog and locales
./linux-catalog.sh --version        # Show version
./linux-catalog.sh --help           # Help
```

### 🖥️ Installation flow

1. Browse a category or search for an application.
2. Select the application.
3. The program searches available sources (APT, DNF/DNF5/YUM, Pacman, Zypper, APK, XBPS, eopkg, Portage, Flatpak, and Snap, depending on what is installed).
4. Review the candidates and select the package identifier that matches the application.
5. Confirm the installation. The native package manager then performs its own transaction checks.

The installer **does not install an approximate match without your review**. It does not add repositories automatically, download remote scripts, or use `curl | bash`.

### 🧰 Optional system-wide installation

```bash
make
sudo make install
```

This installs the executable at `/usr/local/bin/dkariio-catalog` and data files at `/usr/local/share/dkariio-linux-app-catalog/`.

Uninstall:

```bash
sudo make uninstall
```

### 🛠️ v1.0.1 fixes

- Flatpak requests explicit `application,remotes` columns to read the actual application ID.
- Solus `eopkg` search now parses `package - description` result lines.
- APK and XBPS version parsing preserves hyphenated package names containing digits.
- Snap packages requiring `classic` confinement use `--classic`; `devmode` Snaps are blocked for safety.
- Multi-word fallback searches use the complete normalized application name.

### ⚠️ v1.0.1 scope and limitations

- The 970 display names come from the initial catalog shipped with this project. They are **not** guaranteed package identifiers.
- Search uses a normalized application-name slug or a maintained hint in `catalog/search-hints.tsv`; it may miss some applications or return multiple candidates.
- Review the package name, source, and description before confirming.
- AUR, third-party PPAs/RPM repositories, downloaded DEB/RPM files, AppImages, vendor scripts, and external binaries are not installed.
- The program does not enable repositories, import signing keys, upgrade the whole system, or handle licenses automatically.
- Support for every existing distribution or architecture is not guaranteed. v1.0.1 implements the package managers listed above; Nix/Guix and AUR are outside this release.
- Installation is one application per operation; there is no multi-app installation queue yet.
- Some catalog entries are servers, services, plugins, or specialist tools and may have limited package availability.

### 🛡️ Security & 🤝 Contributing

See [`SECURITY.md`](SECURITY.md) before installing software, and [`CONTRIBUTING.md`](CONTRIBUTING.md) to help improve package hints, translations, and package-manager support.

---

## 🔗 Project metadata

| Field | Value |
|---|---|
| Creator | **@dkariio** · [Instagram](https://www.instagram.com/dkariio/) |
| Version | `1.0.1` |
| Language | Bash (Bash 4+) |
| License | MIT |
| Short description (ES) | Catálogo e instalador de aplicaciones Linux en Bash, multidioma y compatible con varios gestores de paquetes. |
| Short description (EN) | A multilingual Bash Linux app catalog and installer supporting multiple package managers. |

**Made for Linux users. Built by @dkariio. 🐧**
