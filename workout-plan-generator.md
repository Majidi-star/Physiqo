---
name: workout-plan-generator
description: Generates a complete, personalized resistance-training workout plan (split, exercises, sets/reps/rest, progression) from a user's fitness profile, with full support for gym-equipped, home/minimal-equipment, and bodyweight-only training. Always use this whenever the AI coach is asked to build, update, or regenerate a training program, a single day's workout, or an exercise substitution — including requests like "make me a plan," "I don't have a gym, what can I do instead," "change my Tuesday workout," or "I have an injury, adjust my program." Output must be produced in both Persian and English per the app's bilingual localization system.
---

# Workout Plan Generator

A knowledge module for Physiqo's AI coach (مربی هوشمند بدنسازی). It turns a user's stored fitness profile into a structured, safe, and equipment-aware training plan, and keeps the plan updated as equipment, goals, or limitations change.

## 1. When to use this

Trigger this skill whenever the AI coach needs to:
- Generate a brand-new weekly training program for a user
- Regenerate/adjust an existing program (new goal, new equipment, injury, missed days)
- Build a single workout for one body-part screen (chest/back/legs/abs/arms/shoulders)
- Swap one exercise for an equipment-appropriate alternative (e.g. "I don't have a barbell")
- Answer a question that requires proposing sets/reps/rest/exercise selection

## 2. Required inputs

Pull these from the user's stored profile (`AIContextBuilder` JSON) before generating anything. If a field is missing, use the stated default and note the assumption in the plan's notes field — do not block generation on missing data.

| Field | Source | Default if missing |
|---|---|---|
| Gender | profile.gender | ask once, else "unspecified" (use neutral exercise language) |
| Age | profile.age | assume 25–40 adult range; apply §6 rules only if provided |
| Height / Weight | profile.height, profile.weight | used for load/intensity notes only, never displayed as a target |
| Experience level | fitness profile | "beginner" |
| Primary goal | fitness profile (incl. "Other" free text) | "general fitness" |
| Available equipment | fitness profile / extra notes | "bodyweight only" (safest assumption) |
| Workout days/week | settings → workout days | 3 |
| Injuries / limitations / extra notes | fitness profile free-text field | none |
| Session length preference | extra notes, if mentioned | 45–60 min |

## 3. Generation algorithm

Run these steps in order every time a plan is (re)generated.

### Step 1 — Determine equipment tier
Classify into exactly one tier; this controls which exercise table rows are eligible in §5.

- **Tier A — Full gym**: barbells, machines, cables, benches available
- **Tier B — Home/minimal**: dumbbells and/or resistance bands, no machines/barbell
- **Tier C — Bodyweight only**: no equipment at all

If the user mentions partial equipment (e.g. "I only have dumbbells and a pull-up bar"), still use Tier B/C rules but prefer the listed items first before falling back to the tier's other options.

### Step 2 — Choose the training split
Base the split on days/week **and** experience level. Prefer patterns that map cleanly onto the app's existing body-part categories (chest, back, legs, abs, arms, shoulders).

| Days/week | Beginner | Intermediate/Advanced |
|---|---|---|
| 1–2 | Full Body | Full Body |
| 3 | Full Body ×3 | Full Body ×3 or Push/Pull/Legs (compressed) |
| 4 | Upper / Lower ×2 | Upper / Lower ×2, or Upper/Lower/Push/Pull |
| 5 | Upper / Lower + 1 Full Body | Body-part split: Chest, Back, Legs, Shoulders, Arms (each with Abs superset) |
| 6 | Push / Pull / Legs ×2 | Push / Pull / Legs ×2 |

Abs get 2–4 exercises added to the end of 2–3 sessions/week rather than their own dedicated day, unless the user explicitly wants an abs-focused day.

### Step 3 — Set the sets/reps/rest scheme by goal

| Goal | Reps | Sets (per exercise) | Rest | Notes |
|---|---|---|---|---|
| Strength | 3–6 | 3–5 | 2–4 min | Prioritize compound lifts; slower rep pace |
| Hypertrophy / muscle gain | 6–12 | 3–4 | 60–90 sec | Default for "bodybuilding" goal |
| Fat loss / conditioning | 12–20 | 2–3 | 30–60 sec | Higher density; consider supersets/circuits |
| General fitness / beginner default | 8–15 | 2–3 | 60–75 sec | Favor full-body compound movement patterns |
| Muscular endurance | 15–25 | 2–3 | 30–45 sec | Lighter loads, bodyweight-friendly |

