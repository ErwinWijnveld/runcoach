<?php

namespace Tests\Feature\Ai\Support;

use App\Ai\Agents\ActivityFeedbackAgent;
use App\Ai\Agents\OnboardingAgent;
use App\Ai\Agents\RunCoachAgent;
use App\Ai\Agents\WeeklyInsightAgent;
use App\Ai\Support\LanguageDirective;
use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Support\Facades\App;
use Tests\TestCase;

class LanguageDirectiveTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_returns_empty_for_english(): void
    {
        $this->assertSame('', LanguageDirective::for('en'));
    }

    public function test_returns_empty_for_unknown_locale(): void
    {
        $this->assertSame('', LanguageDirective::for('fr'));
    }

    public function test_returns_dutch_directive_for_nl(): void
    {
        $directive = LanguageDirective::for('nl');

        $this->assertStringContainsString('Respond to the runner in Dutch', $directive);
        $this->assertStringContainsString('idiomatic', $directive);
        $this->assertStringContainsString('## Response language', $directive);
    }

    public function test_current_reads_app_locale(): void
    {
        App::setLocale('nl');
        $this->assertStringContainsString('Dutch', LanguageDirective::current());

        App::setLocale('en');
        $this->assertSame('', LanguageDirective::current());
    }

    public function test_activity_feedback_agent_appends_directive_when_locale_is_nl(): void
    {
        App::setLocale('nl');
        $agent = new ActivityFeedbackAgent;

        $this->assertStringContainsString('Respond to the runner in Dutch', $agent->instructions());
    }

    public function test_activity_feedback_agent_omits_directive_when_locale_is_en(): void
    {
        App::setLocale('en');
        $agent = new ActivityFeedbackAgent;

        $this->assertStringNotContainsString('Respond to the runner in Dutch', $agent->instructions());
        $this->assertStringNotContainsString('## Response language', $agent->instructions());
    }

    public function test_weekly_insight_agent_appends_directive_when_locale_is_nl(): void
    {
        App::setLocale('nl');
        $agent = new WeeklyInsightAgent;

        $this->assertStringContainsString('Respond to the runner in Dutch', $agent->instructions());
    }

    public function test_run_coach_agent_appends_directive_when_locale_is_nl(): void
    {
        App::setLocale('nl');
        $user = User::factory()->create(['locale' => 'nl']);
        $agent = new RunCoachAgent($user);

        $this->assertStringContainsString('Respond to the runner in Dutch', $agent->instructions());
    }

    public function test_onboarding_agent_appends_directive_when_locale_is_nl(): void
    {
        App::setLocale('nl');
        $user = User::factory()->create(['locale' => 'nl']);
        $agent = new OnboardingAgent($user);

        $this->assertStringContainsString('Respond to the runner in Dutch', $agent->instructions());
    }
}
