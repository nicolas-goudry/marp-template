# Marp Deck Directory

> **A zero-config, fully reproducible presentation environment** powered by [Marp](https://marp.app/) and [Nix](https://nixos.org/).
>
> 1. Write slides in Markdown
> 2. Build pixel-identical HTML, PDF, and cover images anywhere
> 3. Forget toolchain drift forever

Presentations have a tooling problem. Proprietary editors lock content into binary formats. Web slide builders die when their SaaS goes offline. Even "plain HTML" decks tend to drift the moment a teammate runs a different Node version, a different Chromium, or a different font fallback.

This repository is a deliberate, opinionated answer to that problem:

- **Markdown-first authoring**: Slides are text. They diff cleanly, review like code, and survive any tool you'll ever use.
- **Marp for rendering**: A mature, fast, themeable Markdown-to-slide engine with a real CLI, live server, and PDF export.
- **Nix flakes for the toolchain**: The Marp CLI, the headless browser used for PDF rendering, the emoji set, and every supporting binary are pinned by hash. Anyone with Nix can reproduce your deck, byte-for-byte, five years from now.
- **Convention over configuration**: Drop a `.md` file under `slides/`, get HTML, PDF, and a PNG cover. No project per deck, no boilerplate, no scripts to copy.

The combination is greater than the sum of its parts. **Marp gives you authoring; Nix gives you guarantees.** Together they deliver a presentation pipeline you can hand to a colleague, a CI runner, or your future self without a single "well, it works on my machine..." moment.

If you write talks, lectures, internal briefings, or conference material, and you care that they still build cleanly next year: this is for you.

## Prerequisites

You need exactly one thing: **Nix with flakes enabled**. That's it. No Node, no npm, no Chromium, no font installer.

### Install Nix

The easiest way to install Nix is through the [Determinate Systems installer](https://github.com/DeterminateSystems/nix-installer) (flakes are on by default):

```bash
curl -fsSL https://install.determinate.systems/nix | sh -s -- install
```

Alternatively, use the [official installer](https://nixos.org/download) and enable flakes manually by adding the following to `~/.config/nix/nix.conf`:

```
experimental-features = nix-command flakes
```

### Optional: direnv

This repo ships an `.envrc` containing `use flake`. If you install [direnv](https://direnv.net/) and [nix-direnv](https://github.com/nix-community/nix-direnv), your shell automatically enters the project's environment the moment you `cd` into the directory.

```bash
# Install direnv (example using Nix profile, do what best suits you)
nix profile install nixpkgs#direnv nixpkgs#nix-direnv

# Hook direnv into your shell (bash example)
echo 'eval "$(direnv hook bash)"' >> ~/.bashrc

# In the repo root:
direnv allow
```

From then on, `cd`-ing into the project replaces `nix develop` entirely.

### Supported Platforms

The flake targets:

| System           | Status    |
| ---------------- | --------- |
| `x86_64-linux`   | Supported |
| `aarch64-linux`  | Supported |
| `aarch64-darwin` | Supported |

> [!NOTE]
>
> Darwin x86_64 support is expected to be dropped in NixOS 26.05, hence we chose to not support it explicitly, but it should work anyway if you add it to the flake's supported systems.

## Quick Start

```bash
# 1. Clone
git clone https://github.com/nicolas-goudry/marp-deck-directory
cd marp-deck-directory

# 2. Enter the reproducible dev shell
nix develop # or simply `cd` here if direnv is set up (see previous section)

# 3. Start the live-reload Marp server
marp --server .
```

Open [http://localhost:8080](http://localhost:8080): Marp serves an index of every deck under `slides/` and reloads on save.

To create your first deck, drop a Markdown file under `slides/` (see [Authoring slides](#authoring-slides)) and the server picks it up instantly.

## Directory Structure

```
.
├── flake.nix                     # Nix flake: devshell + per-deck packages
├── shell.nix                     # Devshell definition (marp-cli)
├── treefmt.nix                   # Formatter config (nixfmt + prettier)
├── .marprc                       # Marp CLI config: default theme paths, HTML tags enabled
├── .envrc                        # direnv hook (`use flake`)
│
├── pkgs/                         # Custom Nix packages
│   ├── slides.nix                # The build engine: discovers and builds every deck
│   ├── brave-unsandboxed.nix     # Brave wrapper for PDF/cover rendering
│   └── twemoji.nix               # Pinned Twemoji asset set
│
├── assets/                       # GLOBAL assets, shared by every deck
│   ├── css/                      # Custom CSS files
│   │   ├── theme.css             # Example main custom theme (declares @theme custom-theme)
│   │   └── fonts.css             # Example Ubuntu Sans / Ubuntu Mono @font-face declarations
│   ├── themes/                   # Third-party themes
│   ├── fonts/                    # Font files
│   └── images/                   # Images
│
└── slides/                       # YOUR decks live here
    ├── chicken-cooking.md        # Flat deck
    ├── chicken-cooking.cover.md  # Optional dedicated cover for chicken-cooking.md
    │
    └── 2026/q4-keynote/          # Self-contained deck
        ├── slides.md             # Conventional name
        ├── cover.md              # Optional cover
        └── assets/               # Deck-specific assets
```

**Two kinds of assets:**

| Layout                   | Where                      | When to use                                                 |
| ------------------------ | -------------------------- | ----------------------------------------------------------- |
| **Global assets**        | `assets/` at the repo root | Logos, fonts, themes, anything reused across multiple decks |
| **Deck-specific assets** | `<deck-dir>/assets/`       | Diagrams, screenshots, one-off images for a single deck     |

**Two kinds of decks:**

| Style                                                       | Filename                   | Output name                |
| ----------------------------------------------------------- | -------------------------- | -------------------------- |
| **Flat deck**                                               | `slides/foo/bar.md`        | `foo-bar.{html,pdf,cover}` |
| **Self-contained deck** (recommended for non-trivial talks) | `slides/foo/bar/slides.md` | `foo-bar.{html,pdf,cover}` |

A self-contained deck owns its directory: it can carry a `cover.md` and an `assets/` subfolder. Flat decks are perfect for short, asset-light talks.

> [!WARNING]
>
> **Naming collisions**
>
> Don't put both `foo/bar.md` and `foo/bar/slides.md` in the tree: the nested form wins and the other is silently skipped.
>
> **Pick one style per deck.**

## The Nix Advantage

This is where the project earns its keep. Everything that can break across machines (version drift, missing binaries, font fallbacks, sandboxing quirks) is removed from the table.

### Marp CLI, pinned

The devshell (`shell.nix`) declares exactly one input: `marp-cli` from a pinned `nixpkgs` revision (`flake.lock`).

Whoever runs `nix develop` gets the **same** Marp version you developed against, with no global Node install required.

### Brave, unsandboxed

Marp uses a real Chromium-based browser to render PDFs and PNG covers. Stock Chromium in sandbox-restricted environments (CI, containers, NixOS without setuid) fails non-obviously. The custom `pkgs/brave-unsandboxed.nix` derivation wraps Brave with the right flags:

```text
--no-sandbox
--disable-setuid-sandbox
--disable-gpu
--disable-dev-shm-usage
```

Then, the build system passes the wrapper to Marp via `--browser=chrome --browser-path=…`.

PDF and cover builds _Just Work™_ in any Nix environment, including stripped-down CI runners.

### Twemoji, vendored

Emoji are rendered via [Twemoji](https://github.com/twitter/twemoji), pinned to **v14.0.3** by sha256 hash in `pkgs/twemoji.nix`.

The 2K+ SVG asset set is copied into `assets/twemoji/` at build time and referenced through Marp's `options.emoji.twemoji.base` setting.

Emoji look the same on Linux, macOS, and the colleague who only opens the PDF.

### Fonts, embedded

`assets/fonts/` ships any font you drop in it (by default the full Ubuntu Sans and Ubuntu Mono families). `assets/css/fonts.css` declares the matching `@font-face` rules.

Decks render identically whether the viewer has these fonts installed or not, and PDF exports embed them.

### The "works on my machine" guarantee

Because every input is content-addressed by Nix:

- A teammate who runs `nix develop` gets the exact Marp, Brave, Twemoji, and font set you used.
- CI builds with `nix build .#slides` produce reproducible artifacts.
- Future-you, two laptops from now, rebuilds the same deck pixel-for-pixel.

**If a deck builds today, it builds forever.**

## Authoring Slides

### Add a new deck in 30 seconds

```bash
mkdir -p slides
cat > slides/hello.md <<'EOF'
---
marp: true
theme: gaia
paginate: true
---

# Hello, Marp!

A slide about nothing in particular.

---

## Second slide

- Markdown lists
- Render as bullets
- Obviously
EOF
```

Run `marp --server .` and open [http://localhost:8080](http://localhost:8080): your deck is live.

### Marp syntax cheatsheet

| Feature             | Syntax                                                                  |
| ------------------- | ----------------------------------------------------------------------- |
| Slide separator     | `---` on its own line                                                   |
| Per-slide directive | `<!-- _class: lead -->` (single slide), `<!-- class: lead -->` (sticky) |
| Speaker notes       | `<!-- This is a speaker note -->`                                       |
| Background image    | `![bg](/assets/images/bg/foo.jpg)`                                      |
| Fit image to slide  | `![bg fit](image.png)`                                                  |
| Two columns         | Use the `lead`/`split` class, or HTML/CSS                               |
| Inline HTML         | Allowed: `html: true` is set in `.marprc`                               |

See the [Marp Markdown documentation](https://marpit.marp.app/markdown) for the full syntax.

### Best practices

- **Use self-contained decks** (`<name>/slides.md`) for anything beyond a single screen of content. You get a clean home for the cover and deck-local assets.
- **Reference global assets with absolute paths** (i.e. `/assets/images/logos/foo.webp`), the build system rewrites these correctly for every output format.
- **Reference deck-local assets with `./assets/...`**, same: the build system relocates and rewrites them safely.
- **Keep one logical idea per slide**: Marp is fast; abuse the separator.
- **Commit early, diff often**: That's the whole point of Markdown decks.

## How Deck Covers Work

A "cover" is a single PNG, generated from the **first slide** of a Markdown file, suitable for thumbnails, social sharing, deck galleries, and READMEs.

### Resolution order

For every deck `slides/<path>/<deck>.md`, the build system looks for a dedicated cover file in this order:

1. **Self-contained deck only**: if the deck is named `slides.md`, look for `cover.md` in the same directory.
2. **Any deck**: look for `<deck>.cover.md` next to the deck.
3. **Fallback**: use the deck file itself; its first slide becomes the cover.

| Deck path                  | Cover candidate (in order)                                                                             |
| -------------------------- | ------------------------------------------------------------------------------------------------------ |
| `slides/intro.md`          | 1. `slides/intro.cover.md`<br/>2. `slides/intro.md`                                                    |
| `slides/keynote/slides.md` | 1. `slides/keynote/cover.md`<br/>2. `slides/keynote/slides.cover.md`<br/>3. `slides/keynote/slides.md` |

### How the cover is rendered

The cover format invokes Marp with `--image=png` plus the same `--browser` and `--allow-local-files` flags used for PDFs. Output filename matches the deck's derivation name (e.g., `keynote.png`), and the file lands in the final `result/` directory alongside the HTML and PDF outputs.

This means you can write a **dedicated, beautifully-styled title slide** for sharing, distinct from your in-deck title, by simply creating a `cover.md` (or `<deck>.cover.md`) with a single slide.

## Build & Export

All builds go through Nix. There is no Makefile by design. The flake exposes every deck and every format as a first-class package.

### Build everything

```bash
nix build .#slides
```

The `result/` symlink contains:

- One `*.html` per deck
- One `*.pdf` per deck
- One `*.png` cover per deck
- A copy of `assets/` (with global, twemoji, and any deck-specific assets rewritten correctly)

### Build a single deck

Every deck is exposed as a passthru attribute under `slides`, mirroring its path. A deck at `slides/foo/bar.md` (or `slides/foo/bar/slides.md`) is available as `slides.foo.bar.{html,pdf,cover}`.

```bash
# HTML only
nix build .#slides.intro.html

# PDF only
nix build .#slides.intro.pdf

# Cover PNG only
nix build .#slides.intro.cover

# Nested deck
nix build .#slides.2026.q4-keynote.pdf
```

### Live preview (no Nix build needed)

Inside `nix develop`:

```bash
marp --server .                 # Browse every deck at http://localhost:8080
```

### Format the codebase

```bash
nix fmt          # Runs nixfmt + prettier per treefmt.nix
nix flake check  # Verifies formatting
```

> [!NOTE]
>
> `slides/**/*.md` is excluded from Prettier (see `.prettierignore`) so Marp's specific directives and tokens (like step-by-step list items with `* item`) aren't reformatted.

## Customization

### Custom CSS themes

The default theme `custom-theme` is declared in `assets/css/theme.css` (built on top of `catppuccin-mocha.css` and the Ubuntu fonts CSS).

To add your own:

1. Drop a CSS file in either `assets/css/` or `assets/themes/` (both are registered as Marp theme paths in `.marprc`):

   ```yaml
   themeSet:
     - assets/css
     - assets/themes
   ```

2. Start your theme file with a Marpit theme directive:

   ```css
   /*! @theme my-theme */
   ```

3. Reference it from any deck:

   ```yaml
   ---
   theme: my-theme
   ---
   ```

You can also override styles inline per deck using `<style>` tags or Marp's `style:` frontmatter key.

### Adding fonts

1. Drop the font files into `assets/fonts/`.
2. Create a dedicated CSS file in `assets/css` with a theme directive and `@font-face` rules. Reference fonts via absolute paths (i.e. `url("/assets/fonts/MyFont-Regular.ttf")`) so they resolve correctly in both HTML and PDF builds.

   ```css
   /*! @theme my-font */

   .markdown-body,
   section {
     --fontStack-sansSerif: "My Font";
     --fontStack-monospace: "My Font Mono";
     font-family: "My Font", sans-serif;
   }

   @font-face {
     /* ... */
   }
   ```

3. Use the font from your theme:

   ```css
   @import "my-font";
   ```

Because fonts are embedded into the repo and referenced through CSS that the build copies verbatim, PDFs ship with the typography baked in.

### Configuring Marp globally

Project-wide Marp behavior lives in `.marprc`:

```yaml
# Default locations to look for Marp themes
themeSet:
  - assets/css
  - assets/themes
# Allow raw HTML in Markdown (needed for advanced layouts)
html: true
```

These are basic sensibles defaults, you can add any [Marp CLI option](https://github.com/marp-team/marp-cli) here. The build system extends this file at build time to wire in Twemoji and the unsandboxed browser, but never overwrites your settings.

### Pinning a different Marp / Brave / Twemoji version

- **Marp & Brave:** both come from `nixpkgs`, just edit `flake.lock`'s nixpkgs revision (`nix flake update`).
- **Twemoji:** edit `version` and `hash` in `pkgs/twemoji.nix`. Run `nix build .#twemoji` to verify.

## License

See [`LICENSE`](./LICENSE).
