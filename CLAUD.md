# CLAUD.md — Developer Assistant Guide for Physiqo

This file serves as a guide for developer assistants (Claude, Antigravity, and other agentic coding platforms) to understand how to interact with, refactor, and build on the **Physiqo** codebase.

---

## 1. Stack & Architecture

Physiqo is a premium, serverless, offline-first bodybuilding and fitness application.

| Component | Technology | Detail |
|---|---|---|
| **Front-End** | Flutter (Dart) | Full RTL layout, Farsi/English support |
| **Theme / UI** | AppTheme (`lib/theme/app_theme.dart`) | Dark cinematic theme, flat design (no glows/neon) |
| **Local Storage** | Secure Storage & SharedPreferences | Keeps API credentials secure, logs local workouts |
| **AI Integration**| Chat & Vision API | Interacts with OpenRouter, Nvidia NIM, Reka, or Gemini |

---

## 2. MCP configurations (Stitch MCP)
The app is connected to the Stitch MCP server with project ID `7928721753590883638`.
* **Fixing Configs:** If the local MCP client is broken, check `C:\Users\Amirhosein\.gemini\config\mcp_config.json` and replace the runner configurations with the parameters found in `mcp_config_fix.json` in the root directory.

---

## 3. Key Naming & Coding Rules

When generating code or proposing changes:
* **Strict RTL/LTR Layouts:** Use `Directionality` widgets or directional widgets (e.g. `BackButtonIcon`) so the app mirrors automatically depending on the selected locale.
* **No Unbounded Rows/Columns:** Avoid rendering `Text` inside a `Row` alongside icons without wrapping it in an `Expanded` or `Flexible` widget. Unconstrained texts cause horizontal overflow errors in languages with long words (e.g., Russian, Bengali).
* **Dropdown Alignment:** Set `isExpanded: true` on all `DropdownButton` widgets, and `width: double.infinity` on parent containers to prevent horizontal squeezing overflows.
* **Privacy by Design:** Never store keys on remote clouds. All provider tokens must be written/read from `FlutterSecureStorage` using prefix patterns.

---

## 4. Grounding Files
* [AGENTS.md](file:///d:/Physiqo/AGENTS.md): Main design token values and styling rules.
* [workout-plan-generator.md](file:///d:/Physiqo/workout-plan-generator.md): Instruction prompts for the AI Coach.
