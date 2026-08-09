# VITRUVIAN — Flutter App PLAN.md
> AI-powered body analysis & training plan app
> Built in Flutter via Antigravity. Read this entire file before writing a single line of code.

---

## 1. DESIGN TOKENS (Source of Truth — Never Deviate)

### Colors
```dart
// lib/theme/tokens.dart
const kBackground        = Color(0xFF1C1C1E);
const kSurface           = Color(0xFF2A2A2C);
const kSurfaceHigh       = Color(0xFF3A3A3C);
const kOnSurface         = Color(0xFFFFFFFF);
const kOnSurfaceVariant  = Color(0xFF8E8E93);
const kPrimary           = Color(0xFFFF6B2C);
const kOnPrimary         = Color(0xFFFFFFFF);
const kOutline           = Color(0xFF3A3A3C);
const kError             = Color(0xFFFF3B30);
```

### Typography — Inter only
| Token       | Size | Weight | Line Height | Tracking |
|-------------|------|--------|-------------|----------|
| displayLg   | 32px | 900    | 40px        | -0.02em  |
| headlineMd  | 24px | 700    | 32px        | -0.01em  |
| bodyLg      | 16px | 400    | 24px        | 0        |
| bodyMd      | 14px | 400    | 20px        | 0        |
| labelMd     | 12px | 500    | 16px        | 0.08em   |

### Spacing (8pt grid)
```
xs=4, sm=8, md=16, lg=24, xl=32, gutter=16
```

### Border Radius
```
sm=8, md=12, lg=16, xl=20, full=9999
```

### Shadows
```dart
BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0,4))
```

---

## 2. PACKAGES — Add all of these to pubspec.yaml before any screen work

```yaml
dependencies:
  flutter_animate: ^4.5.0        # micro-interactions & entrance animations
  shimmer: ^3.0.0                # skeleton loading states
  flutter_staggered_animations: ^1.1.1  # list reveal animations
  image_picker: ^1.1.2           # camera & gallery access
  http: ^1.2.1                   # API calls
  google_fonts: ^6.2.1           # Inter font
  lottie: ^3.1.2                 # loading animation (body scan)
  percent_indicator: ^4.2.3      # circular progress for muscle groups
  cached_network_image: ^3.3.1   # image caching
```

---

## 3. SCREENS (4 total — build in this exact order)

---

### SCREEN 1 — Onboarding / Splash

**Purpose:** First impression. Must feel premium in 3 seconds.

**Layout:**
- Full black background (`kBackground`)
- Centered Vitruvian SVG logo, 120×120px
- Logo entrance: fade in + scale from 0.8 → 1.0, spring curve, 800ms delay
- Below logo: app name "VITRUVIAN" in displayLg, white, tight tracking, staggered fade-in after logo
- Tagline: "Know your body. Build your best." in bodyMd, `kOnSurfaceVariant`, fades in 200ms after title
- Bottom: Full-width CTA button "GET STARTED" — `kPrimary` background, white text, labelMd uppercase, 56px height, rounded-xl, slight glow: `BoxShadow(color: kPrimary.withOpacity(0.4), blurRadius: 20, spreadRadius: 0)`
- Button entrance: slides up from bottom, 400ms, elastic curve

**Animations:**
- Sequence: logo → title → tagline → button (staggered 150ms each)
- Use `flutter_animate` `.fadeIn().scale()` chain

---

### SCREEN 2 — Camera Capture

**Purpose:** User takes or uploads a full-body photo.

**Layout:**
- Dark background
- Top: back arrow + "Body Scan" title in headlineMd, centered
- Camera preview area: 
  - Rounded-xl container, full width, 70% of screen height
  - Inside: body outline guide SVG overlay (standing human silhouette, stroke only, `kPrimary.withOpacity(0.4)`, no fill)
  - Corner bracket markers at 4 corners of the guide (like ID photo alignment guides) in `kPrimary`
  - Pulsing animation on the guide: opacity oscillates 0.3 → 0.7, 2s loop, ease-in-out
