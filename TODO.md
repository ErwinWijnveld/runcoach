# RunCoach TODO

Running list of known issues / nice-to-haves that aren't yet scheduled. Add the date when you log a new item; cross out (or remove) when done.

## Open

### 2026-04-25 — Tighten agent prompt about week 1's truncated DOWs

**Symptom:** Edit-flows on a freshly-created plan often have the agent reference a `day_of_week` in week 1 that doesn't exist (e.g. agent calls `set_day week 1 day_of_week 5` when week 1 only has days `[6, 7]` because today is Saturday). The first `edit_schedule` call fails, the agent retries — each retry costs ~20–25s of LLM thinking + JSON streaming. Two failed retries = ~50s of dead wall-clock.

**Why:** `PlanOptimizerService::dropDaysPastTarget` trims week 1 to start from today's DOW (so DOWs strictly before today's are missing). The agent doesn't internalize this from the `plan_structure` field already in its tool-result history; it assumes week 1 has its `preferred_weekdays` in full.

**Fix:** Add an explicit line in `RunCoachAgent::planDesignPrinciples()` (or in the `EditSchedule` tool description) like:

> "Week 1 is partial — only DOWs from today onward exist there because the past portion of the current week is already gone. ALWAYS scan the most recent `plan_structure` (returned by `create_schedule`/`get_current_proposal`/`edit_schedule`) before composing ops to know which `(week, day_of_week)` pairs are actually present. Never assume a DOW exists."

**Expected impact:** ~25s saved on the average follow-up edit during onboarding-review.

**File:** `api/app/Ai/Agents/RunCoachAgent.php` (`planDesignPrinciples` method) and/or `api/app/Ai/Tools/EditSchedule.php` (description string).
