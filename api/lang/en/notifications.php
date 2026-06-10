<?php

return [

    'plan_generation' => [
        'completed' => [
            'title' => 'Your training plan is ready',
            'body' => 'Tap to review and accept your plan.',
        ],
        'failed' => [
            'title' => 'Plan generation hit a snag',
            'body' => 'Tap to try again.',
        ],
    ],

    'training_day' => [
        // Used when we couldn't locate the TrainingDay row — bare fallback.
        'fallback_title' => "Today's run",
        'fallback_body' => 'Tap to see the details.',
        // Used when km + type label are available, e.g. "Today: 5km Easy".
        'title_with_km' => 'Today: :km km :type',
        // Used when the day has no target distance (e.g. an interval day
        // whose blueprint was emptied), e.g. "Today: Intervals".
        'title_without_km' => 'Today: :type',
        // Body composed of parts joined with ". ".
        'target_pace' => 'Target pace :pace/km',
        'tap_for_details' => 'Tap for details.',
    ],

    'birthday_zone_check' => [
        'title' => 'Happy birthday! 🎂',
        'body' => "You're a year wiser — let's refresh your heart-rate zones to match.",
    ],

    'plan_evaluation' => [
        'title' => 'Your 2-week check-in is ready',
        'body_with_proposal' => "We've suggested a small adjustment based on your last 2 weeks.",
        'body_no_change' => 'Your plan still fits — no adjustments needed.',
    ],

];
