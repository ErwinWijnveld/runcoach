<?php

namespace App\Enums;

enum RaceDistance: string
{
    case FiveK = '5k';
    case TenK = '10k';
    case HalfMarathon = 'half_marathon';
    case Marathon = 'marathon';
    case Custom = 'custom';
}
