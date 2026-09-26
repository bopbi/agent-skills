# Model tier policy

`MODEL_TIERS.md` is the canonical, hand-edited source for model-tier data in
this repository. Do not edit model IDs, provider coverage, tier definitions,
compatibility rules, or the checked-as-of date in any generated consumer.

## Updating this policy

1. Edit this file and verify provider information against its authoritative
   source.
2. Run `scripts/sync-model-tiers.sh`.
3. Run `scripts/sync-model-tiers.sh --check`.
4. Review `run-plan/SKILL.md` whenever the tier meanings, compatible-model
   range format, or provider-switch policy changes.

The synchronizer manages these consumers:

- `plan-task/SKILL.md`
- `pr-triage/SKILL.md`
- `README.md`

The marker-delimited block below is copied byte-for-byte into each consumer.
It is the only model-tier matrix or model-ID recency statement that may be
edited by hand.

<!-- BEGIN GENERATED MODEL-TIER POLICY -->
**Policy source:** This block is generated from `MODEL_TIERS.md`; do not edit
it in this consumer.

Plans recommend the cheapest **tier** that can reliably execute each step or
cluster, judged by ambiguity and blast radius rather than feature importance.
A task is not mechanical merely because its file list is short or its intended
outcome is clear: new production behavior, a dependency boundary or test seam,
and non-trivial test design require at least **standard**. Reserve **small**
for isolated, fully specified mechanical work.
Every recommendation also emits a **compatible model range**: one model from
each supported provider at that tier. The tier is the requirement, not the
provider that created the plan, so execution may switch providers when the
selected model is listed for, or verified above, the required tier.

| Tier | Use for | Claude | OpenAI | Google | Kimi (Moonshot) | Qwen (Alibaba) | Grok (xAI) |
|---|---|---|---|---|---|---|---|
| small | isolated, fully specified mechanical work only: renames, nits, boilerplate, mirrored tests; never new behavior, dependency seams, or test strategy | `claude-haiku-4-5` | `gpt-5.6-luna` | `gemini-3.5-flash-lite` | `kimi-k2.7-code-highspeed` (lowest-cost current option, not a small-capability model) | `qwen3.8-flash` | `grok-build-0.1` |
| standard | default: 2–5 files, clear requirement, established pattern; minimum for new behavior, dependency boundaries, or non-trivial test design | `claude-sonnet-5` | `gpt-5.6-terra` | `gemini-3.7-flash` | `kimi-k2.8-preview` | `qwen3.7-plus` | `grok-4.3` |
| large | cross-cutting or ambiguous: shared state, concurrency, unfamiliar code | `claude-opus-5-5` | `gpt-5.6-sol` | `gemini-3.8-flash` | `kimi-k3` (long-context variant: `kimi-k3-256k`) | `qwen3.8-max` | `grok-4.6` |
| frontier | genuinely hard and costly to get wrong | `claude-fable-5-1` | `gpt-5.5-pro` | `gemini-3.8-flash` (no higher general-purpose production API model) | `kimi-k3` with `reasoning_effort: "max"` (no separate frontier model; long-context variant: `kimi-k3-256k`) | `qwen3.8-max` (no higher general-purpose production API model) | `grok-4.6` (no higher general-purpose production API model) |

Model IDs are current as of **September 2026**. Providers ship often, so
verify current availability before relying on an exact ID. Default to
**standard** unless work is isolated and fully mechanical (small), or
cross-cutting or ambiguous (large); use frontier only when large is
insufficient and mistakes would be unusually costly.
<!-- END GENERATED MODEL-TIER POLICY -->
