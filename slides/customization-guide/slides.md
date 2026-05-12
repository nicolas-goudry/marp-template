---
# Metadata
title: "Marp Deck Directory: Customization Guide"
date: 2026-05-12
author: Nicolas Goudry
affiliation: https://github.com/nicolas-goudry
lang: en-US

# Marp config
theme: custom-theme
paginate: true
# Transitions documentation: https://github.com/marp-team/marp-cli/blob/v4.3.1/docs/bespoke-transitions/README.md
transition: fade
footer: Marp Deck Directory - Customization Guide
---

<style scoped>
  .title-container {
    background: rgba(30, 30, 46, .8);
    border: 1px solid #f38ba8;
    padding: 2rem;
    border-radius: 10px;
  }
</style>

<!--
_class: lead
_footer: ""
_paginate: skip
_transition: swipe
-->

![bg grayscale](./assets/images/bg/pexels-sabinakallari-33998415.jpg)

<div class="title-container">

# Marp Deck Directory

## Customization Guide

</div>

---

![bg right:33% w:200](./assets/images/logos/catppuccin.png)

# Builtin Themes

This template comes with all [Catppuccin](https://github.com/catppuccin/catppuccin) flavors themes, available in `assets/themes` directory.

Using these themes is as simple as adding this frontmatter block to your slides:

```yaml
---
theme: catppuccin-mocha
---
```

Other flavors are **catppuccin-latte**, **catppuccin-frappe** and **catppuccin-macchiato**.

---

# Adding your Themes

By default, Marp is configured to look for themes in `assets/themes` and `assets/css`.

Each directory has a different objective:

- `assets/themes`: third party themes, drop the CSS here and forget it
- `assets/css`: your custom themes, based on builtin or third party themes (or not)

Each Marp theme **must** define an `@theme` directive that can be referenced from frontmatter:

```css
/*! @theme my-custom-theme */
```

---

# Fonts <span style="float: right"><sub><sup>1/3</sup></sub></span>

The `assets/css` directory can also be used to add fonts, in the shape of themes.

Drop your fonts under `assets/fonts`, and create a new CSS file to use your font:

```css
/*! @theme my-font */

@font-face {
  src: url("/assets/fonts/MyFontSans.ttf") format("truetype");
}
```

<div class="markdown-alert markdown-alert-warning">
  <div class="markdown-alert-title">Warning</div>

  You **must** use absolute paths to reference fonts source files, because relative paths are relative to source Markdown files in Marp.
</div>

---

# Fonts <span style="float: right"><sub><sup>2/3</sup></sub></span>

It's also a good practice to set the font as the default directly in the font theme:

```css
.markdown-body,
section {
  --fontStack-sansSerif: "My Font Sans";
  --fontStack-monospace: "My Font Mono";
  font-family: var(--fontStack-sansSerif);
}
```

This way, you only have to care about importing the font theme and you're good to go!

---

# Fonts <span style="float: right"><sub><sup>3/3</sup></sub></span>

Once your font theme is created, you can reference it from a custom theme:

```css
/*! @theme my-custom-theme */

@import "my-font";
```

By default, this template uses [Ubuntu Sans](https://fonts.google.com/specimen/Ubuntu+Sans) and [Ubuntu Mono](https://fonts.google.com/specimen/Ubuntu+Mono) fonts. You can look up how they are used in `assets/css/fonts.css`, which gets imported from `assets/css/theme.css`.

---

# Marp CSS <span style="float: right"><sub><sup>1/2</sup></sub></span>

Aside from themes, you can style your slides directly from Markdown. There's two, _well three_, ways to style your slides:

```yaml
---
# Using frontmatter style directive (global)
style: |
  h1 { color: purple; }
---
```

```html
<!-- Using HTML <style> tags (applied to all slides) -->
<style>h1 { color: purple; }</style>
<!-- Using scoped HTML <style> tags (applies to a single slide) -->
<style scoped>h1 { color: purple; }</style>
```

---

# Marp CSS <span style="float: right"><sub><sup>2/2</sup></sub></span>

If you ever need to style the slide containers (i.e. `<section>` elements), you can use the `_class` directive:

```html
<!-- _class: lead -->
```

With this directive, the corresponding slide will have the `lead` CSS class, which can either be defined in the Marp theme or in the deck global styles, as shown in previous slide.

```html
<section class="lead" ...>
  ...
</section>
```

---

<style scoped>
  ul {
    text-align: center;
    list-style-position: inside;
  }
</style>

<!--
_class: lead
-->

# That's all folks!

You should now know enough to get started customizing your decks with:

- third party themes
- custom themes
- fonts
- in-deck styles and classes
