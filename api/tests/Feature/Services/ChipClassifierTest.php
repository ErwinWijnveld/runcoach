<?php

namespace Tests\Feature\Services;

use App\Services\ChipClassifier;
use Mockery;
use OpenAI\Contracts\ClientContract;
use OpenAI\Contracts\Resources\ChatContract;
use OpenAI\Responses\Chat\CreateResponse as ChatCreateResponse;
use Tests\TestCase;

class ChipClassifierTest extends TestCase
{
    private function fakeResponse(string $content): ChatCreateResponse
    {
        return ChatCreateResponse::fake([
            'choices' => [
                [
                    'index' => 0,
                    'message' => ['role' => 'assistant', 'content' => $content],
                    'finish_reason' => 'stop',
                ],
            ],
        ]);
    }

    public function test_classifies_free_text_against_chip_options(): void
    {
        $chat = Mockery::mock(ChatContract::class);
        $chat->shouldReceive('create')->once()->andReturn($this->fakeResponse('{"value": "race"}'));

        $openai = Mockery::mock(ClientContract::class);
        $openai->shouldReceive('chat')->andReturn($chat);

        $classifier = new ChipClassifier($openai);
        $result = $classifier->classify(
            'I have a marathon coming up',
            [
                ['label' => 'Race coming up!', 'value' => 'race'],
                ['label' => 'General fitness', 'value' => 'general_fitness'],
                ['label' => 'Get faster', 'value' => 'pr_attempt'],
                ['label' => 'Not sure yet', 'value' => 'skip'],
            ],
        );

        $this->assertEquals('race', $result);
    }

    public function test_returns_null_when_llm_says_none(): void
    {
        $chat = Mockery::mock(ChatContract::class);
        $chat->shouldReceive('create')->once()->andReturn($this->fakeResponse('{"value": null}'));

        $openai = Mockery::mock(ClientContract::class);
        $openai->shouldReceive('chat')->andReturn($chat);

        $classifier = new ChipClassifier($openai);
        $result = $classifier->classify('tell me a joke', [
            ['label' => 'Race coming up!', 'value' => 'race'],
        ]);

        $this->assertNull($result);
    }

    public function test_returns_null_on_openai_failure(): void
    {
        $chat = Mockery::mock(ChatContract::class);
        $chat->shouldReceive('create')->andThrow(new \Exception('down'));

        $openai = Mockery::mock(ClientContract::class);
        $openai->shouldReceive('chat')->andReturn($chat);

        $classifier = new ChipClassifier($openai);
        $this->assertNull($classifier->classify('foo', [['label' => 'X', 'value' => 'x']]));
    }
}
