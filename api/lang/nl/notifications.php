<?php

return [

    'plan_generation' => [
        'completed' => [
            'title' => 'Je trainingsplan staat klaar',
            'body' => 'Tik om te bekijken en goed te keuren.',
        ],
        'failed' => [
            'title' => 'Plan-generatie liep vast',
            'body' => 'Tik om opnieuw te proberen.',
        ],
    ],

    'training_day' => [
        'fallback_title' => 'Loop van vandaag',
        'fallback_body' => 'Tik voor de details.',
        'title_with_km' => 'Vandaag: :km km :type',
        'title_without_km' => 'Vandaag: :type',
        'target_pace' => 'Richttempo :pace/km',
        'tap_for_details' => 'Tik voor details.',
    ],

    'birthday_zone_check' => [
        'title' => 'Gefeliciteerd! 🎂',
        'body' => 'Je bent een jaar wijzer — laten we je hartslagzones bijwerken.',
    ],

    'plan_evaluation' => [
        'title' => 'Je 2-weken evaluatie staat klaar',
        'body_with_proposal' => 'We hebben een kleine aanpassing voorgesteld op basis van je laatste 2 weken.',
        'body_no_change' => 'Je plan klopt nog — geen aanpassingen nodig.',
    ],

];
