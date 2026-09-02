# Physiqo Analytics Event Schema

On-device, local-first telemetry emitted by `TestLogger` (and the companion
`SessionRecorder`). All events are written as one JSON object per line (JSONL)
to `<app-docs>/testing_logs/session_<uuid>.jsonl`.

## Envelope

Every line shares this structure:

```json
{
  "ts": "2026-09-02T10:15:30.000Z",
  "session_id": "a1b2c3d4-...",
  "seq": 42,
  "event": "<event-name>",
  "data": { ... }
}
```

| Field | Type | Description |
|---|---|---|
| `ts` | string (ISO-8601 UTC) | Event timestamp. |
| `session_id` | string | UUID v4 generated per session. |
| `seq` | int | Monotonically increasing per-session sequence number. |
| `event` | string | Event type (see below). |
| `data` | object | Typed payload. Secrets are redacted by `_redact()`. |

---

## Lifecycle Events

### `app_launch`
Emitted once on cold/warm start.
- `cold_start` (bool)
- `launch_duration_ms` (int?)
- `app_version` (string)
- `os` (string), `os_version` (string)
- `locale` (string)
- `screen_size` (string?)

### `app_launch_complete`
Emitted after `runApp`.
- `launch_duration_ms` (int)

### `app_background` / `app_foreground`
Lifecycle transitions. `app_background` includes `session_duration_ms`.

### `app_terminate_detected`
Best-effort inference when the previous session had no clean-close marker.
- `previous_session_file` (string)

### `testing_mode_enabled` / `testing_mode_disabled`
User toggled the diagnostics switch in Settings.

---

## Navigation Events

### `screen_view`
- `screen_name` (string)
- `previous_screen` (string?)
- `nav_method` (`push` | `pop` | `replace` | `button`)
- `load_duration_ms` (int?) — optional screen load time.

### `screen_exit`
- `screen_name` (string)
- `time_on_screen_ms` (int) — dwell time.

---

## Interaction Events

### `tap`
- `screen_name` (string?)
- `element_id` (string)
- `element_label` (string?)
- `x` (int?), `y` (int?) — optional tap coordinates.

### `rage_tap`
3+ taps on the same element within 1.5s with no intervening navigation.
- `screen_name` (string?)
- `element_id` (string)
- `taps_in_window` (int)

### `user_hesitation`
Emitted after 5s of no user activity (resets + re-arms on each activity).
- `inactive_threshold_ms` (int)
- `screen_name` (string?)

---

## LLM Interaction Events

**Metadata only — no raw prompt or response text is ever logged.**

### `llm_request`
Emitted when an LLM streaming request begins.
- `chat_id` (string?)
- `message_count` (int?)
- `has_images` (bool?)
- `provider` (string?)

### `llm_response`
Emitted when an LLM request completes (success or failure). Bridged from
`AiService._logRequestInfo` — the single chokepoint for all provider calls.
- `chat_id` (string?)
- `latency_ms` (int)
- `input_tokens` (int?), `output_tokens` (int?)
- `tokens_estimated` (bool) — true when token counts were approximated.
- `error` (string?)
- `provider` (string?), `model` (string?)
- `race_tag` (string?) — identifies the winning candidate in a multi-provider race.

---

## Task Flow Events

### `task_start`
Marks the beginning of a user-facing task flow.
- `task_id` (string) — pair with `task_complete`.
- `flow_name` (string) — e.g. `chat_response`, `body_scan_analysis`.
- `params` (object?) — optional flow-specific parameters.

### `task_complete`
- `task_id` (string)
- `success` (bool)
- `duration_ms` (int?) — computed from the paired `task_start`.
- `error` (string?)
- `result` (object?) — optional flow-specific outcome (e.g. `overall_score`).

**Tracked flows:**
| Flow | Start | Complete |
|---|---|---|
| `chat_response` | `_processAiLoop` entry | Loop exit (success/error) |
| `body_scan_analysis` | `_startAnalysis` entry | Navigation to analysis / error |

---

## Performance Events

### `app_performance`
Periodic sample (every 5s) of rendering + memory metrics.
- `fps` (string?) — frames-per-second over the sampling window.
- `jank_frames` (int) — frames whose build+raster exceeded 16.6ms.
- `dropped_frames` (int) — frames exceeding 33.3ms.
- `memory_rss_kb` (int) — `ProcessInfo.currentRss` in KB.

---

## Error Events

### `app_error`
Uncaught errors from `FlutterError.onError`, the zone guard, and
`PlatformDispatcher.instance.onError`.
- `error_message` (string)
- `error_type` (string) — `runtimeType` of the error.
- `stack_trace_first_n_lines` (string[])
- `screen_name` (string?)
- `breadcrumb_trail` (string[]) — last 20 screen names.

### `api_error`
Structured network/API failures (distinct from app errors).
- `endpoint` (string)
- `error_message` (string)
- `status_code` (int?)
- `latency_ms` (int?)

---

## Session Replay (separate file)

Replay data lives in `testing_logs/screenshots/`:
- `replay_index.jsonl` — chronological index of events.
- `<timestamp>.png` — 0.5x screenshots.

### `replay_index.jsonl` entries
```json
{ "ts": "...", "session_id": "...", "type": "screenshot", "path": "screenshots/123.png", "width": 393, "height": 852 }
{ "ts": "...", "session_id": "...", "type": "tap", "x": 120, "y": 340, "masked": false }
{ "ts": "...", "session_id": "...", "type": "screen_change", "screen": "ChatScreen" }
```

**Masking:** When a sensitive screen is active (chat tab, body-scan flow),
`setMasked(true)` suppresses screenshot capture — only tap *coordinates* are
recorded (with `"masked": true`), never the pixel content.

**Retention:** Screenshots are capped at 50 MB; oldest PNGs are deleted first.
Session JSONL files are capped at 20 files / 10 MB total.

---

## Privacy & Redaction

- All payloads pass through `_redact()`, which replaces any key containing
  `key`, `token`, `secret`, `password`, `authorization`, or `apikey` with
  `[REDACTED]`.
- LLM events record only latency, token counts, provider/model, and errors —
  never the prompt or response text.
- Session replay screenshots are masked on sensitive screens.
- All data stays on-device until the user explicitly exports via Settings →
  Testing Diagnostics.
