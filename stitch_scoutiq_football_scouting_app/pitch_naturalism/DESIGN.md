---
name: Pitch Naturalism
colors:
  surface: '#effee0'
  surface-dim: '#d0dfc2'
  surface-bright: '#effee0'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#eaf9db'
  surface-container: '#e4f3d5'
  surface-container-high: '#deedd0'
  surface-container-highest: '#d8e7ca'
  on-surface: '#131f0d'
  on-surface-variant: '#424841'
  inverse-surface: '#283420'
  inverse-on-surface: '#e7f6d8'
  outline: '#737970'
  outline-variant: '#c2c8be'
  surface-tint: '#466647'
  primary: '#001905'
  on-primary: '#ffffff'
  primary-container: '#102f15'
  on-primary-container: '#769976'
  inverse-primary: '#acd0aa'
  secondary: '#4d6537'
  on-secondary: '#ffffff'
  secondary-container: '#cce9af'
  on-secondary-container: '#516a3b'
  tertiary: '#131600'
  on-tertiary: '#ffffff'
  tertiary-container: '#272c01'
  on-tertiary-container: '#8e955d'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#c7ecc5'
  primary-fixed-dim: '#acd0aa'
  on-primary-fixed: '#022109'
  on-primary-fixed-variant: '#2e4e31'
  secondary-fixed: '#cfecb2'
  secondary-fixed-dim: '#b3cf97'
  on-secondary-fixed: '#0d2000'
  on-secondary-fixed-variant: '#364d22'
  tertiary-fixed: '#e1e8a8'
  tertiary-fixed-dim: '#c4cb8f'
  on-tertiary-fixed: '#1a1e00'
  on-tertiary-fixed-variant: '#444a1b'
  background: '#effee0'
  on-background: '#131f0d'
  surface-variant: '#d8e7ca'
typography:
  display-lg:
    fontFamily: Newsreader
    fontSize: 40px
    fontWeight: '600'
    lineHeight: 48px
    letterSpacing: -0.02em
  display-lg-mobile:
    fontFamily: Newsreader
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 38px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Newsreader
    fontSize: 28px
    fontWeight: '600'
    lineHeight: 34px
    letterSpacing: -0.015em
  headline-md:
    fontFamily: Newsreader
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 28px
    letterSpacing: -0.01em
  title-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 18px
    fontWeight: '700'
    lineHeight: 24px
  title-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 22px
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 15px
    fontWeight: '400'
    lineHeight: 22px
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
  label-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 13px
    fontWeight: '700'
    lineHeight: 18px
    letterSpacing: 0.02em
  label-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 11px
    fontWeight: '600'
    lineHeight: 14px
    letterSpacing: 0.04em
  stat-num-xl:
    fontFamily: Newsreader
    fontSize: 36px
    fontWeight: '500'
    lineHeight: 40px
    letterSpacing: -0.03em
  stat-num-md:
    fontFamily: Newsreader
    fontSize: 24px
    fontWeight: '500'
    lineHeight: 28px
    letterSpacing: -0.02em
rounded:
  sm: 0.5rem
  DEFAULT: 1rem
  md: 1.5rem
  lg: 2rem
  xl: 3rem
  full: 9999px
spacing:
  gutter: 1rem
  margin: 1.25rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style
The design system manifests an organic, high-performance ethos: the quiet authority of deep pitch turf combined with editorial analytical clarity. Built specifically for elite football talent spotters, sporting directors, and tactical coaches, the aesthetic rejects the neon, tech-heavy clutter of conventional sports analytics in favor of a timeless, country-club-meets-tactics-room refinement.

Visual styling combines warm organic minimalism with tactile elevation:
- **Atmospheric Palette:** Rooted in lush pitch hues (deep forest canopy, sun-drenched dry sage, pale mineral lime, and tender pastel mint).
- **Tactile Softness:** Hyper-smoothed geometry featuring expansive 24px surface radiuses balanced by continuous pill contours.
- **Editorial Legibility:** Literary, high-contrast serif headlines anchoring rapid, field-side scanning, paired with athletic geometric sans typography for high-density player data matrices.

## Colors
The palette is strictly restricted to five deliberate botanical and pitch-grade swatches:

- **Primary (`#102F15` - Dark Forest):** The structural anchor. Used for primary interactive actions, high-emphasis text, solid pill buttons, active navigation markers, and executive summary headers.
- **Secondary (`#728C5A` - Sage):** The contextual mid-tone. Applied to secondary metric copy, metric trend icons, micro-borders (applied at 20% to 40% alpha), inactive state accents, and technical charts.
- **Tertiary (`#EAF1B1` - Pale Lime):** The catalytic highlight. Reserved for breakout badges, peak-value percentiles (e.g., top 1% progressive passing), active filtering toggles, and tactical alert callouts.
- **Neutral / Canvas (`#EBFADC` - Pastel Mint):** The structural viewport foundation. Replaces stark clinical white with a calm, non-glare, organic pitch glow. Also serves as high-contrast inverted typography when rendered against Dark Forest cards.
- **Surface (`#FFFFFF` - Crisp White):** The primary card and sheet canvas. Provides crisp isolation and maximum legibility for dense scouting metrics against the Pastel Mint backdrop.

## Typography
Typographic rhythm pairs the classic literary authority of Newsreader with the ergonomic, athletic precision of Plus Jakarta Sans.