- Below camera area, 3 buttons in a row:
  - Gallery icon (left): circular, `kSurface` bg, `kOnSurfaceVariant` icon
  - Capture button (center): 72px circle, `kPrimary` bg, white camera icon, subtle outer ring in `kPrimary.withOpacity(0.3)`, pulsing
  - Flip camera icon (right): circular, `kSurface` bg, `kOnSurfaceVariant` icon
- Bottom hint text: "Stand 2m away · Full body visible · Good lighting" in labelMd, `kOnSurfaceVariant`, centered

**Animations:**
- On capture tap: button scales down 0.9 then back, 200ms spring
- Transition to Screen 3: captured image slides up as a card while analysis screen fades in behind it

---

### SCREEN 3 — Analysis Reveal (MONEY SHOT — maximum polish here)

**Purpose:** AI analyzes the photo. This screen sells the entire app.

**3a — Loading State (while API call runs):**
- Show captured photo as full-screen blurred background (`ImageFilter.blur(sigmaX:20, sigmaY:20)`)
- Dark overlay on top: `kBackground.withOpacity(0.85)`
- Center: Lottie animation of a body scan (use a scanning beam / radar sweep Lottie from lottiefiles.com — search "body scan" or "radar scan", pick a minimal orange one)
- Below animation: "Analyzing your physique..." in bodyLg, white
- Skeleton shimmer cards loading below (3 placeholder muscle group cards)
- CRITICAL: Also trigger cached fallback response simultaneously (see Section 5)

**3b — Results State (after API returns):**
- Top half: photo thumbnail (small, rounded-lg, top-right corner)
- "YOUR ANALYSIS" label in labelMd, `kOnSurfaceVariant`, uppercase
- Overall score: large number (e.g. "74") in displayLg, `kPrimary`, with "/100" in headlineMd, `kOnSurfaceVariant`
- Subtitle: "Physique Balance Score" in bodyMd, `kOnSurfaceVariant`

- **Body Region Cards** — staggered list reveal (flutter_staggered_animations):
  Each card: `kSurface` bg, rounded-lg, border in `kOutline`, left accent bar color-coded:
  - 🟢 Green (`0xFF34C759`) = Strong
  - 🟡 Amber (`0xFFFF9F0A`) = Developing  
  - 🔴 Red (`0xFFFF3B30`) = Needs Work
  
  Card content:
  - Region name (e.g. "Chest", "Shoulders", "Core") in headlineMd
  - Status label in bodyMd, color-matched to accent
  - Brief AI note in bodyMd, `kOnSurfaceVariant` (1 line max)
  - Circular percent indicator (percent_indicator) showing score 0–100, color-matched

- Tap a card → it expands inline to show full AI detail text (AnimatedContainer, spring curve)

- Bottom sticky button: "BUILD MY PLAN" — same style as Screen 1 CTA

**Animations:**
- Results entrance: overall score counts up from 0 → final number, 1.2s, ease-out
- Cards stagger in from bottom, 80ms between each
- Each card: `.fadeIn().slideY(begin: 0.3)`

---

### SCREEN 4 — Training Plan

**Purpose:** Personalized workout generated from the analysis.

**Layout:**
- Header: "YOUR PLAN" in displayLg + week label ("Week 1") in bodyMd, `kOnSurfaceVariant`
- Day selector: horizontal scrollable pill tabs (Mon–Sun), active = `kPrimary` bg, inactive = `kSurface`
- Exercise list (staggered reveal on day change):

  Each exercise card: `kSurface` bg, rounded-lg, border `kOutline`
  - Left: exercise index number in displayLg, `kPrimary.withOpacity(0.3)` (watermark style)
  - Exercise name in headlineMd
  - Target muscle in bodyMd, `kPrimary`
  - Sets × Reps grid (3 columns):
    | SETS | REPS | REST |
    |------|------|------|
    |  4   |  12  | 60s  |
    Each cell: value in headlineMd white, label in labelMd `kOnSurfaceVariant`
  - Checkmark button (right): circular, `kSurface` border → fills `kPrimary` on tap with spring animation + scale pop

- Bottom: "COMPLETE DAY" full-width button, `kPrimary`

**Animations:**
- Day switch: old list fades out (150ms), new list staggers in (80ms per card)
- Checkmark completion: scale 1.0 → 1.3 → 1.0, spring, `kPrimary` fill animates in
- "COMPLETE DAY" button: slides up from below on first card check