If the user's goal is a free-text "Other" value, map it to the closest row above and say so in the plan notes rather than inventing a new untested scheme.

### Step 4 — Select exercises
For each body part scheduled that day, pick 3–5 exercises using the tables in §5, filtered to the equipment tier from Step 1. Order: one primary compound movement first, then 1–2 secondary/isolation movements, then an optional finisher.

### Step 5 — Apply special-case adjustments (§6) and injury/limitation filtering (§7)

### Step 6 — Assign a progression scheme (§8)

### Step 7 — Assemble the weekly schedule and emit it in the app's data format (§9), fully localized (§10)

## 4. Warm-up and cool-down (always include)

- Warm-up: 5 min light cardio (marching in place if no equipment) + dynamic stretches/joint circles for the muscles trained that day
- Cool-down: 3–5 min static stretching of the muscles trained
- These are metadata on the session, not counted toward the main exercise list unless the app's schema requires a fourth "warm-up" entry type

## 5. Exercise bank by body part and equipment tier

Use these as the canonical pool. Any exercise added to the user's custom exercise DB should also declare which tier(s) it belongs to so future substitutions stay consistent.

**Chest**
- Tier A: Barbell Bench Press, Incline DB/Barbell Press, Cable Fly, Machine Chest Press, Dips
- Tier B: DB Bench Press, DB Incline Press, DB Fly, Resistance Band Press
- Tier C: Push-ups, Incline Push-ups, Decline Push-ups, Diamond Push-ups

**Back**
- Tier A: Lat Pulldown, Barbell Row, Seated Cable Row, T-Bar Row, Pull-up
- Tier B: DB Row (single-arm), Renegade Row, Band Pull-apart, Band Row
- Tier C: Pull-ups/Chin-ups (if any bar/ledge available), Inverted Row (table edge), Superman, Doorway Row with towel

**Legs**
- Tier A: Barbell Back Squat, Leg Press, Romanian Deadlift, Leg Curl, Leg Extension, Walking Lunge
- Tier B: Goblet Squat, DB Romanian Deadlift, DB Lunge, Band Squat
- Tier C: Bodyweight Squat, Bulgarian Split Squat (chair-assisted), Glute Bridge, Walking Lunge, Wall Sit, Jump Squat

**Shoulders**
- Tier A: Barbell/Machine Overhead Press, Cable Lateral Raise, Rear Delt Machine
- Tier B: DB Shoulder Press, DB Lateral Raise, DB Front Raise, Band Lateral Raise
- Tier C: Pike Push-up, Plank-to-Downward-Dog, Wall Handstand Hold (advanced only)

**Arms (Biceps/Triceps)**
- Tier A: Barbell Curl, Cable Curl, Tricep Pushdown, Skull Crusher, Preacher Curl
- Tier B: DB Curl, Hammer Curl, DB Overhead Tricep Extension, DB Kickback, Band Curl
- Tier C: Chin-ups (biceps emphasis), Diamond Push-ups (triceps), Close-Grip Push-ups, Chair/Bench Dips

**Abs**
- Tier A: Cable Crunch, Hanging Leg Raise, Ab Machine
- Tier B/C (same list, no equipment needed): Crunches, Plank, Leg Raises, Russian Twists, Mountain Climbers, Bicycle Crunches, Side Plank

## 6. Age/experience adjustments

- **Beginner (<6 months training)**: fewer exercises per session (3–4 body parts covered lightly across full-body days), simpler movement patterns, extra coaching cues on form
- **Age 50+ (if provided)**: prefer machine/DB variants over max-effort barbell lifts, longer warm-up, avoid deep-range high-impact plyometrics unless the user reports training experience
- **Advanced (2+ years)**: introduce periodization — vary rep ranges by week, plan a deload every 4–6 weeks (see §8)

## 7. Injury / limitation handling

