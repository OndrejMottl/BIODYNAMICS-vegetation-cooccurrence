# BIODYNAMICS brand guide

Based on the BIODYNAMICS description, the brand direction is **terminal ecology**: computational, research-heavy, slightly archival, and dark-mode-first.

## Recommended direction

Think **retro programming lab**, not cyberpunk:

- deep graphite backgrounds
- phosphor-green accents
- syntax-style amber and magenta used sparingly
- clean scientific typography
- subtle grid / terminal / contour-map textures

The key idea is **serious science first, retro code second**.

## Color brand guide

### Core neutrals

Use these for most of the interface.

- **Midnight** `#0B0F14` — page background
- **Console Panel** `#141B22` — cards, nav, code blocks
- **Slate Border** `#2A3441` — rules, dividers, subtle frames
- **Bone Text** `#E6EDF3` — primary text
- **Muted Mist** `#98A6B3` — secondary text, captions

### Brand accents

Use these for links, calls to action, highlights, and data.

- **Phosphor Green** `#8DF59A` — primary brand accent
- **Moss Teal** `#48C7B8` — secondary accent, climate/data cues
- **Cursor Amber** `#FFB35C` — hover, emphasis, timeline markers
- **Syntax Magenta** `#D98CFF` — annotations, tags, selected states
- **Signal Red** `#FF7B72` — warnings / errors only

### Usage rules

- Keep the site mostly **Midnight + Bone Text**
- Let **Phosphor Green** do the brand work
- Use **Amber** and **Magenta** as syntax accents, not main colors
- Prefer **Teal** for charts and scientific graphics
- Never put long paragraphs in green on black

Suggested balance:

- 70% dark neutrals
- 20% text / structural contrast
- 10% accent colors

## Font brand guide

### Recommended pairing

- **Headings / nav / labels / code:** `IBM Plex Mono`
- **Body copy / long reading:** `IBM Plex Sans`

This pairing supports the concept well: technical and slightly retro, but still appropriate for a serious research project.

### Why it works

- mono for headings gives the programming identity
- sans for body keeps pages readable
- both belong to the same family, so the system feels cohesive

### Usage rules

- **H1–H3:** IBM Plex Mono, weight 600
- **Body:** IBM Plex Sans, weight 400–500
- **Buttons / labels / metadata:** IBM Plex Mono, weight 500
- **Figures / tables / numeric outputs:** use tabular numerals where possible

### More stylized alternative

If you want slightly more attitude:

- `Space Mono` for headings
- `Source Sans 3` or `Inter` for body

Default recommendation remains **IBM Plex Mono + IBM Plex Sans**.

## Visual language

Use:

- thin borders
- rectangular or slightly rounded cards
- subtle glow only on active elements
- faint grid, scanline, or contour overlays
- code-editor-inspired section dividers
- restrained iconography

Avoid:

- heavy gradients
- glossy UI
- giant neon effects
- all-caps everywhere
- full-monospace body text

## Quick brand summary

- **Mood:** midnight lab workstation
- **Tone:** precise, technical, ecological, data-native
- **Look:** dark console + scientific dashboard
- **Texture:** terminal + atlas + biodiversity mapping

## Starter design tokens

```scss
@import url('https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:wght@400;500;600&family=IBM+Plex+Sans:wght@400;500;600;700&display=swap');

:root {
  --bd-bg: #0B0F14;
  --bd-surface: #141B22;
  --bd-border: #2A3441;
  --bd-text: #E6EDF3;
  --bd-muted: #98A6B3;

  --bd-green: #8DF59A;
  --bd-teal: #48C7B8;
  --bd-amber: #FFB35C;
  --bd-magenta: #D98CFF;
  --bd-red: #FF7B72;
}

body {
  background: var(--bd-bg);
  color: var(--bd-text);
  font-family: "IBM Plex Sans", system-ui, sans-serif;
}

h1, h2, h3, nav, .navbar, .menu-text, code, pre {
  font-family: "IBM Plex Mono", monospace;
}

a {
  color: var(--bd-green);
}

code, pre {
  background: var(--bd-surface);
  border: 1px solid var(--bd-border);
}

.card, .panel, .sidebar {
  background: var(--bd-surface);
  border: 1px solid var(--bd-border);
}
```

## Suggested next step

Turn this into a Quarto `_brand.scss` covering:

- navbar
- links
- code blocks
- callouts
- chart colors

