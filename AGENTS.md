# AGENTS.md — Physiqo App

## Project Overview
Physiqo is a premium AI-powered fitness and bodybuilding Flutter app. Cinematic dark UI, Persian/Farsi language, full RTL layout. The Stitch MCP project ID is `7928721753590883638`.

## Stack
| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) |
| Language | Persian/Farsi (RTL) |
| Design Source | Stitch MCP (`projects/7928721753590883638`) |
| Design Tokens | `c:\Projects\Physiqo\app\Design.md` |
| Font | Inter |

## File Map
```
c:\Projects\Physiqo\
  app/
    Design.md          ← PRIMARY design token source (colors, typography, spacing, radii)
  mcp_config_fix.json  ← Updated MCP config (use @playwright/mcp)
  install_chromium.ps1 ← Playwright setup script (one-time)
```

## Design Tokens (from Design.md + Stitch)

### Colors
| Token | Hex | Usage |
|---|---|---|
| background | `#1C1C1E` | App background (subtle radial gradient) |
| surface | `#2A2A2C` | Card backgrounds |
| surface-container-high | `#3A3A3C` | Elevated surfaces |
| on-surface | `#FFFFFF` | Primary text |
| on-surface-variant | `#8E8E93` | Secondary text, inactive nav |
| primary | `#FF6B2C` | Active icons, borders, CTAs, scores |
| on-primary | `#FFFFFF` | Text on orange buttons |
| outline | `#3A3A3C` | Card borders (standard) |
| error | `#FF3B30` | Negative values ONLY |

### Typography (all Inter)
| Style | Size | Weight | Line Height |
|---|---|---|---|
| headline-lg | 32px | 700 | 40px |
| headline-md | 24px | 700 | 32px |
| body-lg | 16px | 400 | 24px |
| body-md | 14px | 400 | 20px |
| label-md | 12px | 500 | 16px |

### Spacing
`xs=4px` · `sm=8px` · `md=16px` · `lg=24px` · `xl=32px` · `gutter=16px`

### Border Radius
`sm=8px` · `md=12px` · `lg=16px` · `xl=20px` · `full=9999px`
Card standard radius: **12px**

## Stitch Screens (Active / Non-hidden)
| Screen ID | Label | Size |
|---|---|---|
| `cc71aa8122714c128044765b21877a68` | **analysis screen** ← reference | 704×1520 |
| `be8c986930544d5980c71406179c3065` | Home screen | 768×1376 |
| `5d5100a51887436fb670e8a54f96c360` | body screen | 768×1376 |
| `353368094d1742328f0fc45b573ff6c0` | Moves screen | 768×1376 |
| `6f37322c3cb14953af87193ac26eec17` | focused move screen | 768×1376 |
| `165aaf697a7946cfb4b03367eda842e3` | Settings | 704×1520 |
| `47a9f978ebda4bd78731ac48783e65e2` | chat screen | 704×1520 |

## Key Design Rules (NEVER violate)
1. **No glow** — No bloom, neon, blur, or soft shadow on any element. Flat solid color only.
2. **Orange is accent-only** — Never as large background fill. Only on active states, borders, CTAs, scores.
3. **Error red is negative-only** — `#FF3B30` exclusively for declining scores/values. Never as brand color.
4. **RTL everywhere** — All text right-aligned, layout mirrored. Persian/Farsi strings.
5. **Card borders** — Standard: 1px `#3A3A3C`. Active/primary: 1px `#FF6B2C`. Always 12px radius.
6. **Nav bar** — No filled background behind icons. Active=orange, Inactive=`#8E8E93`.
7. **Illustrations** — White flat line-art only. No color fills, no gradients.
8. **No duplicate info** — Section headers always pair with a data point on same row.

## Navigation Bar Items (RTL order)
```
تنظیمات | اسکن بدن | [CENTER AI ⊙] | تمرینات | خانه
```
Center AI button: circular waveform ring of dense radial orange spikes, no filled circle behind it, elevated above other items.

## Session Rules
- **grep before view_file** — Always search for a symbol/token before opening a file
- **Design.md is source of truth** — Never invent color/spacing values; extract from Design.md or Stitch
- **Stitch MCP for visuals** — Use `get_screen` + `list_screens` for any visual reference
- **No big downloads** — User has limited internet; avoid triggering npm installs that download browsers
- **After architecture change** — Update this AGENTS.md

## MCP Config Fix
The user's `mcp_config.json` needs updating. See `c:\Projects\Physiqo\mcp_config_fix.json` — replace content in `C:\Users\Amirhosein\.gemini\config\mcp_config.json` manually.