- **Editorial Hierarchy:** Player names, screen narrative titles, and monumental scouting evaluation grades utilize Newsreader. This evokes traditional bespoke scouting dossiers and legacy sports print journalism.
- **Metric System:** Quantitative outputs (xG, expected assists, completed dribbles, match ratings) balance Newsreader numbers with tight, uppercase Plus Jakarta Sans labels (`label-md`).
- **Body & Controls:** Interactive controls, search strings, bio snippets, and comparative metrics rely exclusively on Plus Jakarta Sans to maximize readability in rapid, bright daylight viewing environments.

## Layout & Spacing
A fluid 4-column mobile layout anchored by an 8pt architectural rhythm, optimized for handheld thumb navigation on touchscreens.

- **Canvas Margins:** Outer viewport gutters stay fixed at `1.25rem` (20px) on mobile to create comfortable edge clearance for gesture swipes.
- **Component Breathing Room:** Dense data grids (e.g., radar metric breakdown tables) use compact gaps (`space-xs` and `space-sm`), while player dossier sections maintain wide separations (`space-lg` to `space-xl`) to establish strong visual hierarchy.
- **Safe Viewport Allowance:** The bottom edge enforces a minimum clearance of `6rem` (96px) to accommodate the floating nav island without obscuring scrollable card content.

## Elevation & Depth
Depth is produced through ambient, natural light projection tinted in soft herbal green tones rather than artificial grey or black drop shadows.

- **Ambient Cast:** Base cards leverage `0 8px 24px -4px rgba(16, 47, 21, 0.06)`, imparting weightlessness against the `#EBFADC` pastel canvas.
- **Floating Island Elevation:** The bottom navigation bar and active floating action buttons float on a deep organic diffusion: `0 16px 36px -6px rgba(16, 47, 21, 0.16)`.
- **Micro-Boundaries:** Drop shadows pair with a subtle 1px border colored in Sage with 25% opacity (`rgba(114, 140, 90, 0.25)`). This maintains border crispness under direct stadium sunlight.

## Shapes
The design system enforces a clean binary shape hierarchy:

- **Large Structural Canvas:** Cards, modal bottom sheets, player dossier sheets, and metric modules are set strictly to `24px` (`rounded-3xl`).
- **Interaction Elements & Controls:** All action triggers, chips, search inputs, rating tags, and navigation frames are set to `9999px` (pure pill form).
- **Secondary Icon Anchors:** Quick-scout action triggers, shortlist bookmarks, and filter buttons feature circular 1:1 pill aspect ratios (`w-11 h-11 rounded-full`).

## Components

### Buttons
- **Primary Action:** Solid `#102F15` pill shape, text set in `#EBFADC` (`title-md`), minimum height of 48px with 24px horizontal padding. Subtle inward focus ring in `#EAF1B1`.
- **Secondary Action:** Transparent pill backed by a 1.5px `#728C5A` border (50% opacity), filled with `#FFFFFF` at resting state. Text set in `#102F15`.
- **Icon Buttons:** Circular pills (44px × 44px) in solid `#FFFFFF` with 1px Sage outline (`rgba(114, 140, 90, 0.3)`) and `#102F15` iconography.

### Chips & Badges
- **Active Filter Chip:** Filled in `#102F15`, typography in `#EBFADC`, pill-shaped, zero outline.
- **Inactive Filter Chip:** Filled in `#FFFFFF`, subtle 1px Sage boundary (`rgba(114, 140, 90, 0.3)`), label in `#728C5A`.
- **Metric Highlight Badge:** Accentuated in `#EAF1B1` with bold `#102F15` text (`label-md`). Used strictly for top-percentile data tags (e.g., "99th Percentile", "Target Profile").

### Cards
- **Standard Card:** Crisp `#FFFFFF` surface, `24px` radius, ambient green drop shadow, 1px perimeter border in Sage (`rgba(114, 140, 90, 0.2)`), inner padding of `1.25rem`.
- **Highlight Feature Card:** Solid `#102F15` surface, `24px` radius, typography set in `#EBFADC` and `#EAF1B1`, equipped with secondary stat annotations in `#728C5A`.

### Input Fields & Search Bars
- Pure pill search bars set against `#FFFFFF` with `1rem` horizontal padding and 48px height. Leading icon in `#728C5A`. Border styled in `rgba(114, 140, 90, 0.3)` transitioning to solid `#102F15` when active.

### Floating Navigation Bar
- A detached floating pill island pinned 16px above the mobile display bottom margin.
- Surface styled in pure `#FFFFFF` with an extra-diffused ambient shadow.
- Houses 5 symmetrical tabs: Home, Discover, Compare, Shortlist, Profile.
- **Active Tab:** Solid circular `#102F15` pill backing with `#EAF1B1` icon glyph.
- **Inactive Tab:** Unfilled background with `#728C5A` iconography.

### Specialized Scouting Data Components
- **Percentile Bar:** Track set in `rgba(114, 140, 90, 0.15)`, active progress bar filled in `#102F15` or `#EAF1B1` depending on value significance.
- **Comparison Metric Tile:** Split modular sub-cards displaying two player metrics side-by-side on clean `#FFFFFF` tiles, with the winning metric emphasized by a `#EAF1B1` pill outline.