# Sky Global — build notes (Phase 1 static prototype)

Living notes for the eventual Next.js + Supabase + admin handoff.

## Stack (current)
- Static HTML / CSS / vanilla JS, no build step.
- `assets/theme.css` — design system (tokens, components, RTL).
- `assets/app.js` — behaviour: i18n toggle (data-en / data-ar attributes),
  header state, mobile menu, **expanding company panels**, count-ups,
  GSAP + ScrollTrigger motion layer (vendored: `assets/gsap.min.js`,
  `assets/scrolltrigger.min.js`), with a CSS/IntersectionObserver fallback.
- `server.pl` — tiny local static server (`perl server.pl 4321`).
- `build-artifact.pl` + `publish.sh` — inline everything into one file for
  the hosted claude.ai previews (CDNs are blocked there).

## "Our Companies" — expanding panels
The interaction (row of panels; hovered/focused panel expands via animated
`grid-template-columns`, others collapse to vertical-label strips; layered
content reveal) is implemented in vanilla JS (`[data-expand]` handler in
`app.js`) + CSS (`.co-expand` / `.co-panel` in `index.html`). Mobile falls
back to a vertical accordion (`grid-template-rows`).

**Panel visual system (redesigned per client, 2026-09-01) — one system, all
five identical, differing only in logo + watermark:** a 1px `#e5e7eb`
hairline divides panels; each company's own colour logo is enlarged and
centred when expanded (`.c-logo`); the caption (title / sector / description
/ link) is anchored to the panel bottom (`.c-cap`) and reveals with a
stagger.

- **Expanded** panel: solid white, faint (~6%) centred `.wm` behind the logo.
- **Collapsed** panel: soft gradient — `radial-gradient` + `linear-gradient`
  both keyed off `--ca` at 5–13% (so each panel is tinted with its own
  accent) — plus the `.wm` re-anchored to the bottom edge, oversized (200%
  wide) and bled off-frame at ~11% opacity as a composition anchor. The
  strip shows: accent dot (`.s-dot`) → small company emblem
  (`.s-ic` = `<img>` of `assets/img/icon-<co>.svg`) → vertical brand-dark
  name (`.s-nm`, `#1e4875`).
- Mobile (≤860px): collapsed rows use a horizontal gradient + centred small
  `.wm`; strip is a horizontal row.

When editing, keep the five structurally identical — only `--ca`, `.wm`
contents, `.c-logo` contents and the `.s-ic` icon file should differ.
`assets/img/icon-*.svg` = emblem-only marks (NHeroes swoosh, Talawin
emblem, SG monogram in each blue, Fluiday badge) with explicit width/height
so `<img>` gets an intrinsic aspect ratio.

**Future upgrade (Phase 2 / Next.js):** this pattern can be re-expressed as a
React component (the client had a React + TypeScript + shadcn reference).
Behaviour to preserve: animated column expansion, collapsed strips, staggered
icon → title → sector → description reveal, desaturate→saturate on the panel
background, keyboard: first Enter expands, second Enter follows the link.

## Hero — full-bleed image + load-reveal + Ken Burns + parallax (current)
`<section class="hero" id="hero">`:
- **Full-bleed image** `[data-hero-img]` (`assets/img/hero-tower.jpg` — PLACEHOLDER
  glass tower; client to supply the real tall skyscraper, ideally 2× res).
- **Duotone** (`.hero-duotone`): image is `filter: grayscale(1)`; a brand-blue
  vertical gradient (`#4f7cae → #2d5d94 → #1e4875 → #142f4d`) with
  `mix-blend-mode: color` recolours it, plus a `multiply` layer for depth.
- **Legibility** (`.hero-grad`): strong bottom→top dark gradient + a diagonal
  left wash + a soft vignette, so white text stays readable.
- **Animations** (`initHero()` in `app.js`, GSAP):
  1. Load reveal — `clip-path: inset(100% 0 0 0) → inset(0)` bottom-to-top, 1.35s
     `power2.inOut`.
  2. `[data-hero-text]` (inner / quote / stats) fade-up + stagger right after.
  3. Ken Burns — `scale 1 → 1.08`, 13s, `power1.inOut`, `yoyo repeat:-1`.
  4. Parallax — `.hero-bg` `yPercent: 15` on ScrollTrigger scrub (bg is oversized
     `inset: -9% 0` for headroom).