Scan the profile's free-text notes for limitation keywords (e.g. knee, shoulder, lower back, wrist, pregnancy). If found:
1. Remove any exercise in §5 that loads the flagged joint/area under high stress (e.g. flag "knee" → drop Jump Squat, deep Bulgarian Split Squat; flag "lower back" → drop Barbell RDL/Deadlift variants, prefer machine-supported or bodyweight alternatives)
2. Substitute with the nearest same-muscle-group alternative from the same or a lower equipment tier
3. Add a plan note recommending the user confirm with a doctor or physiotherapist before continuing — do not attempt to diagnose or give medical advice beyond this
4. Never silently drop the limitation from future regenerations — persist it as part of the profile context

## 8. Progression scheme

| Experience | Method |
|---|---|
| Beginner | Linear progression: add reps or weight every session while form holds; deload only if two sessions in a row show no progress |
| Intermediate | Double progression: work up to the top of the rep range across sets before increasing weight/difficulty; deload every 6 weeks |
| Advanced | Block periodization: rotate rep-range emphasis every 3–4 weeks, mandatory deload week every 4–6 weeks (reduce volume ~40%) |

For Tier C (bodyweight), "progression" also includes moving to a harder variant (e.g. knee push-up → standard → decline) once the top of the rep range is hit for 2 consecutive sessions.

## 9. Output schema

Emit one plan object per regeneration. Field names below are a reasonable default — align them to Physiqo's actual Flutter models (the existing exercise DB / workout-day models) rather than introducing a parallel schema; this shape is a starting point for Antigravity to map, not a hard requirement.

```json
{
  "goal": "hypertrophy",
  "split_type": "body_part_split",
  "equipment_tier": "B",
  "days": [
    {
      "day_label": "Day 1 - Chest",
      "body_parts": ["chest", "abs"],
      "exercises": [
        {
          "exercise_id": "chest_01",
          "sets": 4,
          "reps": "8-12",
          "rest_seconds": 75,
          "tier_used": "B"
        }
      ]
    }
  ],
  "progression_notes": "Double progression; increase weight once 4x12 is achieved with good form.",
  "assumptions_made": ["age not provided, assumed adult default"],
  "flags": ["user reported knee sensitivity - squats substituted"]
}
```

## 10. Bilingual output rules (Persian + English)

- Never emit a raw localization key (e.g. `exercise_legs_14_name`) as visible text in either language — this has been a recurring bug in the app. Always resolve to an actual translated string on both the `_name`/`_desc` fields before returning.
- Generate both `fa` and `en` strings for any new custom exercise the plan introduces; do not leave one language blank.
- Use the existing app terminology for body parts and plan vocabulary:

| English | Persian |
|---|---|
| Chest | سینه |
| Back | پشت |
| Legs | پا |
| Shoulders | شانه |
| Arms | بازو |
| Abs | شکم |
| Sets | ست |
| Reps | تکرار |
| Rest | استراحت |
| Warm-up | گرم کردن |
| Cool-down | سرد کردن |

- Keep numerals and units consistent with the app's existing unit-system settings (metric/imperial) rather than hardcoding either.
- English-mode output must remain fully LTR-mirrored per the app's existing localization/layout system; this skill only governs plan *content*, not layout — flag to Antigravity if a generated plan surfaces through a screen that hasn't had the LTR-mirroring audit applied yet.

## 11. Safety notes

- This module produces general fitness programming, not medical advice. Any user-reported pain, injury, or health condition should route to the §7 flagging behavior and a "consult a professional" note rather than an attempted workaround.
- Do not generate plans implying rapid, extreme, or unsafe rates of change (e.g. no plans framed around aggressive short-term weight-loss targets). Keep language focused on strength/consistency/technique, not appearance-based urgency.

## 12. Implementation notes for Antigravity

- This file is intended to be used as the grounding/system-prompt content the AI coach references whenever it calls the "generate/update workout plan" tool — either paste its relevant sections into that tool's system prompt, or load it at runtime and pass the applicable sections based on context (full plan generation vs. single substitution).
- Keep §5 (exercise bank) as data the app can also render directly in the exercise database screen, so AI-generated exercises stay consistent with what's manually browsable there.
- Any new exercise the AI coach introduces via this skill should be written into the app's exercise DB (with both language fields populated) rather than existing only inside a chat message, so it shows up correctly in the exercise detail screen later.
