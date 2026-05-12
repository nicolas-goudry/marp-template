---
# Metadata
title: Marp Deck Directory Introduction
date: 2026-05-11
author: Nicolas Goudry
affiliation: https://github.com/nicolas-goudry
lang: en-US

# Marp config
theme: custom-theme
paginate: true
# Transitions documentation: https://github.com/marp-team/marp-cli/blob/v4.3.1/docs/bespoke-transitions/README.md
transition: coverflow
footer: Marp Deck Directory - Introduction
---

<!--
_class: lead
_paginate: false
_footer: ""
-->

# Marp Deck Directory

## A zero-config, fully reproducible presentation environment.

Powered by **Marp** 🚀 and **Nix** ❄️.

---

<!-- _transition: none -->

# The Tooling Problem

Presentations often suffer from **toolchain drift**. Have you ever experienced:

* "It looked perfectly fine on my Macbook..."
* Missing custom fonts on the conference computer.
* Broken `npm` dependencies just before a talk.
* Blank PDF exports in CI pipelines due to Chromium sandbox restrictions.

<p> </p>

---

<!-- _paginate: hold -->

# The Tooling Problem

Presentations often suffer from **toolchain drift**. Have you ever experienced:

- "It looked perfectly fine on my Macbook..."
- Missing custom fonts on the conference computer.
- Broken `npm` dependencies just before a talk.
- Blank PDF exports in CI pipelines due to Chromium sandbox restrictions.

We need a way to make decks outlive the laptop they were written on.

---

# The Solution: Nix + Marp

By combining Marp's elegant Markdown rendering with Nix flake inputs, this template provides:

* **Pinned Toolchain**: Marp CLI, Brave browser, and Twemoji are locked by hash.
* **Guaranteed Reproducibility**: Byte-for-byte identical builds across Linux and macOS.
* **Zero Host Dependencies**: No need to install Node, global npm packages, or maintain local Chrome binaries.

---

# Build Everywhere

Write your slides in simple Markdown, and let the Nix derivation do the heavy lifting automatically.

```bash
# Build the entire deck directory into multiple formats
nix build '.#slides'

# Or build a specific format for a specific deck
nix build '.#slides.showcase.pdf'
```

This generates:

1. A standalone **HTML** presentation.
2. A crisp **PDF** export (via a headless, unsandboxed Brave engine).
3. A custom **PNG Cover** image for thumbnails.

---

# Smart Asset Management

Organize your slides elegantly with transparent path rewriting. The Nix build automatically fixes paths for you:

| Asset Type | Location | Usage |
| :--- | :--- | :--- |
| **Global Assets** | `/assets/` | Shared fonts, CSS themes, and company logos. |
| **Local Assets** | `slides/my-talk/assets/` | Deck-specific diagrams, photos, and screenshots. |

> *"Whether you are previewing locally on the `--server` or deploying the final HTML artifact, your images and fonts will perfectly resolve."*

---

<!-- _transition: none -->

# Beautiful Defaults included

Focus on content, not CSS. This directory ships with batteries included:

* 💅 Styled using gorgeous [**Catppuccin** themes](https://github.com/nicolas-goudry/marp).
* 🔤 **Ubuntu Sans & Mono** fonts embedded automatically.
* 💻 Pre-configured syntax highlighting and element typography.
* 🌍 Fully vendored Twemoji support out-of-the-box! 🎉

<p> </p>

---

<!-- _paginate: hold -->

# Beautiful Defaults included

Focus on content, not CSS. This directory ships with batteries included:

- 💅 Styled using gorgeous [**Catppuccin** themes](https://github.com/nicolas-goudry/marp).
- 🔤 **Ubuntu Sans & Mono** fonts embedded automatically.
- 💻 Pre-configured syntax highlighting and element typography.
- 🌍 Fully vendored Twemoji support out-of-the-box! 🎉

To customize, drop your own CSS or fonts in `assets/` and update your theme.

---

<!-- _class: lead -->

# Ready to present?

Clone the repository, drop into the shell, and start writing.

```bash
nix develop
serve
```

**Happy presenting!** 🎤