- **Mobile / touch / reduced-motion**: Ken Burns + parallax are disabled
  (`light` gate = `max-width:760` OR `pointer:coarse`); reveal + fade kept.
- **Self-healing**: an inline `<script>` right after the hero sets the
  pre-animation state before first paint and, if `app.js` never runs, restores
  the resting state after 4s (`window.__heroInit` flag).

### Phase-2 (Next.js) notes
- Replace `<img>` with `next/image` (`fill`, `priority`, `sizes="100vw"`,
  responsive `srcSet`). Keep `object-position: 50% 28%`.
- The duotone/gradients are pure CSS — carry over unchanged.
- GSAP `initHero()` moves into a client component (`"use client"`, run in
  `useLayoutEffect` inside `gsap.context()` for cleanup).

### Optional Phase-2 upgrade: scroll-expand intro
An earlier build had a scroll-driven opening: the brand media starts small and
centred, a GSAP ScrollTrigger pinned+scrubbed timeline grows it to full-bleed
while the title "SKY GLOBAL / HOLDING" splits apart and the rest of the hero
fades in. It was removed at the client's request but the approach is sound if
revisited. Behaviour to preserve: scroll progress 0→1 drives the media size and
the title translateX; content fades in near progress 1; title splits into the
two brand words. framer-motion's `useScroll` + `useTransform` map onto this
directly; or keep GSAP ScrollTrigger. Full removed implementation (HTML + CSS +
JS + a framer-motion mapping) is saved in `reference/scroll-expand-hero.md`.

## Placeholders to replace before launch
- **SG logo**: real vector is in (`#sgMark` symbol). Gradient `#7C8AD0 → #33469C`
  chosen to match the PDF's rendered appearance — confirm with client.
- **Company logos** (in the panels, colour, centred) — now REAL vectors
  extracted from the client's source PDFs (2026-09-01), inline in
  `index.html` and mirrored at `assets/img/logo-{nheroes,talawin,fluiday}.svg`:
  - NHeroes ← `ان هيروز/NHEROES LOGO SOURCE.pdf` (mark = PDF vector paths;
    "NHEROES" = embedded NimbusSansME-Demi font outlined).
  - Talawin Marha ← `تلاوين مرحة/شعار تلاوين مرحة.pdf` (emblem + wordmark,
    maroon #993D3D). The tiny Arabic strap-line (live CFF text) is
    deliberately omitted at panel size — add it for the Talawin page /
    footer from a logo file with it outlined.
  - Fluiday Auto ← `فلودي/FLUIDAY Identity.pdf` p.1 (badge + grey shadow +
    white "Fluiday Auto" + ®). Red = #ED1C24 (brand-guide value; file
    stores CMYK 0/100/100/0).
  - Sky Global Contracting & Financial Consulting = real `#sgMark`
    monogram (#2d5d94 / #1f7ac2) — confirm the correct per-company lockup.
  Extraction pipeline (no poppler/Python on this machine):
  `tools/pdfdump.pl` (inflate PDF streams), `tools/p2s.pl` (content
  stream -> SVG paths), `tools/ttf2path.pl` (embedded TrueType -> outlines),
  `tools/mksvg.pl` (crop + assemble).
- **Hero background photo** (`assets/img/hero-tower.jpg`) — placeholder
  architecture shot; needs an owned / licensed image.
- **Numbers**: founding year (2014), partner count (1,500+), sector count —
  bracketed placeholders in the client's own docs; labelled on the page.
- **Founders' bios**, **interactive markets map**, **partner logos**,
  **project photography / video** — all client-supplied, via the CMS in Phase 2.
- **English copy** — professional draft translation of the Arabic source docs;
  native Arabic proofing recommended pre-launch.

## Phase 2 (planned)
Next.js (App Router) + Tailwind + Supabase (Postgres + Storage), deployed on
Vercel via GitHub. Password-protected `/admin` to edit all text / numbers /
images / logos in both languages and add/remove leadership, companies, values,
portfolio items. Content model already CMS-shaped (every editable string is a
`data-en` / `data-ar` pair; stats and lists are discrete).