---

## 4. API ARCHITECTURE

### Two-API Split

**API 1 — Gemini Flash (Photo Analysis)**
- Endpoint: `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent`
- Free tier: ~15 RPM, no card required
- Get key: aistudio.google.com

**Prompt to send with the image:**
```
You are an expert fitness coach and body composition analyst. Analyze this full-body photo and return ONLY a JSON object with this exact structure, no markdown, no explanation:

{
  "overall_score": <number 0-100>,
  "regions": [
    {
      "name": "<muscle group>",
      "status": "strong" | "developing" | "needs_work",
      "score": <number 0-100>,
      "note": "<one sentence assessment>"
    }
  ],
  "summary": "<2 sentence overall assessment>"
}

Assess these regions: Chest, Shoulders, Back, Arms, Core, Legs. Be honest and constructive.
```

**API 2 — NVIDIA NIM (Training Plan)**
- Endpoint: `https://integrate.api.nvidia.com/v1/chat/completions`
- Model: `deepseek-ai/deepseek-r1`
- Free: 1000 credits, 40 RPM
- Get key: build.nvidia.com

**Prompt (send the analysis JSON as context):**
```
You are an elite personal trainer. Based on this body analysis JSON: {ANALYSIS_JSON}

Return ONLY a JSON object, no markdown, no explanation:

{
  "plan_name": "<personalized plan name>",
  "days": [
    {
      "day": "Monday",
      "focus": "<muscle group focus>",
      "exercises": [
        {
          "name": "<exercise name>",
          "target_muscle": "<primary muscle>",
          "sets": <number>,
          "reps": <number or "8-12">,
          "rest_seconds": <number>
        }
      ]
    }
  ]
}

Create a 5-day plan (Mon-Fri) that prioritizes the weak areas identified in the analysis. 4-6 exercises per day.
```

---

## 5. FALLBACK CACHE (Demo Protection)

```dart
// lib/data/fallback_response.dart
// Pre-run the full API flow once before any client demo.
// Store the response here as a const.
// If API call takes > 8 seconds OR throws any error, use this cached response.
// The UI must never show an unresolved spinner in front of a client.

const kFallbackAnalysis = '''{ ... paste your pre-run response here ... }''';
const kFallbackPlan = '''{ ... paste your pre-run response here ... }''';
```

Implementation logic:
```dart
Future<String> analyzeBody(File image) async {
  try {
    final result = await _callGeminiAPI(image)
        .timeout(Duration(seconds: 8));
    return result;
  } catch (_) {
    return kFallbackAnalysis;
  }
}
```

---

## 6. NAVIGATION STRUCTURE

```
AppRouter:
  /splash         → Screen 1 (Onboarding)
  /capture        → Screen 2 (Camera)
  /analysis       → Screen 3 (Analysis Reveal) — requires captured image
  /plan           → Screen 4 (Training Plan) — requires analysis result

Bottom nav: visible only on /analysis and /plan
Transitions: custom slide + fade, 350ms, no default MaterialPageRoute push
```

---

## 7. ASSETS

```
assets/
  images/
    vitruvian_logo.svg    ← your exported SVG
  animations/
    body_scan.json        ← Lottie file from lottiefiles.com
```

---

## 8. BUILD ORDER FOR ANTIGRAVITY

Run Antigravity in this exact sequence — do not skip steps or combine them:

1. `Generate lib/theme/tokens.dart` — tokens only, no screens
2. `Generate lib/theme/app_theme.dart` — ThemeData using tokens
3. `Generate pubspec.yaml` — with all packages from Section 2
4. `Generate Screen 1 — Onboarding` — reference tokens file, no hardcoded colors
5. `Generate Screen 2 — Camera Capture`
6. `Generate Screen 3 — Analysis Reveal (loading state only first)`
7. `Generate Screen 3 — Analysis Reveal (results state)`
8. `Generate Screen 4 — Training Plan`
9. `Generate lib/services/api_service.dart` — both API calls + fallback logic
10. `Generate lib/router/app_router.dart` — navigation

After each step: review for hardcoded colors or sizes before proceeding to next.
