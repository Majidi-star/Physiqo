---
name: Physiqo
colors:
  background: '#1C1C1E'
  surface: '#2A2A2C'
  surface-container: '#2A2A2C'
  surface-container-high: '#3A3A3C'
  on-surface: '#FFFFFF'
  on-surface-variant: '#8E8E93'
  primary: '#FF6B2C'
  on-primary: '#FFFFFF'
  outline: '#3A3A3C'
  outline-variant: '#3A3A3C'
  error: '#FF3B30'
  on-error: '#FFFFFF'
typography:
  headline-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
  headline-md:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
rounded:
  sm: 0.5rem
  DEFAULT: 0.75rem
  md: 0.75rem
  lg: 1rem
  xl: 1.25rem
  full: 9999px
spacing:
  base: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  gutter: 16px
---
# Design System: Physiqo
## Brand & Style
Physiqo is a premium AI-powered fitness and bodybuilding app. The visual 
identity is cinematic, dark, and precise — inspired by sci-fi HUD 
interfaces and high-end fitness brands like Whoop and Fitbod. The 
personality is confident, technical, and motivating.
The app is in Persian/Farsi with full RTL (right-to-left) layout 
throughout every screen.
## Colors
- **Primary accent (#FF6B2C):** Flat solid orange. Used exclusively for:
  active nav icons, active labels, primary card borders, CTA buttons, 
  timeline active nodes, score numbers, and progress bars.
  NEVER used as a large background fill except on primary CTA buttons.
  NEVER red, coral, neon, or glowing — always flat solid orange only.
- **Background (#1C1C1E):** Dark charcoal. Applied as a subtle radial 
  gradient — slightly lighter near center content, darker toward edges. 
  Strictly grayscale gradient, no color tint whatsoever.
- **Surface (#2A2A2C):** Card backgrounds. Slightly lighter than the 
  main background to create elevation through tonal contrast.
- **Outline (#3A3A3C):** 1px card borders. Primary/active cards get a 
  flat solid orange border. All other cards get this neutral border.
- **On-surface (#FFFFFF):** Primary text color.
- **On-surface-variant (#8E8E93):** Secondary/metadata text, 
  inactive nav labels, inactive nav icons.
- **Error (#FF3B30):** Reserved EXCLUSIVELY for negative values and 
  decline indicators (e.g. a score that dropped). Never used as a 
  brand or accent color anywhere.
## No Glow Rule
Absolutely no glow, bloom, blur, neon, or soft shadow effects on any 
UI element under any circumstances. All color is flat and solid. 
Cards are elevated via a thin 1px border and a subtle non-glowing 
drop shadow only.
## Typography
All text is in Persian/Farsi. Layout is RTL throughout.
Font: Inter (or system sans-serif fallback).
Large score numbers are displayed in bold geometric style, very large.
Section headers pair with a supporting data point on the same row.
No standalone floating labels with empty space around them.
## Navigation Bar
5 items: خانه | تمرینات | [CENTER] | اسکن بدن | تنظیمات
- No filled background, pill, or highlight behind any icon
- Active icon strokes = flat solid orange (#FF6B2C)
- Active label = flat solid orange (#FF6B2C)  
- Inactive icons and labels = gray (#8E8E93)
- Center AI coach button: elevated above other nav items, larger size,
  icon is a circular waveform ring of dense radial orange spikes 
  varying in height — no filled circle behind it, ring stands alone
## Cards
- Background: #2A2A2C
- Border: 1px solid #3A3A3C for standard cards
- Border: 1px solid #FF6B2C for primary/active/featured card only
- Corner radius: 12px
- No glow, no heavy shadow
## Logo
Wordmark: "Physiqo" with double chevron mark to the left.
Always flat, no gradient, no glow.
Orange chevrons, white wordmark text.
## Illustrations
Exercise illustrations are clean flat white line-art only.
Pure white strokes on dark charcoal — no color fills, no gradients,
no warm tones, no pink or purple contamination.
All exercise illustrations identical in style regardless of 
selected/unselected card state.
Selected state is communicated only by the card border color.
## Layout Rules
- No duplicate information on any single screen
- Section headers always pair with a data point on the same row
- No more than 2-3 horizontal info bands before reaching main content
- Generous negative space between sections
- All RTL — text right-aligned, layout mirrors left-to-right convention