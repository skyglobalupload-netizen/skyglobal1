# Sky Global Holding — Website

Bilingual (Arabic-first / English, full RTL) marketing website for **Sky Global Holding**
(سكاي جلوبال القابضة) and its five subsidiaries.

Plain static HTML / CSS / vanilla JavaScript — **no build step**. Deploys as-is to any
static host.

---

## Pages

| Path | Page |
|------|------|
| `/index.html` | Sky Global Holding — single-page (About, Companies, Vision & Mission, Group Services, Leadership, Numbers, Contact) |
| `/companies/fluiday-auto.html` | Fluiday Auto — automotive chemicals |
| `/companies/nheroes.html` | NHeroes — marketing agency & software house |
| `/companies/talawin-marha.html` | Talawin Marha — creative & experience design |
| `/companies/sky-global-contracting.html` | Sky Global Contracting — construction |
| `/companies/sky-global-financial-consulting.html` | Sky Global Financial Consulting — audit / zakat / tax |

## Repository structure

```
.
├── index.html                 site entry point (served at /)
├── companies/                 the 5 subsidiary pages
├── assets/
│   ├── theme.css              shared design system (tokens, layout, RTL, components)
│   ├── app.js                 shared JS (language toggle, menus, scroll reveals, counters)
│   ├── img/                   images, logos, icons
│   └── video/fl/hero.mp4      Fluiday Auto hero video
├── vercel.json                caching headers for Vercel
├── .vercelignore              keeps build-tools/ out of the deployment
├── .gitignore
└── build-tools/               NOT deployed — Perl scripts used during design
                               (single-file page bundler, local preview server,
                               logo vector-extraction) + developer notes
```

## Run locally

Any static server works. Examples:

```bash
# Python (built in on macOS / Linux)
python -m http.server 8000        # → http://localhost:8000

# Node
npx serve

# or the bundled Perl server
perl build-tools/server.pl 4321   # → http://127.0.0.1:4321
```

Preview switches (dev only): `index.html?nofx` disables animations;
`index.html?hero=abstract` shows the old abstract hero instead of the photo.

## Deployment (Vercel)

- Framework preset: **Other** (static). No build command, no install command.
- Output directory: **`.`** (repo root).
- `vercel.json` sets long-cache headers for `/assets/**` and no-cache for HTML.

## Editing

- **Copy** is stored inline as `data-en="…"` / `data-ar="…"` attribute pairs on each
  element; `app.js` swaps them on language change. Edit both to change text.
- **Colours / spacing / fonts** are CSS custom properties at the top of `assets/theme.css`
  and, per subsidiary, in a `<style>` block at the top of that company's HTML file.
- **Fonts** load from Google Fonts; the site falls back to system fonts if offline.

## Before public launch — outstanding items

**Replace stock imagery (not licensed to Sky Global):**
- `assets/img/hero-jeddah.jpg` — home hero
- `assets/img/fcs/hero.jpg`, `fcs/report.jpg`, `fcs/accounting.jpg` — Financial Consulting

**Fill placeholder slots** (shown on the pages as dashed boxes):
- Fluiday Auto: about photo, radiator-cleaner & spare-parts photos, 3 motorsport photos,
  distribution map, 4 partner logos
- Sky Global Contracting: 4 project-gallery photos
- Talawin Marha: products / portfolio section
- NHeroes: hero photo/video, client logos, video-portfolio thumbnails

**Confirm placeholder data:**
- Founding year (2014) and the "1500+ partners & clients" figure — both marked "(مبدئي)"
- Founder headshots + bios (Hisham Almuflehi, Wajdi Bamfleh)
- Each company's own phone / email (all currently show the group's
  `info@skyglobalworld.com` / `+966 12 206 8728`)
- Contracting name: content says "سكاي جلوبال العقارية", pages say "سكاي جلوبال للمقاولات"
- Native Arabic review of agency-drafted copy (Financial & NHeroes "من نحن", Talawin EN)

**Wire the footer newsletter field to a real provider** (currently shows a thank-you only).

## Roadmap

Migration to **Next.js + Tailwind + GSAP** with a password-protected admin/CMS (Supabase)
so non-technical staff can edit all text, numbers, images and logos in both languages.
This repo is the design reference and content source for that work.

---

© Sky Global Holding. All rights reserved.
