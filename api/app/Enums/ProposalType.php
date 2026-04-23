<?php

namespace App\Enums;

use App\Enums\Concerns\HasValues;

enum ProposalType: string
{
    use HasValues;

    case CreateSchedule = 'create_schedule';
    case ModifySchedule = 'modify_schedule';
    case EditActivePlan = 'edit_active_plan';
    case AlternativeWeek = 'alternative_week';
}
