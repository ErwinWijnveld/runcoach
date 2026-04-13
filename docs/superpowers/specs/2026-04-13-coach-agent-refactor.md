# RunCoach AI Coach Agent Refactor — Design Spec

## Problem

The current coach implementation is a basic chat-completion wrapper with predefined tool definitions. It has several issues:

1. **Not agentic** — the AI can only call tools from a fixed list with rigid schemas. It can't query individual activities, look up specific training days, or flexibly explore the user's data.
2. **Aggregates only** — `GetStravaSummaryTool` returns averages, not individual runs. When a user asks "how was my last run?", the coach can't answer specifically.
3. **Manual tool orchestration** — custom `callAI()` loop manually handles OpenAI tool calling, message threading, and iteration limits. This is exactly what the Laravel AI SDK Agent does natively.
4. **Dual conversation storage** — we have custom `coach_conversations`/`coach_messages` tables AND the SDK's `agent_conversations`/`agent_conversation_messages` tables. The SDK handles persistence automatically via `RemembersConversations`.
5. **Proposal system is tangled** — schedule mutations (create/modify/alternative) return data through the tool-calling loop and get stored as `CoachProposal`. This needs to stay but should work within the SDK's agent architecture.

## Solution

Replace `CoachChatService` + custom OpenAI calls with a proper **Laravel AI SDK Agent** (`RunCoachAgent`) that uses `RemembersConversations` for built-in conversation persistence and implements `HasTools` with granular, data-access tools.

## Architecture

### Agent: `RunCoachAgent`

A single Agent class that:
- Implements `Agent`, `Conversational`, `HasTools` via `RemembersConversations` + `Promptable`
- Takes a `User` in its constructor for scoping all data access
- System prompt adapts based on `coach_style` preference
- Uses `RemembersConversations` — the SDK handles conversation storage in `agent_conversations` / `agent_conversation_messages` automatically
- Tools are injected with the user context so they're scoped

### Tools (granular, data-access focused)

The key shift: instead of 7 big tools with complex schemas, we use **more granular tools** that let the agent decide what data to fetch. The agent itself reasons about what it needs.

| Tool | Purpose | Approval needed |
|------|---------|----------------|
| `GetRecentActivities` | List recent runs with full details (date, distance, pace, HR, name). Params: `limit` (default 10) | No |
| `GetActivityDetail` | Get full details of a specific activity by date or name | No |
| `GetTrainingSummary` | Aggregated stats over a period (weekly avg km, pace trends, HR trends) | No |
| `GetCurrentSchedule` | Current training schedule with days, compliance scores | No |
| `GetRaceInfo` | Active race details, weeks until race, completion rate | No |
| `GetComplianceReport` | Compliance breakdown: per-session scores, trends | No |
| `CreateSchedule` | Generate a full training plan. Returns proposal for approval | **Yes** |
| `ModifySchedule` | Change specific training days. Returns proposal for approval | **Yes** |

**Key difference from current:** `GetRecentActivities` and `GetActivityDetail` give the agent per-run data. The agent can answer "how was my last run?" by calling `GetRecentActivities(limit: 1)` and reading the actual numbers.

### Proposal System

Schedule mutations (`CreateSchedule`, `ModifySchedule`) still need user approval. These tools return a structured proposal payload. The controller detects proposals in the response and stores them as `CoachProposal` records. The accept/reject flow stays the same.

Implementation: mutation tools return a JSON string that includes `"requires_approval": true` and the payload. The controller parses the agent response, detects proposals, and creates `CoachProposal` records.

### Conversation Flow

**Before (custom):**
```
Flutter → POST /coach/conversations/{id}/messages
  → CoachChatService.sendMessage()
    → manually build messages array
    → manually call OpenAI with tool defs
    → manually handle tool call loop
    → manually store messages in coach_messages
  → return response + proposal
```

**After (SDK):**
```
Flutter → POST /coach/conversations/{id}/messages
  → CoachController
    → RunCoachAgent::make(user: $user)
      ->continue($conversationId, as: $user)
      ->prompt($content)
    // SDK handles: message history, tool calling loop, message storage
  → parse response for proposals
  → return response + proposal
```

### Database Changes

**Drop custom tables:**
- `coach_conversations` — replaced by `agent_conversations`
- `coach_messages` — replaced by `agent_conversation_messages`

**Keep:**
- `coach_proposals` — but change FK from `coach_message_id` to `agent_message_id` (string UUID referencing `agent_conversation_messages.id`)

**The SDK's `agent_conversation_messages` table already stores:** role, content, tool_calls, tool_results, usage, meta. This is richer than our custom `coach_messages`.

### API Changes

The API contract stays mostly the same for Flutter — same endpoints, same request/response shapes. Internal plumbing changes:

| Endpoint | Change |
|----------|--------|
| `POST /coach/conversations` | Creates via SDK `forUser()` instead of custom model |
| `GET /coach/conversations` | Queries `agent_conversations` instead of `coach_conversations` |
| `GET /coach/conversations/{id}` | Loads from SDK conversation store |
| `POST /coach/conversations/{id}/messages` | Uses `RunCoachAgent->continue()->prompt()` |
| `POST /coach/proposals/{id}/accept` | Same — applies proposal payload |
| `POST /coach/proposals/{id}/reject` | Same — marks rejected |

### File Changes

**Delete:**
- `app/Services/CoachChatService.php`
- `app/Services/CoachTools/` (all 7 files)
- `app/Models/CoachConversation.php`
- `app/Models/CoachMessage.php`
- `database/factories/CoachConversationFactory.php`
- `database/factories/CoachMessageFactory.php`

**Create:**
- `app/Ai/Agents/RunCoachAgent.php`
- `app/Ai/Tools/GetRecentActivities.php`
- `app/Ai/Tools/GetActivityDetail.php`
- `app/Ai/Tools/GetTrainingSummary.php`
- `app/Ai/Tools/GetCurrentSchedule.php`
- `app/Ai/Tools/GetRaceInfo.php`
- `app/Ai/Tools/GetComplianceReport.php`
- `app/Ai/Tools/CreateSchedule.php`
- `app/Ai/Tools/ModifySchedule.php`
- Migration: alter `coach_proposals` FK + drop old tables

**Modify:**
- `app/Http/Controllers/CoachController.php` — use `RunCoachAgent` instead of `CoachChatService`
- `app/Models/CoachProposal.php` — update FK to `agent_message_id`
- `routes/api.php` — no change (same endpoints)
- `tests/Feature/CoachChatTest.php` — update to use `RunCoachAgent::fake()`

### System Prompt

```
You are RunCoach, a personal AI running coach. Your style is {coach_style}.

You have access to the runner's complete Strava activity history and their training schedule. Use your tools to look up whatever data you need — you can see individual runs, pace, distance, heart rate, and training compliance.

Coaching principles:
- Always reference the runner's actual data. Never invent numbers.
- Use periodization, the 80/20 rule (80% easy / 20% hard), and progressive overload.
- Be specific: mention actual dates, distances, and paces from their data.
- When creating or modifying schedules, always use the appropriate tool. The runner must approve changes before they take effect.

The runner's profile:
- Level: {level}
- Weekly capacity: {weekly_km_capacity} km
- Coach style preference: {coach_style}
```

### Provider Configuration

Use OpenAI by default (already configured). The agent can easily be switched to Anthropic or any other provider via the `config/ai.php` default or per-prompt override:

```php
$agent->prompt($content, provider: Lab::Anthropic, model: 'claude-sonnet-4-20250514');
```
