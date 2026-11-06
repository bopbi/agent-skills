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
On every plan creation, update, or refinement, recalibrate the **Model
recommendation** from the final plan and this current policy: rebuild the
overall tier and rationale, compatible model range, and applicable per-step,
per-part, or per-cluster overrides, including any policy-defined
reasoning-effort qualifiers. Remove stale overrides and effort qualifiers
instead of carrying them forward.

| Tier | Use for | Claude | OpenAI | Google | Kimi (Moonshot) | Qwen (Alibaba) | Grok (xAI) |
|---|---|---|---|---|---|---|---|
| small | isolated, fully specified mechanical work only: renames, nits, boilerplate, mirrored tests; never new behavior, dependency seams, or test strategy | `claude-haiku-5-5` | `gpt-6-luna` | `gemini-3.5-flash-lite` | `kimi-k3.1-pro` with `reasoning_effort: "low"` (lowest-cost current model, not a small-capability model) | `qwen3.8-flash` | `grok-build-0.1` |
| standard | default: 2–5 files, clear requirement, established pattern; minimum for new behavior, dependency boundaries, or non-trivial test design | `claude-sonnet-5-5` | `gpt-6.1-terra` | `gemini-3.8-flash` | `kimi-k3.1-pro` with `reasoning_effort: "high"` | `qwen3.7-plus` | `grok-4.6` |
| large | cross-cutting or ambiguous: shared state, concurrency, unfamiliar code | `claude-opus-5-5` | `gpt-6.1-sol` | `gemini-4-argon` | `kimi-k3.1-pro` with `reasoning_effort: "max"` | `qwen3.8-max` | `grok-4.7` |
| frontier | genuinely hard and costly to get wrong | `claude-opus-5-5` (max effort) | `gpt-6-astra` | `gemini-4-argon` (highest reasoning effort; Carbon is not publicly available) | `kimi-k3.1-pro` with `reasoning_effort: "max"` (no separate frontier model) | `qwen3.8-max` (no higher general-purpose production API model) | `grok-4.7` (no higher general-purpose production API model) |

Model IDs are current as of **November 2026**. Providers ship often, so
verify current availability before relying on an exact ID. Default to
**standard** unless work is isolated and fully mechanical (small), or
cross-cutting or ambiguous (large); use frontier only when large is
insufficient and mistakes would be unusually costly.
<!-- END GENERATED MODEL-TIER POLICY -->

## November 2026 research basis

This refresh uses Artificial Analysis Intelligence Index v5 and Coding Agent
Index, with Vals' Terminal-Bench 4.0 results as a second coding benchmark.
Scores from different index versions are not directly comparable. Prices below
are first-party standard API rates per 1M input/output tokens unless noted.

- **Kimi:** K3.1 Pro scored 55 on Artificial Analysis v4.3 at launch and led
  Terminal-Bench 4.0; on the newer v5 index it remained the leading open-weight
  entrant. Its $2/$10 price is 33% below K3, and it supports low, high, and max
  reasoning effort. K2 models are closed to new users and are planned for
  retirement by the end of December 2026, so K3.1 Pro now covers every tier.
- **OpenAI:** Terra costs $1/$5, half Sol's $2/$10, and was the cheapest leading
  model per Artificial Analysis v5 task. Terra is therefore the standard-tier
  default; Sol remains the large-tier choice for more complex coding.
- **Google:** Argon is the generally available Gemini 4 recommendation. Its
  introductory $2/$10 rate runs through November 30, then returns to the
  standard $4/$20. Carbon leads Artificial Analysis v5 at 59 but remains limited
  to selected users, so it is not yet a production API recommendation.
- **Anthropic:** Opus 5.5 scored 58 versus Fable 5.1's 49 on Artificial
  Analysis v5 and costs $4/$20 versus $10/$50, making Opus 5.5 the better
  frontier default as well as the large-tier choice.
- **Qwen and Grok:** The existing mappings remain current; no newer generally
  available model justified a tier change in this review.

Sources: [Artificial Analysis Intelligence Index v5](https://artificialanalysis.ai/articles/artificial-analysis-intelligence-index-v5),
[Kimi K3.1 Pro benchmark analysis](https://artificialanalysis.ai/articles/kimi-k3-1-pro-launch-benchmarks),
[Gemini 4 Carbon benchmark analysis and availability](https://artificialanalysis.ai/articles/gemini-4-carbon-new-number-1),
[Vals Terminal-Bench 4.0](https://www.vals.ai/benchmarks/terminal-bench-4),
[Kimi model availability](https://platform.moonshot.ai/docs/models),
[Kimi K3.1 Pro API guide](https://platform.moonshot.ai/docs/guide/kimi-k3-1-pro-quickstart),
[OpenAI GPT-6.1 Terra launch and pricing](https://openai.com/index/introducing-gpt-6-1-terra/),
[Google Gemini 4 Carbon launch and availability](https://blog.google/innovation-and-ai/models-and-research/gemini-models/introducing-gemini-4-carbon/),
[Anthropic pricing](https://docs.anthropic.com/en/docs/about-claude/pricing),
and [Alibaba Cloud model pricing](https://www.alibabacloud.com/help/en/model-studio/model-pricing).
