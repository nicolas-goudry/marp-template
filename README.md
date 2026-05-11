# Marpit Slides Template

This repository provides a reproducible, Nix-powered template for generating slide decks using the [Marpit](https://marpit.marp.app/) Markdown syntax and CLI rendering engine. It is designed to manage multiple slide decks within a single project while ensuring consistent formatting and asset management.

## Features

- **Nix-powered reproducibility**: uses Nix Flakes to ensure the exact same build environment across different systems
- **Automatic deck discovery**: the build system automatically detects all `.md` files in the `slides/` directory and generates corresponding build targets for them
- **Dual-format output**: every slide deck can be rendered into **HTML** or **PDF** format
- **Privacy-first assets**: includes local [Twemoji](https://github.com/twitter/twemoji) assets to account for Nix build sandbox denying internet access
- **Custom theming**: features a built-in custom CSS theme using [Catppuccin](https://catppuccin.com) Mocha color palette
- **Integrated formatting**: uses [`treefmt-nix`](https://github.com/numtide/treefmt-nix) to maintain a consistent code style

## Project structure

- **slides/**: contains the Markdown source files for slide decks
- **assets/**: stores images, fonts, and custom CSS
- **.marprc**: global Marp configuration
- **pkgs/slides.mix**: contains the core logic for building all slide decks and exposing them individually
- **flake.nix**: defines project inputs, outputs, and supported systems

## Getting started

### Prerequisites

To use this template, you must have [Nix](https://nixos.org/download.html) installed on your system with **Flakes** and **Nix commands** [experimental features](https://nix.dev/manual/nix/latest/development/experimental-features.html) enabled.

### Development environment

Enter the development shell to access Marp CLI and other tools:

```bash
nix develop
```

If you use [direnv](https://direnv.net), the environment will automatically load via the included `.envrc` (if allowed) when you navigate to the project:

```bash
direnv allow
```

## Running locally

You can use the Marp CLI directly to preview or serve your slides:

- **Server mode**: serves all decks in the project (at http://localhost:8080 by default)

  ```bash
  marp -s .
  ```

- **Preview mode (with hot reload)**: opens a live preview of a specific deck that updates as you save changes

  ```bash
  marp -wp slides/en.md
  ```

## Building slides with Nix

To build all decks and formats in a single output:

```bash
nix build '.#slides'
```

To build a specific deck and format (e.g., the English deck in PDF format), target the specific attribute:

```bash
nix build '.#slides.en.pdf'
```

The resulting files will be located in the `result/` directory.

### Formatting

To automatically format the entire project:

```bash
nix fmt
```

## Technical notes

### Browser sandboxing

Rendering PDFs via Marp requires running a browser. Because standard sandboxing is restricted within the Nix build environment, this template implements a custom `brave-unsandboxed` wrapper. This wrapper disables the GPU and SUID sandbox specifically for the build process to ensure reliable PDF generation.

> [!NOTE]
>
> At the time of writing, Chromium is not available on Darwin and Firefox has a build failure on Darwin. Hence we chose Brave as the browser used for PDF rendering to ensure that the build works across all supported systems.

### Asset path management

When rendering HTML format, the build system automatically copies the `assets/` directory to the derivation output directory and rewrites asset paths to ensure they are correctly resolved relative to the generated HTML file.

Additionally, the Twemoji assets are copied along with the output assets to ensure fully reproducible builds.

### Meta-derivation for slides

All slide decks are managed through a meta-derivation in [`pkgs/slides.nix`](./pkgs/slides.nix). This derivation builds all slide decks in all supported formats (HTML and PDF) and outputs them in a single directory along with shared styling and assets.

To still allow building a specific deck and format individually, the derivation exposes each combination via `passthru` attributes, making them accessible via `.#slides.<variant>.<format>`.

## License

This project is mostly for my personal use, but I open-sourced it under the [MIT license](./LICENSE) in case it might help others building beautiful and reproducible Marpit slide decks.
