# Physiqo AI Config Generator - LLM Prompt

Copy everything below the line and paste it into any LLM (ChatGPT, Claude, Gemini, etc.).
Fill in the bracketed [...] placeholders with your actual values before sending.

---

You are generating a Physiqo AI configuration JSON file. The user will import this file into the Physiqo app "Import / Export AI Config" screen. You MUST produce a single, valid JSON object - no markdown fences, no commentary, no trailing text.

## Schema Rules (MUST follow exactly)

1. The root object MUST contain "schemaVersion": 1 - the import will reject any other value.
2. exportedAt is optional; if omitted the app fills it automatically. Use ISO-8601 if you include it.
3. All string values must be valid JSON strings (escape quotes, backslashes, newlines as \n).
4. Provider name values must be non-empty strings with no spaces or special characters - they are used as key suffixes (e.g. openai, gemini, custom-openai).
5. apiKey can be an empty string "" - the user will be prompted to enter it after import if needed. Never invent fake keys.
6. chatModels and visionModels are arrays of model ID strings (e.g. "gpt-4o", "claude-3-5-sonnet-20241022"). A model can appear in both arrays.
7. activeChatModel / activeVisionModel must be one of the model IDs listed in that provider chatModels / visionModels array, or null / omitted.
8. activeChatProvider / activeVisionProvider must match a provider name from the providers array, or be null / omitted.
9. fallbacks.text and fallbacks.vision are arrays of fallback entries. Each entry needs provider (matching a provider name) and modelId. id and isEnabled are optional (isEnabled defaults to true).
10. customInstructions.mode must be one of: "shared", "chat", "vision".
    - "shared" means one instruction used for both chat and vision (put it in shared).
    - "chat" means separate instructions for chat and vision (put them in chat and vision).
    - "vision" means only vision uses a custom instruction (put it in vision).
11. All numeric fields must be integers, not strings.
12. enableAutoFailover must be a boolean (true/false), not a string.

## Full JSON Schema (annotated example)

```json
{
  "schemaVersion": 1,
  "exportedAt": "2025-01-15T12:00:00.000Z",
  "network": {
    "maxRetries": 3,
    "timeoutSeconds": 30,
    "enableAutoFailover": true
  },
  "selection": {
    "activeChatProvider": "openai",
    "activeVisionProvider": "openai"
  },
  "providers": [
    {
      "name": "openai",
      "baseUrl": "https://api.openai.com/v1",
      "apiKey": "",
      "chatModels": ["gpt-4o", "gpt-4o-mini"],
      "visionModels": ["gpt-4o"],
      "activeChatModel": "gpt-4o",
      "activeVisionModel": "gpt-4o"
    }
  ],
  "fallbacks": {
    "text": [
      {
        "id": "fb_001",
        "provider": "openai",
        "modelId": "gpt-4o-mini",
        "isEnabled": true
      }
    ],
    "vision": []
  },
  "customInstructions": {
    "mode": "shared",
    "shared": "You are Physiqo, a fitness and bodybuilding AI coach. Be concise, motivational, and scientifically accurate.",
    "chat": "",
    "vision": ""
  }
}
```

## Field Reference

| Section | Field | Type | Required | Default | Notes |
|---|---|---|---|---|---|
| root | schemaVersion | int | YES | - | Must be 1 |
| root | exportedAt | string | no | auto | ISO-8601 timestamp |
| network | maxRetries | int | no | 3 | 1-10 recommended |
| network | timeoutSeconds | int | no | 30 | 10-120 recommended |
| network | enableAutoFailover | bool | no | true | If true, tries next fallback when a request fails |
| selection | activeChatProvider | string/null | no | null | Must match a provider name |
| selection | activeVisionProvider | string/null | no | null | Must match a provider name |
| providers[] | name | string | YES | - | Unique identifier, no spaces |
| providers[] | baseUrl | string | no | "" | API base URL (omit trailing /) |
| providers[] | apiKey | string | no | "" | Leave empty if user will enter manually |
| providers[] | chatModels | string[] | no | [] | Model IDs for text chat |
| providers[] | visionModels | string[] | no | [] | Model IDs for image analysis |
| providers[] | activeChatModel | string/null | no | null | Must be in chatModels |
| providers[] | activeVisionModel | string/null | no | null | Must be in visionModels |
| fallbacks.text[] | id | string | no | auto | Unique ID; auto-generated if missing |
| fallbacks.text[] | provider | string | YES | - | Must match a provider name |
| fallbacks.text[] | modelId | string | YES | - | Must be in that provider chatModels |
| fallbacks.text[] | isEnabled | bool | no | true | If false, skipped during failover |
| fallbacks.vision[] | (same as text) | | | | Uses visionModels instead |
| customInstructions | mode | string | no | "shared" | "shared", "chat", or "vision" |
| customInstructions | shared | string | no | "" | Used when mode = "shared" |
| customInstructions | chat | string | no | "" | Used when mode = "chat" |
| customInstructions | vision | string | no | "" | Used when mode = "vision" |

## User Request

The user wants a config with these settings:

- **Providers:** [Describe the AI providers you want, e.g. "OpenAI with GPT-4o and GPT-4o-mini, and a custom OpenAI-compatible local server at http://localhost:11434/v1 with Ollama models"]
- **API Keys:** [Say "leave blank" or provide keys - WARNING: keys in the file are stored in plaintext]
- **Active provider:** [Which provider for chat? Which for vision?]
- **Network settings:** [e.g. "3 retries, 30s timeout, auto-failover on"]
- **Fallbacks:** [e.g. "If OpenAI chat fails, try GPT-4o-mini; no vision fallbacks"]
- **Custom instructions:** [e.g. "Shared mode: You are Physiqo, a fitness coach..."]

Generate the complete JSON now. Output ONLY the JSON object, nothing else.
