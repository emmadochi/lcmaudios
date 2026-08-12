---
name: Premium Audio Design System
colors:
  surface: '#141313'
  surface-dim: '#141313'
  surface-bright: '#3a3939'
  surface-container-lowest: '#0e0e0e'
  surface-container-low: '#1c1b1b'
  surface-container: '#201f1f'
  surface-container-high: '#2b2a2a'
  surface-container-highest: '#353434'
  on-surface: '#e5e2e1'
  on-surface-variant: '#c7c6ca'
  inverse-surface: '#e5e2e1'
  inverse-on-surface: '#313030'
  outline: '#919094'
  outline-variant: '#46464a'
  surface-tint: '#c8c6c7'
  primary: '#c8c6c7'
  on-primary: '#313031'
  primary-container: '#0f0f10'
  on-primary-container: '#7d7b7c'
  inverse-primary: '#5f5e5f'
  secondary: '#ffb3ad'
  on-secondary: '#680009'
  secondary-container: '#b60319'
  on-secondary-container: '#ffc2bd'
  tertiary: '#e9c349'
  on-tertiary: '#3c2f00'
  tertiary-container: '#150e00'
  on-tertiary-container: '#967800'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#e5e2e3'
  primary-fixed-dim: '#c8c6c7'
  on-primary-fixed: '#1c1b1c'
  on-primary-fixed-variant: '#474647'
  secondary-fixed: '#ffdad6'
  secondary-fixed-dim: '#ffb3ad'
  on-secondary-fixed: '#410003'
  on-secondary-fixed-variant: '#930011'
  tertiary-fixed: '#ffe088'
  tertiary-fixed-dim: '#e9c349'
  on-tertiary-fixed: '#241a00'
  on-tertiary-fixed-variant: '#574500'
  background: '#141313'
  on-background: '#e5e2e1'
  surface-variant: '#353434'
typography:
  h1:
    fontFamily: Manrope
    fontSize: 40px
    fontWeight: '700'
    lineHeight: '1.2'
    letterSpacing: -0.02em
  h2:
    fontFamily: Manrope
    fontSize: 28px
    fontWeight: '600'
    lineHeight: '1.3'
    letterSpacing: -0.01em
  h3:
    fontFamily: Manrope
    fontSize: 20px
    fontWeight: '600'
    lineHeight: '1.4'
    letterSpacing: '0'
  body-lg:
    fontFamily: Manrope
    fontSize: 18px
    fontWeight: '400'
    lineHeight: '1.6'
  body-md:
    fontFamily: Manrope
    fontSize: 16px
    fontWeight: '400'
    lineHeight: '1.5'
  label-caps:
    fontFamily: Manrope
    fontSize: 12px
    fontWeight: '700'
    lineHeight: '1'
    letterSpacing: 0.1em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  unit: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  gutter: 16px
  margin: 20px
---

## Brand & Style

The design system is built to evoke the atmosphere of a high-end private listening lounge. It targets an audience that values high-fidelity sound and editorial-grade presentation. The brand personality is sophisticated, mysterious, and effortlessly confident.

The visual style leverages **Minimalism** to ensure the focus remains on the artist and the audio content, while using **Glassmorphism** to create a sense of physical depth and luxury. By combining deep charcoal surfaces with crimson accents, the system feels both aggressive and refined. Interaction patterns are intuitive and fluid, emphasizing a "tactile digital" experience where layers feel like polished glass and dark chrome.

## Colors

The palette is strictly dark-mode dominant to minimize eye strain and maximize the "glow" of the crimson and gold accents.

- **Deep Charcoal Black** serves as the infinite canvas, providing a sense of endless depth.
- **Rich Crimson Red** is used sparingly for active states, high-priority buttons, and critical branding moments.
- **Soft Red Gradient** adds a modern, vibrant energy to interactive elements like play sliders and primary CTAs.
- **Subtle Gold** is reserved exclusively for premium status, VIP badges, and high-tier subscription features.
- **Warm White** ensures high legibility without the harshness of pure white, maintaining the "luxury" aesthetic.

## Typography

This design system utilizes **Manrope** for its balanced, geometric, and modern characteristics. The type hierarchy is designed for quick scanning in a mobile environment while maintaining an editorial feel.

Large headlines use tight letter spacing and heavy weights to command attention, while body text uses generous line heights for maximum readability against dark backgrounds. Labels and secondary metadata utilize uppercase styling with increased tracking to create a "technical" luxury look, similar to high-end audio hardware interfaces.

## Layout & Spacing

The layout follows a **fluid grid** model optimized for handheld devices. It utilizes a 4-column structure for mobile, where the gutter remains fixed at 16px to maintain airiness.

The spacing rhythm is based on a 4px baseline. Components and containers should always use multiples of 8px for padding and margins to ensure a consistent vertical rhythm. Wide margins of 20px are used at the screen edges to prevent the UI from feeling cramped and to emphasize the "minimalist" luxury of whitespace.

## Elevation & Depth

Hierarchy is established through **Glassmorphism** and tonal stacking.

1.  **Base Layer (#0F0F10):** The main background.
2.  **Surface Layer (#1A1A1D):** Elevated containers (cards, navigation bars).
3.  **Glass Layer:** Semi-transparent overlays (10-20% opacity) with a 20px background blur (Backdrop Filter) and a subtle 1px inner border (white at 5% opacity) to simulate light catching the edge of the glass.
4.  **Shadows:** Shadows are highly diffused and soft. Use a shadow color of `#000000` at 40% opacity with a large blur radius (20px-40px) to create an ambient, atmospheric lift rather than a harsh drop shadow.

## Shapes

The shape language focuses on a "Rounded" aesthetic to feel modern and approachable yet professional.

- **Standard Containers:** Use a radius of 0.5rem (8px).
- **Large Cards & Album Art:** Use a radius of 1rem (16px) to create a distinct frame for visuals.
- **Pills/Badges:** Utilize full rounding for tags and status indicators.
- **Interaction Targets:** Buttons follow the 0.5rem standard, ensuring they feel substantial and easy to tap.

## Components

### Buttons
Primary buttons use the **Soft Red Gradient** with Warm White text. They should have a subtle outer glow (drop shadow) matching the crimson color to simulate an illuminated state. Secondary buttons are outlined in 1px Warm White (20% opacity) with glassmorphism backgrounds.

### Audio Player
The player is the hero component. It uses a full-screen glassmorphic overlay when expanded. The progress bar is a 4px thin line: the track is Crimson Red, and the remaining length is Deep Gray. The "Play" button is a large, floating action button with the Crimson gradient.

### Track Lists
Lists are clean with no dividers. Instead, use 16px of vertical spacing between items. Active tracks are indicated by a small Crimson dot and the text color shifting to Warm White, while inactive tracks remain at 60% opacity.

### Premium Badges
Badges are small, using the **Subtle Gold** color for both the icon and the text. Use the `label-caps` typography style for high-end readability.

### Input Fields
Inputs are minimalist: a bottom-border only or a subtle glassmorphic fill. Focus states should be indicated by the bottom border transitioning to the Crimson Red color.

### Icons
Use **thin-line (1px - 1.5px weight)** icons. They should be elegant and simple, never filled unless in an active/selected state.