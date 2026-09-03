# Project Rules — Physiqo

## Code Style

### Flutter / Dart
- Use `const` constructors everywhere possible
- `AppColors`, `AppTypography`, `AppSpacing` — never hardcode values inline
- RTL: wrap root with `Directionality(textDirection: TextDirection.rtl, ...)`
- All user-facing strings in Farsi — no English placeholder text
- `BorderRadius.circular(12)` for cards — not `BorderRadius.all(...)`
- Widget files: one widget per file, snake_case filenames
- Stateless by default; use `StatefulWidget` / Riverpod only when state is needed

### No-Glow Enforcement
```dart
// ALWAYS add this to ThemeData to remove ink splash glow:
splashFactory: NoSplash.splashFactory,
highlightColor: Colors.transparent,
splashColor: Colors.transparent,
```

### Color Usage Guard
```dart
// ✅ Correct
color: AppColors.primary  // orange on active element only

// ❌ Wrong — never fill large areas with orange
Container(color: AppColors.primary, ...)
```

## Files to Read First

### For any backend/data change
1. `app/lib/models/` — data models
2. `app/lib/services/` — API/service layer
3. `app/lib/providers/` — state management

### For any UI/screen change
1. `DESIGN.md` — colors, spacing, typography (source of truth)
2. Stitch MCP `get_screen` for the relevant screen ID (see AGENTS.md screen map)
3. `lib/theme/` — theme constants

### For navigation changes
1. Nav bar: 5 items, RTL order, center AI button is special
2. Check `lib/navigation/` for router setup

## Grep Before Opening
Always grep for these before opening files:
```
# Find color usage
grep_search "AppColors\." --include="*.dart"

# Find a specific screen widget
grep_search "class HomeScreen" --include="*.dart"

# Find spacing usage
grep_search "AppSpacing\." --include="*.dart"
```

## Common Pitfalls

1. **Glow on ListTile/InkWell** — Always set `splashColor: transparent` and `highlightColor: transparent`
2. **LTR layout creeping in** — Test every screen with RTL explicitly; Flutter defaults to LTR
3. **Orange overuse** — `primary (#FF6B2C)` is accent only. Background/fill = `surface (#2A2A2C)`
4. **Error red as accent** — `#FF3B30` is ONLY for declining metrics/negative values
5. **Card border missing** — Every card needs explicit `border: Border.all(color: AppColors.outline, width: 1)`
6. **Font fallback** — Always include `fontFamilyFallback: ['sans-serif']` for Farsi characters
7. **Image illustrations** — Must be white flat SVG on transparent. No color fills.
8. **Score numbers** — Must be `fontWeight: FontWeight.w700`, large, in orange if active

## Stitch MCP Quick Reference
```
Project ID: 7928721753590883638
Design System Asset: assets/59461979341228967  (Physiqo)

get_screen:
  name: "projects/7928721753590883638/screens/<SCREEN_ID>"
  projectId: "7928721753590883638"
  screenId: "<SCREEN_ID>"
```

## Traffic Conservation Rules
- Never trigger `npm install` commands that auto-download browsers
- Avoid `npx <package>` for packages not already cached (will download)
- Stitch MCP screenshot URLs are Google CDN — safe to fetch
- Do NOT run `npx playwright install` — user has limited internet
