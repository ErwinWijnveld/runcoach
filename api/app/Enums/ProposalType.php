<?php

namespace App\Enums;

enum ProposalType: string
{
    case CreateSchedule = 'create_schedule';
    case ModifySchedule = 'modify_schedule';
    case AlternativeWeek = 'alternative_week';
}
