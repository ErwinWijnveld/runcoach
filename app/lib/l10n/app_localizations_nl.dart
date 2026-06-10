// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get appTitle => 'RunCoach';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageDutch => 'Nederlands';

  @override
  String get runShareSheetCta => 'Deel deze run';

  @override
  String get runShareSheetSubtitle => 'Tik om op te slaan of te delen';

  @override
  String get runShareInlineCta => 'Deel deze run';

  @override
  String get runShareBarrierLabel => 'Run samenvatting';

  @override
  String get runShareKpiDistance => 'AFSTAND';

  @override
  String get runShareKpiTime => 'TIJD';

  @override
  String get runShareKpiAvgPace => 'GEM. TEMPO';

  @override
  String get runShareKpiAvgHr => 'GEM. BPM';

  @override
  String get runShareKpiCompliance => 'OP SCHEMA';

  @override
  String get runShareIndoorPill => 'BINNEN GELOPEN';

  @override
  String get commonContinue => 'Doorgaan';

  @override
  String get commonTryAgain => 'Probeer opnieuw';

  @override
  String get commonRetry => 'Opnieuw proberen';

  @override
  String get commonSkip => 'Overslaan';

  @override
  String get commonRequired => 'Verplicht';

  @override
  String get commonSaving => 'Bezig met opslaan…';

  @override
  String get commonOpenSettings => 'Open Instellingen';

  @override
  String get commonAppleHealth => 'Apple Health';

  @override
  String get commonEditedByYou => 'Door jou bewerkt';

  @override
  String commonFromSource(String source) {
    return 'Van $source';
  }

  @override
  String get commonEditZones => 'Zones bewerken';

  @override
  String get authWelcomeEyebrow => 'JOUW AI-HARDLOOPCOACH';

  @override
  String get authWelcomeHeadlineLine1 => 'Train Smarter,';

  @override
  String get authWelcomeHeadlineLine2 => 'Not Harder';

  @override
  String get authWelcomeSignInButton => 'INLOGGEN MET APPLE';

  @override
  String get authAppleScreenTitle => 'Inloggen met Apple';

  @override
  String get authAppleErrorNoIdentityToken =>
      'Apple gaf geen identity-token terug.';

  @override
  String get authAppleErrorBackendRejected =>
      'De backend wees het Apple identity-token af.';

  @override
  String get authAppleErrorAuthEmpty =>
      'Authenticatie is leeg na succesvol inloggen. Controleer de API-URL en backend-logs.';

  @override
  String get authAppleErrorTitle => 'Inloggen mislukt';

  @override
  String get authAppleErrorRetry => 'Probeer opnieuw';

  @override
  String get onbConnectHealthIntroTitle => 'Apple Health koppelen';

  @override
  String get onbConnectHealthIntroBody =>
      'We lezen je hardloopworkouts, hartslagdata, leeftijd en rusthartslag in om je trainingen te scoren en je zones persoonlijk te maken.';

  @override
  String get onbConnectHealthConnectCta => 'Apple Health koppelen';

  @override
  String get onbConnectHealthSkipCta => 'Doorgaan zonder te synchroniseren';

  @override
  String get onbConnectHealthFooter =>
      'Garmin, Polar en Strava komen binnenkort.';

  @override
  String get onbConnectHealthEmptyTitle => 'Nog geen runs gevonden';

  @override
  String get onbConnectHealthEmptyBody =>
      'We konden geen hardloopworkouts uit Apple Health lezen. Misschien zijn er geen runs in de afgelopen 12 maanden, of is leestoegang niet verleend.';

  @override
  String get onbConnectHealthEmptyHint =>
      'Als je WEL runs hebt: open Instellingen → Gezondheid → Toegang tot gegevens en apparaten → RunCoach en zet Workouts + Hartslag aan.';

  @override
  String get onbConnectHealthStageRequesting => 'Apple Health vragen…';

  @override
  String get onbConnectHealthStageRequestingSub =>
      'Tik op \"Sta toe\" in de systeemmelding.';

  @override
  String get onbConnectHealthStageSyncing => 'Je runs ophalen…';

  @override
  String get onbConnectHealthStageSyncingSub =>
      'De laatste 12 maanden uit Apple Health worden gelezen.';

  @override
  String onbConnectHealthStageSyncingProgress(int done, int total) {
    return '$done van $total runs synchroniseren…';
  }

  @override
  String onbConnectHealthStageDone(int count) {
    return '$count runs gesynchroniseerd';
  }

  @override
  String get onbConnectHealthStageDoneSub => 'Je profiel wordt opgebouwd…';

  @override
  String get onbConnectHealthErrorPermission =>
      'Apple Health is niet bereikbaar. Probeer opnieuw?';

  @override
  String get onbConnectHealthErrorRead =>
      'We konden je runs niet uit Apple Health lezen. Probeer opnieuw?';

  @override
  String get onbConnectHealthErrorSync =>
      'We konden je runs niet naar de server synchroniseren. Controleer je verbinding en probeer opnieuw.';

  @override
  String get onbConnectHealthErrorSettings =>
      'Instellingen openen lukt niet automatisch. Ga naar Instellingen → Gezondheid → Toegang tot gegevens en apparaten → RunCoach.';

  @override
  String get onbOverviewTitlePrefilled => 'Je hardloopbasis';

  @override
  String get onbOverviewTitleEmpty => 'Vertel ons over je hardlopen';

  @override
  String get onbOverviewSubtitlePrefilled =>
      'We gebruiken dit om je trainingsplan af te stemmen.';

  @override
  String get onbOverviewSubtitleEmpty =>
      'We hebben twee getallen nodig om een goed plan te bouwen.';

  @override
  String get onbOverviewKmLabel =>
      'Gemiddeld aantal km per week (laatste 4 weken)';

  @override
  String get onbOverviewPaceLabel => 'Rustige looptempo';

  @override
  String get onbOverviewPaceTapPrompt => 'Tik om te kiezen';

  @override
  String get onbOverviewLoadingTitle => 'Je basis wordt geladen…';

  @override
  String get onbOverviewErrorTitle => 'We konden je gegevens niet laden.';

  @override
  String get onbZonesTitle => 'Je trainingszones';

  @override
  String onbZonesSubtitleDerivedCorrected(int maxHr) {
    return 'Op basis van je leeftijd en je zwaarste recente runs lijkt je maximale hartslag rond $maxHr bpm te liggen. Daar maken we 5 trainingszones van.';
  }

  @override
  String onbZonesSubtitleDerivedBasic(int age, int maxHr) {
    return 'Geschat op basis van je leeftijd ($age) — max rond $maxHr bpm. Na een paar zware sessies of een race verfijnen we dit automatisch.';
  }

  @override
  String get onbZonesSubtitleDerivedGeneric =>
      'Geschat op basis van je leeftijd. Tik op \"Zones bewerken\" als je je echte max hartslag kent.';

  @override
  String get onbZonesSubtitleManual =>
      'Je eerder opgeslagen zones. Hiermee wordt elke run beoordeeld.';

  @override
  String get onbZonesSubtitleDefault =>
      'We konden je zones niet automatisch berekenen — stel je max hartslag in voordat je doorgaat.';

  @override
  String get onbZonesConfirmCta => 'Klopt voor mij';

  @override
  String get onbZonesDobLabel => 'Geboortedatum';

  @override
  String get onbZonesDobBody =>
      'We gebruiken je leeftijd om hartslagzones te schatten voor trainingsfeedback. Je kunt ze later via het menu fijn afstellen.';

  @override
  String get onbZonesNoDobBody =>
      'Om je hartslagzones te schatten hebben we alleen je geboortedatum nodig. Daaruit komt een ruwe max-hartslag — goed genoeg voor dagelijkse training en eenvoudig later fijn af te stellen.';

  @override
  String get onbZonesShowAdvanced => 'Toon zones (geavanceerd)';

  @override
  String get onbZonesPickDobCta => 'Kies je geboortedatum';

  @override
  String get onbGeneratingTitle => 'Je plan wordt gebouwd';

  @override
  String get onbGeneratingStageAnalyzing =>
      'Je hardloopgeschiedenis wordt geanalyseerd…';

  @override
  String get onbGeneratingStageStructuring =>
      'Je weekstructuur wordt ontworpen…';

  @override
  String get onbGeneratingStagePlacing => 'Trainingssessies worden ingepland…';

  @override
  String get onbGeneratingStageFinalizing => 'Je plan wordt afgemaakt…';

  @override
  String get onbGeneratingFooter =>
      'Dit kan een paar minuten duren. Sluit de app gerust — we sturen je een melding zodra je plan klaar is.';

  @override
  String get onbGeneratingLoadingNext => 'Je plan wordt geladen…';

  @override
  String get onbGeneratingErrorTitle => 'Plan-generatie mislukt';

  @override
  String get onbGeneratingErrorNetwork =>
      'De server is niet bereikbaar. Controleer je verbinding.';

  @override
  String get onbGeneratingErrorLost =>
      'We zijn de generatie kwijtgeraakt. Probeer opnieuw?';

  @override
  String get onbGeneratingErrorGeneric => 'Generatie mislukt.';

  @override
  String get onbGeneratingErrorMissingId =>
      'Plan is klaar maar conversation-id ontbreekt.';

  @override
  String get onbGeneratingBackCta => 'Terug naar formulier';

  @override
  String get onbFormGoalTypeTitle => 'Waar train je voor?';

  @override
  String get onbFormGoalTypeSubtitle =>
      'We stemmen het plan af op je antwoord.';

  @override
  String get onbFormGoalTypeRaceLabel => 'Trainen voor een wedstrijd';

  @override
  String get onbFormGoalTypeRaceSubtitle =>
      'Je hebt een specifiek event in zicht.';

  @override
  String get onbFormGoalTypePrLabel => 'Sneller worden op een afstand';

  @override
  String get onbFormGoalTypePrSubtitle => 'Ga voor een persoonlijk record.';

  @override
  String get onbFormGoalTypeFitnessLabel => 'Algemene conditie';

  @override
  String get onbFormGoalTypeFitnessSubtitle =>
      'Regelmatig hardlopen, geen specifiek doel.';

  @override
  String get onbFormGoalTypeWeightLossLabel => 'Afvallen';

  @override
  String get onbFormGoalTypeWeightLossSubtitle =>
      'Consistent hardlopen om gestaag af te vallen.';

  @override
  String get onbFormGoalTypeOtherHint => 'Vertel waar je naar op zoek bent…';

  @override
  String get onbFormDistanceTitle => 'Welke afstand?';

  @override
  String get onbFormDistanceSubtitle => 'Kies de wedstrijd- of doelafstand.';

  @override
  String get onbFormDistance5k => '5K';

  @override
  String get onbFormDistance10k => '10K';

  @override
  String get onbFormDistanceHalf => 'Halve marathon';

  @override
  String get onbFormDistanceMarathon => 'Marathon';

  @override
  String get onbFormDistanceOtherHint => 'Afstand in kilometers';

  @override
  String get onbFormRaceNameTitle => 'Hoe heet de wedstrijd?';

  @override
  String get onbFormRaceNameSubtitle =>
      'Naam mag alles zijn, we gebruiken het alleen als label.';

  @override
  String get onbFormRaceNameHint => 'Rotterdam Marathon';

  @override
  String get onbFormRaceDateTitle => 'Wanneer is de wedstrijddag?';

  @override
  String get onbFormRaceDateSubtitle =>
      'We hebben minstens een paar weken nodig om een goed plan te bouwen.';

  @override
  String get onbFormGoalTimeTitle => 'Welke doeltijd of tempo streef je na?';

  @override
  String get onbFormGoalTimeSubtitle =>
      'Voer het in zoals je wilt, wij parsen het.';

  @override
  String get onbFormGoalTimeHint => 'bijv. 1:45:00, 25:30 of 5:30/km';

  @override
  String get onbFormPrTitle => 'Wat is je huidige PR?';

  @override
  String get onbFormPrSubtitlePrefilled =>
      'Vooraf ingevuld op basis van je snelste run uit Apple Health. Pas aan indien nodig.';

  @override
  String get onbFormPrSubtitleOptional =>
      'Optioneel, helpt ons een realistisch doel in te schatten.';

  @override
  String get onbFormPrHint => 'bijv. 1:52:00 of 5:45/km';

  @override
  String get onbFormGoalTimeParseError =>
      'Dat snap ik niet helemaal. Probeer 1:45:00 of 5:30/km.';

  @override
  String onbFormGoalTimePreview(String total, String paceSuffix) {
    return '≈ $total totaal$paceSuffix';
  }

  @override
  String onbFormGoalTimePreviewPaceSuffix(String pace) {
    return ' ($pace/km)';
  }

  @override
  String get onbFormDaysTitle => 'Hoeveel dagen per week?';

  @override
  String get onbFormDaysSubtitle =>
      'Wees realistisch. Het plan is zo goed als je consistentie.';

  @override
  String get onbFormDays1Label => '1 dag';

  @override
  String get onbFormDays1Sub => 'Houdt de gewoonte in leven.';

  @override
  String get onbFormDays2Label => '2 dagen';

  @override
  String get onbFormDays2Sub => 'Minimaal maar consistent.';

  @override
  String get onbFormDays3Label => '3 dagen';

  @override
  String get onbFormDays3Sub => 'Een stevige basis om op te bouwen.';

  @override
  String get onbFormDays4Label => '4 dagen';

  @override
  String get onbFormDays4Sub => 'Mooie balans voor de meeste lopers.';

  @override
  String get onbFormDays5Label => '5 dagen';

  @override
  String get onbFormDays5Sub => 'Solide blok voor serieuze doelen.';

  @override
  String get onbFormDays6Label => '6 dagen';

  @override
  String get onbFormDays6Sub => 'Hoog volume, voor ervaren lopers.';

  @override
  String get onbFormDays7Label => '7 dagen';

  @override
  String get onbFormDays7Sub => 'Elke dag, alleen als je herstel op orde is.';

  @override
  String get onbFormDaysOtherHint => 'Vertel me over je schema…';

  @override
  String get onbFormWeekdaysTitle => 'Op welke weekdagen kun je hardlopen?';

  @override
  String get onbFormWeekdaysSubtitle =>
      'Optioneel — kies de dagen die werken voor jou.';

  @override
  String get onbFormWeekdaysHintEnough => 'Laat leeg als elke dag werkt.';

  @override
  String onbFormWeekdaysHintShort(int required, int count) {
    return 'Kies minstens $required dagen (je hebt er $count).';
  }

  @override
  String get weekdayMon => 'Maandag';

  @override
  String get weekdayTue => 'Dinsdag';

  @override
  String get weekdayWed => 'Woensdag';

  @override
  String get weekdayThu => 'Donderdag';

  @override
  String get weekdayFri => 'Vrijdag';

  @override
  String get weekdaySat => 'Zaterdag';

  @override
  String get weekdaySun => 'Zondag';

  @override
  String get weekdayMonShort => 'Ma';

  @override
  String get weekdayTueShort => 'Di';

  @override
  String get weekdayWedShort => 'Wo';

  @override
  String get weekdayThuShort => 'Do';

  @override
  String get weekdayFriShort => 'Vr';

  @override
  String get weekdaySatShort => 'Za';

  @override
  String get weekdaySunShort => 'Zo';

  @override
  String get onbFormRankTitle => 'Rangschik je favoriete looptypes';

  @override
  String get onbFormRankSubtitle =>
      'Versleep om volgorde te wijzigen. Bovenaan = meer aandacht, onderaan = minder.';

  @override
  String get onbFormRankFooter =>
      'Lange duurlopen blijven in het plan. Ze onderaan zetten houdt ze alleen korter.';

  @override
  String get runTypeEasyLabel => 'Rustige duurloop';

  @override
  String get runTypeEasySub => 'Praattempo, basisvolume.';

  @override
  String get runTypeTempoLabel => 'Tempoloop';

  @override
  String get runTypeTempoSub => 'Volgehouden, comfortabel zwaar.';

  @override
  String get runTypeIntervalLabel => 'Intervals';

  @override
  String get runTypeIntervalSub => 'Korte zware herhalingen met herstel.';

  @override
  String get runTypeLongRunLabel => 'Lange duurloop';

  @override
  String get runTypeLongRunSub => 'Wekelijks uithoudingsvermogen.';

  @override
  String get onbFormCoachStyleTitle => 'Hoe moet ik je coachen?';

  @override
  String get onbFormCoachStyleSubtitle =>
      'Dit bepaalt de toon van het plan en hoe ik je push.';

  @override
  String get coachStyleBalancedLabel => 'Gebalanceerd';

  @override
  String get coachStyleBalancedSub => 'Structuur, met ruimte om aan te passen.';

  @override
  String get coachStyleStrictLabel => 'Streng';

  @override
  String get coachStyleStrictSub => 'Houd me eraan. Niet softer maken.';

  @override
  String get coachStyleFlexibleLabel => 'Flexibel';

  @override
  String get coachStyleFlexibleSub => 'Pas aan als het leven ertussen komt.';

  @override
  String get onbFormCoachStyleOtherHint => 'Vertel hoe je gecoacht wil worden…';

  @override
  String get onbFormRunnerLevelTitle => 'Hoe zou je je hardlopen omschrijven?';

  @override
  String get onbFormRunnerLevelSubtitle =>
      'Dit helpt ons de uitleg af te stemmen.';

  @override
  String get runnerLevelBeginnerLabel => 'Beginner';

  @override
  String get runnerLevelBeginnerSub => 'Net begonnen of terugkomend';

  @override
  String get runnerLevelIntermediateLabel => 'Gevorderd';

  @override
  String get runnerLevelIntermediateSub => 'Loopt regelmatig, racet af en toe';

  @override
  String get runnerLevelAdvancedLabel => 'Ervaren';

  @override
  String get runnerLevelAdvancedSub => 'Kent je zones, racet serieus';

  @override
  String get runnerLevelSubEliteLabel => 'Sub-Elite';

  @override
  String get runnerLevelSubEliteSub => 'Gestructureerde training, competitief';

  @override
  String get runnerLevelEliteLabel => 'Elite';

  @override
  String get runnerLevelEliteSub => 'Gesponsord of top-niveau competitief';

  @override
  String get onbFormIntensityTitle => 'Hoe pittig wil je dit?';

  @override
  String get onbFormIntensitySubtitle =>
      'Schuif omhoog of omlaag als je anders aanvoelt — Standaard past bij wat je doel vraagt.';

  @override
  String get onbFormIntensityEyebrow => 'KM PER WEEK';

  @override
  String get onbFormIntensityCaptionEasy =>
      'Zachtere opbouw, lagere piek. Vol te houden.';

  @override
  String get onbFormIntensityCaptionStandard =>
      'Stabiele wekelijkse opbouw. Auto-geselecteerd.';

  @override
  String get onbFormIntensityCaptionHarder =>
      'Steilere ramp, hogere piek. Blijf scherp.';

  @override
  String get intensityBiasEasyLabel => 'Rustig aan';

  @override
  String get intensityBiasStandardLabel => 'Standaard';

  @override
  String get intensityBiasHarderLabel => 'Push harder';

  @override
  String get intensityBiasEasyShort => 'Rustiger';

  @override
  String get intensityBiasStandardShort => 'Standaard';

  @override
  String get intensityBiasHarderShort => 'Pittiger';

  @override
  String get intensityBiasAutoPick => '(auto)';

  @override
  String get onbFormReviewTitle => 'Klaar om je plan te bouwen?';

  @override
  String get onbFormReviewSubtitle =>
      'Korte samenvatting. Ik neem het hier over.';

  @override
  String get onbFormReviewCreateCta => 'MAAK MIJN PLAN';

  @override
  String get onbFormReviewExtraNotesLabel => 'Nog iets voor je coach?';

  @override
  String get onbFormReviewExtraNotesHint =>
      'Blessures, schemavraagstukken, alles om rekening mee te houden…';

  @override
  String get reviewRowGoal => 'Doel';

  @override
  String get reviewRowDistance => 'Afstand';

  @override
  String get reviewRowRace => 'Wedstrijd';

  @override
  String get reviewRowRaceDay => 'Wedstrijddag';

  @override
  String get reviewRowGoalTime => 'Doeltijd';

  @override
  String get reviewRowCurrentPr => 'Huidige PR';

  @override
  String get reviewRowDaysPerWeek => 'Dagen / week';

  @override
  String get reviewRowPreferredDays => 'Voorkeursdagen';

  @override
  String get reviewRowCoachStyle => 'Coach-stijl';

  @override
  String get reviewRowRunnerLevel => 'Loopniveau';

  @override
  String get reviewRowIntensity => 'Intensiteit';

  @override
  String get reviewRowNotes => 'Notities';

  @override
  String get reviewGoalTypeRaceShort => 'Trainen voor wedstrijd';

  @override
  String get reviewGoalTypePrShort => 'Jaag op een PR';

  @override
  String get reviewGoalTypeFitnessShort => 'Algemene conditie';

  @override
  String get reviewGoalTypeWeightLossShort => 'Afvallen';

  @override
  String commonErrorWithMessage(String message) {
    return 'Fout: $message';
  }

  @override
  String get commonToday => 'Vandaag';

  @override
  String get commonTodayUpper => 'VANDAAG';

  @override
  String get commonTomorrow => 'Morgen';

  @override
  String get dashNoUpcomingRunEyebrow => 'GEEN GEPLANDE RUN';

  @override
  String get dashNoUpcomingTitle => 'Plan voltooid';

  @override
  String get dashNoUpcomingSubtitle =>
      'Alle trainingsdagen zijn geregistreerd.';

  @override
  String get dashThisWeekEyebrow => 'DEZE WEEK';

  @override
  String dashWeeksMatrixEyebrow(int total) {
    return '$total WEKEN';
  }

  @override
  String dashRaceDayLabel(String raceName) {
    return 'Wedstrijddag · $raceName';
  }

  @override
  String dashDaysToGoLabel(int days, String raceName) {
    return '${days}d · $raceName';
  }

  @override
  String dashWeeklySplitSuffix(String planned) {
    return ' / $planned km';
  }

  @override
  String get dashLegendDone => 'Gedaan';

  @override
  String get dashLegendMissed => 'Gemist';

  @override
  String get dashLegendUpcoming => 'Aankomend';

  @override
  String get dashLegendUnplanned => 'Buiten schema';

  @override
  String get dashEmptyTitle => 'Geen actief plan';

  @override
  String get dashEmptyBody =>
      'Kies een doel (of vraag de coach er een te bouwen) om je training op het dashboard te zien.';

  @override
  String get dashEmptyCta => 'Naar Doelen';

  @override
  String get dashRecentRunsEyebrow => 'RECENTE RUNS';

  @override
  String get dashRecentRunsSeeAll => 'Bekijk alles';

  @override
  String get dashRecentRunFallbackTitle => 'Run';

  @override
  String get schedWeeklyPlanTitle => 'Weekplan';

  @override
  String get schedKmTotal => 'KM TOTAAL';

  @override
  String schedWeekCounter(int n) {
    return 'WEEK $n';
  }

  @override
  String get schedBackToToday => 'Terug naar vandaag';

  @override
  String get schedNoTrainingWeek => 'Geen trainingsweek gevonden';

  @override
  String get schedEmptyTitle => 'Geen actief doel';

  @override
  String get schedEmptyBody =>
      'Kies een doel (of vraag de coach er een te bouwen) om je schema hier te zien.';

  @override
  String get schedEmptyCta => 'Naar Doelen';

  @override
  String get scheduleChatBarrierLabel => 'Chat over deze week';

  @override
  String scheduleChatViewingWeek(int weekNumber, String dateRange) {
    return 'Bekijkt week $weekNumber · $dateRange';
  }

  @override
  String scheduleChatTitle(int weekNumber, String dateRange) {
    return 'Week $weekNumber ($dateRange)';
  }

  @override
  String get scheduleChatEmptyTitle => 'Vraag over deze week';

  @override
  String get scheduleChatEmptySubtitle =>
      'Alles mag — tempo, intensiteit, swaps, herstel.';

  @override
  String weekChatSuggestionIntervalPace(String dayName) {
    return 'Hoe loop ik de intervals op $dayName?';
  }

  @override
  String get weekChatSuggestionIntervalPaceSub =>
      'Bepaal de juiste inspanning per rep.';

  @override
  String weekChatSuggestionLongRunPace(String dayName) {
    return 'Hoe loop ik de long run op $dayName?';
  }

  @override
  String get weekChatSuggestionLongRunPaceSub => 'Blijf aeroob, eindig sterk.';

  @override
  String get weekChatSuggestionDeloadWhy => 'Waarom is deze week rustiger?';

  @override
  String get weekChatSuggestionDeloadWhySub =>
      'Herstelweken en wat ze opleveren.';

  @override
  String get weekChatSuggestionRaceDayPrep =>
      'Wat doe ik de dag voor mijn race?';

  @override
  String get weekChatSuggestionRaceDayPrepSub =>
      'Routine, eten en slaap voor de wedstrijd.';

  @override
  String get weekChatSuggestionTooHard => 'Is deze week te zwaar voor mij?';

  @override
  String get weekChatSuggestionTooHardSub =>
      'Krijg een eerlijke check op de belasting.';

  @override
  String get weekChatSuggestionSwapInterval =>
      'Kunnen we een interval ruilen voor een long run?';

  @override
  String get weekChatSuggestionSwapIntervalSub =>
      'Pas de structuur van deze week aan.';

  @override
  String get schedDayTarget => 'DOEL';

  @override
  String get schedDayActual => 'WERKELIJK';

  @override
  String get schedDayDistance => 'AFSTAND';

  @override
  String get schedDayPace => 'TEMPO';

  @override
  String get schedDayPaceField => 'Tempo';

  @override
  String get schedDayDuration => 'DUUR';

  @override
  String get schedDayHr => 'HARTSLAG';

  @override
  String get schedDayHrZone => 'HR-ZONE';

  @override
  String get schedDayAvgHr => 'GEM HR';

  @override
  String get schedDayHeartRate => 'Hartslag';

  @override
  String get schedDayRecovery => 'Herstel';

  @override
  String get schedDayPaceCheckTitle => 'Tempocontrole';

  @override
  String get schedDaySendToWatch => 'STUUR NAAR WATCH';

  @override
  String get schedDaySendingToWatch => 'Wordt naar je watch gestuurd…';

  @override
  String get schedDayAdjustWorkout => 'Pas deze training aan';

  @override
  String get schedDayPickActivity => 'Kies activiteit';

  @override
  String get schedDayUnlinkActivity => 'Activiteit ontkoppelen';

  @override
  String get schedDayUnlinkConfirmTitle => 'Activiteit ontkoppelen?';

  @override
  String get schedDayUnlinkAction => 'Ontkoppel';

  @override
  String get schedDayMoveItAction => 'Verplaats';

  @override
  String get schedDayRescheduleAction => 'Verplaatsen';

  @override
  String get schedDayCouldNotReschedule => 'Verplaatsen mislukt';

  @override
  String planStartsNote(String date) {
    return 'Je plan start $date — eerdere dagen deze week zijn al voorbij.';
  }

  @override
  String get schedDayEditAction => 'Training aanpassen';

  @override
  String get editDayTitle => 'Training aanpassen';

  @override
  String get editDayDistanceLabel => 'Afstand';

  @override
  String get editDayPaceLabel => 'Tempo';

  @override
  String get editDayErrorTitle => 'Opslaan mislukt';

  @override
  String get editDayWarmupLabel => 'Warming-up';

  @override
  String get editDayCooldownLabel => 'Cooling-down';

  @override
  String get editDayWarmupOff => 'Geen';

  @override
  String editDayBlockLabel(int n) {
    return 'Blok $n';
  }

  @override
  String get editDayRepsLabel => 'Herhalingen';

  @override
  String get editDayRepDistanceLabel => 'Afstand per rep';

  @override
  String get editDayRepDurationLabel => 'Tijd per rep';

  @override
  String get editDayRecoveryLabel => 'Herstel';

  @override
  String get editDayAddBlock => 'Blok toevoegen';

  @override
  String get editDayDerivedDistanceLabel => 'Afstand (auto)';

  @override
  String get editDayRestStepLabel => 'Rust';

  @override
  String get commonOk => 'OK';

  @override
  String get commonCancel => 'Annuleren';

  @override
  String get commonClose => 'Sluiten';

  @override
  String get commonBack => 'Terug';

  @override
  String get schedOffPlanBadge => 'BUITEN SCHEMA';

  @override
  String get schedOffPlanRunTitle => 'Run';

  @override
  String get schedOffPlanLinkCta => 'Koppel aan training';

  @override
  String get schedOffPlanLinkErrorTitle => 'Koppelen mislukt';

  @override
  String get schedOffPlanPickTitle => 'Kies een training';

  @override
  String get schedOffPlanPickEmpty =>
      'Geen training dichtbij om aan te koppelen.';

  @override
  String get schedSectionIntervals => 'Intervals';

  @override
  String get schedSectionNotes => 'Notities';

  @override
  String get schedWatchNoDistanceBody =>
      'Deze training heeft geen afstand, dus kan niet op de watch worden ingepland.';

  @override
  String get schedWatchNoStepsBody =>
      'Deze intervalsessie heeft geen werkblokken om naar de watch te sturen.';

  @override
  String get schedWatchSentTitle => 'Verzonden naar je watch';

  @override
  String get schedWatchSentBody =>
      'Open de Fitness-app op je iPhone of Apple Watch om te beginnen.';

  @override
  String get schedWatchDuplicateTitle => 'Al ingepland';

  @override
  String get schedWatchDuplicateBody =>
      'Je hebt al een workout gepland voor deze dag in de Fitness-app.';

  @override
  String get schedWatchPermissionTitle => 'Toestemming nodig';

  @override
  String get schedWatchPermissionBody =>
      'Sta workout-planning toe via Instellingen → RunCoach om deze run naar je watch te sturen.';

  @override
  String get schedWatchUnavailableTitle => 'Niet beschikbaar';

  @override
  String get schedWatchUnavailableBody =>
      'Workouts naar de Apple Watch sturen vereist iOS 17 of nieuwer.';

  @override
  String get schedWatchGenericError => 'Er ging iets mis. Probeer opnieuw.';

  @override
  String get schedWatchNothingToSendTitle => 'Niets om te sturen';

  @override
  String get schedWatchInvalidDateBody =>
      'Deze trainingsdag heeft een ongeldige datum — vernieuw het schema.';

  @override
  String get schedWatchFailedTitle => 'Versturen mislukt';

  @override
  String get commonDelete => 'Verwijder';

  @override
  String get commonNo => 'Nee';

  @override
  String get goalsListYourGoals => 'Jouw doelen';

  @override
  String get goalsListOtherGoals => 'Andere doelen';

  @override
  String get goalsListEmptyTitle => 'Nog geen doelen';

  @override
  String get goalsListEmptyBody =>
      'Vraag de coach hieronder om je eerste trainingsplan te bouwen.';

  @override
  String get goalsCardActive => 'ACTIEF';

  @override
  String get goalsCardDistance => 'AFSTAND';

  @override
  String get goalsCardGoalTime => 'DOELTIJD';

  @override
  String get goalsCardTarget => 'DOEL';

  @override
  String get goalsCardDaysLeft => 'DAGEN OVER';

  @override
  String get goalsCardPast => 'VOORBIJ';

  @override
  String get goalsCardRaceDay => 'WEDSTRIJDDAG';

  @override
  String goalsCardDaysToGo(int days) {
    return 'NOG $days DAGEN';
  }

  @override
  String get goalsCardSwitch => 'Wissel';

  @override
  String get goalsSwitchTitle => 'Actief doel wisselen?';

  @override
  String goalsSwitchBody(String name) {
    return 'Maak \"$name\" je actieve doel. Je huidige actieve doel wordt gepauzeerd.';
  }

  @override
  String get goalsSwitchToThis => 'Wissel naar dit doel';

  @override
  String get goalsSwitchToThisBody =>
      'Je huidige actieve doel wordt gepauzeerd.';

  @override
  String get goalsDeleteGoal => 'Doel verwijderen';

  @override
  String goalsDeleteConfirmBody(String name) {
    return 'Weet je zeker dat je \"$name\" wilt verwijderen?';
  }

  @override
  String get goalsScheduleRowTitle => 'Trainingsschema';

  @override
  String get goalsScheduleRowSubtitle => 'Open je weekplan';

  @override
  String get goalsScheduleRowSubtitlePreview => 'Bekijk het plan van dit doel';

  @override
  String get commonError => 'Fout';

  @override
  String get commonDone => 'Klaar';

  @override
  String get orgConnectionsTitle => 'Verbindingen';

  @override
  String get orgSearchPlaceholder => 'Zoek gyms of clubs';

  @override
  String get orgAllOrganizations => 'Alle organisaties';

  @override
  String get orgResults => 'Resultaten';

  @override
  String get orgNoResults => 'Geen organisaties gevonden.';

  @override
  String get orgSectionActive => 'Actief lidmaatschap';

  @override
  String get orgSectionPendingInvites => 'Openstaande uitnodigingen';

  @override
  String get orgSectionPendingRequests => 'Openstaande verzoeken';

  @override
  String get orgLeaveConfirmTitle => 'Organisatie verlaten?';

  @override
  String get orgLeaveConfirmBody =>
      'Je verliest toegang tot je coach en de plannen die zij hebben gemaakt.';

  @override
  String get orgLeaveAction => 'Verlaten';

  @override
  String get orgLeaveButton => 'Organisatie verlaten';

  @override
  String get orgLeftSuccess => 'Organisatie verlaten';

  @override
  String orgRequestSent(String name) {
    return 'Verzoek verstuurd naar $name';
  }

  @override
  String get orgFallbackName => 'Organisatie';

  @override
  String orgRoleLine(String role) {
    return 'Rol: $role';
  }

  @override
  String orgCoachLine(String name) {
    return 'Coach: $name';
  }

  @override
  String orgInvitedAs(String role) {
    return 'Uitgenodigd als $role';
  }

  @override
  String get orgAccept => 'Accepteren';

  @override
  String get orgReject => 'Afwijzen';

  @override
  String get orgAwaitingApproval => 'Wacht op goedkeuring';

  @override
  String get orgJoin => 'Word lid';

  @override
  String get orgInviteTitle => 'Je bent uitgenodigd';

  @override
  String get orgInviteBody =>
      'Tik op accepteren om lid te worden van de organisatie. Bekijk je actieve lidmaatschap onder Verbindingen.';

  @override
  String get orgInviteAccept => 'Uitnodiging accepteren';

  @override
  String get orgInviteLater => 'Niet nu';

  @override
  String get coachChatListTitle => 'Coach-chat';

  @override
  String get coachChatListEmptyTitle => 'Nog geen gesprekken';

  @override
  String get coachChatListEmptySubtitle => 'Start een chat met je AI-coach';

  @override
  String get coachChatNewTitle => 'Nieuwe chat';

  @override
  String get coachChatDeleteErrorTitle => 'Chat verwijderen mislukt';

  @override
  String get coachChatDeleteErrorBody => 'Probeer opnieuw.';

  @override
  String get coachThinking => 'Aan het denken';

  @override
  String get coachAskFullCoach => 'Vraag de volledige coach';

  @override
  String get coachProposalRevisionEyebrow => 'PLAN-AANPASSING';

  @override
  String coachProposalChanges(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString wijzigingen in je plan',
      one: '1 wijziging in je plan',
    );
    return '$_temp0';
  }

  @override
  String get coachProposalRevisionBody =>
      'Tik hieronder om te bekijken wat is gewijzigd vóór toepassen.';

  @override
  String get coachProposalWeeklyKm => 'KM PER WEEK';

  @override
  String get coachProposalWeeklyRuns => 'RUNS PER WEEK';

  @override
  String get coachProposalViewChanges => 'BEKIJK WIJZIGINGEN';

  @override
  String get coachProposalViewDetails => 'BEKIJK DETAILS';

  @override
  String get coachProposalAccepted => 'Plan geaccepteerd.';

  @override
  String get coachProposalRejected => 'Afgewezen.';

  @override
  String get coachNewPlanCardCta => 'Start een nieuw trainingsplan';

  @override
  String get coachNewPlanCardEyebrow => 'NIEUW PLAN';

  @override
  String get coachNewPlanCardBody =>
      'Ik loop met je door je doel, datum en weekritme — je gesynchroniseerde rungeschiedenis is er al.';

  @override
  String get coachNewPlanCardButton => 'START NIEUW PLAN';

  @override
  String get coachSuggestionCreatePlan => 'Maak een trainingsplan';

  @override
  String get coachSuggestionCreatePlanSub =>
      'Voor een aankomende wedstrijd of nieuw doel.';

  @override
  String get coachSuggestionAdjust => 'Pas mijn schema aan';

  @override
  String get coachSuggestionAnalyze => 'Analyseer mijn voortgang';

  @override
  String get coachSuggestionAnalyzeSub => 'Hoe gaat het de laatste tijd?';

  @override
  String get coachSuggestionAnalyzePrompt =>
      'Hoe gaat mijn training? Geef me een analyse van mijn voortgang.';

  @override
  String get coachSuggestionAdvice => 'Trainingsadvies';

  @override
  String get coachSuggestionAdviceSub => 'Tempo, herstel, voeding, gear.';

  @override
  String get coachSuggestionAdvicePrompt =>
      'Heb je vandaag nog hardloopadvies voor me?';

  @override
  String get coachSuggestionCreatePlanPrompt =>
      'Ik wil een trainingsplan maken voor een aankomende wedstrijd';

  @override
  String get coachSuggestionAdjustSub => 'Pas het plan van deze week aan.';

  @override
  String get coachSuggestionAdjustPrompt =>
      'Kun je mijn trainingsschema voor deze week aanpassen?';

  @override
  String get coachEmptyStateTitle => 'Waar kan ik mee helpen?';

  @override
  String get coachEmptyStateSubtitle =>
      'Ik ken je trainingshistorie en kan je schema beheren.';

  @override
  String get workoutChatAdjust => 'Pas deze training aan';

  @override
  String get workoutChatAdjustSub => 'Afstand, tempo, intervals.';

  @override
  String get workoutChatWhatPlan => 'Wat is het plan';

  @override
  String get workoutChatWhatPlanSub => 'Waarom deze training, waarom vandaag.';

  @override
  String get workoutChatPaceCheckSub => 'Past het richttempo bij mij?';

  @override
  String get workoutChatMoveIt => 'Verplaatsen';

  @override
  String get workoutChatMoveItSub => 'Verplaats naar een andere dag.';

  @override
  String get trainingResultUnlinkErrorBody =>
      'Activiteit ontkoppelen mislukt. Probeer opnieuw.';

  @override
  String get intervalKindWarmup => 'Warming-up';

  @override
  String get intervalKindWork => 'Werk';

  @override
  String get intervalKindRecovery => 'Herstel';

  @override
  String get intervalKindCooldown => 'Cooling-down';

  @override
  String get coachRoleYou => 'Jij';

  @override
  String get coachRoleAssistant => 'RunCore AI-coach';

  @override
  String get coachMessageRetry => 'Opnieuw';

  @override
  String get coachStatsWeeklyAvgKm => 'GEM. KM\nPER WEEK';

  @override
  String get coachStatsWeeklyAvgRuns => 'GEM. RUNS\nPER WEEK';

  @override
  String get coachStatsAvgPace => 'GEM. TEMPO';

  @override
  String get coachStatsSessionAvgTime => 'GEM. SESSIE-\nTIJD';

  @override
  String get coachRevisionGoal => 'DOEL';

  @override
  String coachRevisionWeek(String number) {
    return 'WEEK $number';
  }

  @override
  String get coachRevisionBeforeChip => 'VOOR';

  @override
  String get coachRevisionAfterChip => 'NA';

  @override
  String coachRevisionChangeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wijzigingen in je plan',
      one: '1 wijziging in je plan',
    );
    return '$_temp0';
  }

  @override
  String get coachRevisionDayFallback => 'Dag';

  @override
  String coachRevisionAddedOn(String day) {
    return 'Toegevoegd op $day';
  }

  @override
  String coachRevisionRemovedSession(String day) {
    return 'Sessie op $day verwijderd';
  }

  @override
  String coachRevisionMovedTo(String day) {
    return 'Verplaatst naar $day';
  }

  @override
  String coachRevisionWasOn(String day) {
    return 'Stond op $day';
  }

  @override
  String coachRevisionUpdatedDay(String day) {
    return '$day bijgewerkt';
  }

  @override
  String get coachRevisionGoalUpdated => 'Doel-details bijgewerkt';

  @override
  String coachRevisionGoalFieldName(String value) {
    return 'Naam: $value';
  }

  @override
  String coachRevisionGoalFieldDistance(String value) {
    return 'Afstand: $value';
  }

  @override
  String coachRevisionGoalFieldDate(String value) {
    return 'Datum: $value';
  }

  @override
  String coachRevisionGoalFieldGoalTime(String value) {
    return 'Doeltijd: $value';
  }

  @override
  String coachRevisionGoalFieldDays(String value) {
    return 'Dagen: $value';
  }

  @override
  String get coachRevisionRunFallback => 'Run';

  @override
  String get coachChipOrTypeOwn => 'of typ je eigen';

  @override
  String get trainingResultHeader => 'Trainingsresultaat';

  @override
  String get trainingResultEyebrowCompliance => 'COMPLIANCE';

  @override
  String get trainingResultEyebrowTargetVsActual => 'DOEL VS WERKELIJK';

  @override
  String get trainingResultEyebrowCoachFeedback => 'COACH-FEEDBACK';

  @override
  String get trainingResultCompTarget => 'DOEL';

  @override
  String get trainingResultCompActual => 'WERKELIJK';

  @override
  String get trainingResultRowDistance => 'Afstand';

  @override
  String get trainingResultRowPace => 'Tempo';

  @override
  String get trainingResultRowHeartRate => 'Hartslag';

  @override
  String trainingResultHrZoneTarget(int zone) {
    return 'Zone $zone';
  }

  @override
  String get trainingResultUnlinkConfirmTitle => 'Activiteit ontkoppelen?';

  @override
  String get trainingResultUnlinkConfirmBody =>
      'De run blijft in Apple Health; hij wordt alleen niet meer gekoppeld aan deze trainingsdag.';

  @override
  String get trainingResultUnlinkAction => 'Ontkoppel';

  @override
  String get trainingResultUnlinkButton => 'Activiteit ontkoppelen';

  @override
  String get trainingResultUnlinkErrorTitle => 'Ontkoppelen mislukt';

  @override
  String get coachAnalysisEyebrow => 'COACH-ANALYSE';

  @override
  String get coachAnalysisCompliance => 'Compliance';

  @override
  String get coachAnalysisOpenCta => 'OPEN ANALYSE';

  @override
  String get coachAnalysisAnalysing => 'Je run wordt geanalyseerd…';

  @override
  String get selectActivityTitle => 'Kies een activiteit';

  @override
  String get selectActivitySubtitle =>
      'Runs uit de afgelopen week, gesynchroniseerd vanuit Apple Health.';

  @override
  String get selectActivityLoadError => 'Kon je activiteiten niet laden.';

  @override
  String get selectActivityNoneRecent => 'Geen recente activiteiten';

  @override
  String get selectActivityMatchErrorTitle => 'Run kon niet gekoppeld worden';

  @override
  String get selectActivitySyncedBadge => 'GESYNCHRONISEERD';

  @override
  String get selectActivityNoneRecentDetail =>
      'Niets gesynchroniseerd vanuit Apple Health in de afgelopen week.';

  @override
  String get rescheduleConfirmErrorTitle => 'Verplaatsen mislukt';

  @override
  String rescheduleMoveTo(String date) {
    return 'Verplaats naar $date';
  }

  @override
  String get wearableSummaryDistance => 'AFSTAND';

  @override
  String get wearableSummaryDuration => 'DUUR';

  @override
  String get wearableSummaryAvgHr => 'GEM HR';

  @override
  String get workoutChatEmptyTitle => 'Vraag iets over deze training';

  @override
  String get workoutChatEmptySubtitle =>
      'Ik ken je doelstats, splits en hoe het past in deze week.';

  @override
  String get workoutChatAdjustPrompt =>
      'Kunnen we deze training aanpassen? Ik zou graag ';

  @override
  String get workoutChatWhatPlanPrompt =>
      'Wat is het doel van deze training en waar moet ik op letten?';

  @override
  String get workoutChatPaceCheck => 'Tempocontrole';

  @override
  String get workoutChatPaceCheckPrompt =>
      'Is het richttempo realistisch op basis van mijn recente runs?';

  @override
  String get workoutChatMoveItPrompt =>
      'Kunnen we deze training verplaatsen naar ';

  @override
  String get planDetailsGoalFallback => 'Je trainingsplan';

  @override
  String get planDetailsEyebrowRevision => 'PLAN-AANPASSING';

  @override
  String get planDetailsEyebrowRecommended => 'AANBEVOLEN PLAN';

  @override
  String get planDetailsRevisionTitle => 'Bekijk je wijzigingen';

  @override
  String get planDetailsBreakdownLabel => 'WEEKOVERZICHT';

  @override
  String get planDetailsStatWeeks => 'WEKEN';

  @override
  String get planDetailsStatAvgKm => 'GEM KM / WEEK';

  @override
  String get planDetailsStatRunsPerWeek => 'RUNS / WEEK';

  @override
  String planDetailsWeekLabel(int number) {
    return 'Week $number';
  }

  @override
  String get planDetailsWeekFallback => 'Week';

  @override
  String get planDetailsKmTotal => 'KM TOTAAL';

  @override
  String get planDetailsDayRun => 'Run';

  @override
  String get planDetailsFooterClose => 'SLUITEN';

  @override
  String get planDetailsFooterAdjust => 'PAS AAN';

  @override
  String get planDetailsFooterApplyChanges => 'WIJZIGINGEN TOEPASSEN';

  @override
  String get planDetailsFooterAcceptPlan => 'ACCEPTEER PLAN';

  @override
  String get planDetailsFooterAdjustGoal =>
      'PAS DOEL AAN VOOR REALISTISCH PLAN';

  @override
  String get planDetailsFooterAcceptAnyway => 'Toch accepteren';

  @override
  String get planDetailsVolumeEyebrow => 'WEKELIJKS VOLUME';

  @override
  String planDetailsVolumePeak(String km, int week) {
    return 'Piek $km km · W$week';
  }

  @override
  String get planDetailsFeasibilityUnrealistic => 'Onhaalbaar';

  @override
  String get planDetailsFeasibilityStretch => 'Stretch';

  @override
  String get planDetailsFeasibilityOk => 'Goed';

  @override
  String get commonSave => 'Opslaan';

  @override
  String get commonConfirm => 'Bevestig';

  @override
  String get commonRunnerFallback => 'Hardloper';

  @override
  String get profileMenuConnections => 'Verbindingen';

  @override
  String get profileMenuAccount => 'Account';

  @override
  String get profileMenuHrZones => 'HR-zones';

  @override
  String get profileMenuPrivacy => 'Privacy';

  @override
  String get profileMenuAbout => 'Over';

  @override
  String get profileMenuDeleteData => 'Verwijder gegevens';

  @override
  String get profileMenuLogout => 'Uitloggen';

  @override
  String get profileMenuDeleteConfirmTitle => 'Verwijder gegevens';

  @override
  String get profileMenuDeleteConfirmBody =>
      'Dit verwijdert je account, doelen, trainingsschema en chats. Dit kan niet ongedaan worden gemaakt.';

  @override
  String get profileMenuDeleteConfirmAction => 'Verwijder';

  @override
  String get profileMenuDeleteErrorTitle => 'Kon gegevens niet verwijderen';

  @override
  String profileMenuDeleteErrorBody(String error) {
    return 'Probeer het opnieuw. ($error)';
  }

  @override
  String get profileMenuAccountTitle => 'Account';

  @override
  String get profileMenuFieldName => 'Naam';

  @override
  String get profileMenuFieldEmail => 'E-mail';

  @override
  String get profileMenuFieldNameHint => 'Je naam';

  @override
  String get profileMenuFieldNameEmptyError => 'Naam mag niet leeg zijn';

  @override
  String get coachPromptBarPlaceholder => 'Vraag het je coach...';

  @override
  String get birthDatePickerTitle => 'Geboortedatum';

  @override
  String get birthDatePickerDone => 'Klaar';

  @override
  String lockedFieldFromSource(String source) {
    return 'Van $source';
  }

  @override
  String get lockedFieldEditedByYou => 'Door jou bewerkt';

  @override
  String get lockedFieldOverrideTitle => 'Apple Health-gegevens overschrijven?';

  @override
  String get lockedFieldOverrideBody =>
      'Deze waarden zijn berekend uit je gesynchroniseerde rungeschiedenis en zijn waarschijnlijk het meest accurate signaal. Bewerken kan een minder accuraat trainingsplan opleveren.';

  @override
  String get lockedFieldEditAnyway => 'Toch bewerken';

  @override
  String get paceWheelPickerTitle => 'Rustige tempo';

  @override
  String get paceWheelPickerDone => 'Klaar';

  @override
  String get hrZonesSheetTitle => 'HR-zones';

  @override
  String get hrZonesSheetIntro =>
      'Bewerk de Max HR om alle zones te herberekenen, of pas een grens aan om de aangrenzende zone bij te werken.';

  @override
  String get hrZonesMaxHrLabel => 'Max HR';

  @override
  String get hrZonesRecomputeBusy => 'Bezig met herberekenen…';

  @override
  String get hrZonesRecomputeCta => 'Herbereken op basis van je runs';

  @override
  String get hrZonesErrorMaxHrRange =>
      'Max HR moet tussen 100 en 250 bpm liggen.';

  @override
  String get hrZonesErrorInvalidBpm => 'Voer geldige bpm-waarden in (0-250).';

  @override
  String get hrZonesErrorNotAscending => 'Zones moeten oplopend zijn.';

  @override
  String hrZonesErrorSaveFailed(String error) {
    return 'Opslaan mislukt: $error';
  }

  @override
  String hrZonesUpdatedCorrected(int maxHr) {
    return 'Bijgewerkt — max ~$maxHr bpm (leeftijd + je zwaarste recente runs).';
  }

  @override
  String hrZonesUpdatedDerivedAge(int maxHr, int age) {
    return 'Bijgewerkt — max ~$maxHr bpm (geschat vanaf leeftijd $age).';
  }

  @override
  String get hrZonesUpdatedGenericAge => 'Bijgewerkt vanaf je leeftijd.';

  @override
  String get notificationsSheetTitle => 'MELDINGEN';

  @override
  String notificationsSheetLoadError(String error) {
    return 'Kon meldingen niet laden.\n$error';
  }

  @override
  String get notificationsSheetEmpty => 'Je bent volledig bijgewerkt.';

  @override
  String get notificationsCardDismiss => 'VERWIJDEREN';

  @override
  String get notificationsCardApply => 'TOEPASSEN';

  @override
  String get notificationsCardViewEvaluation => 'Bekijk je evaluatie';

  @override
  String get notificationsTypePlanEvaluation => '2-WEKEN EVALUATIE';

  @override
  String get evaluationCardEyebrow => 'EVALUATIE';

  @override
  String evaluationCardScheduledFor(String date) {
    return 'Gepland voor $date';
  }

  @override
  String evaluationCardWeekTitle(int week) {
    return 'Week $week check-in';
  }

  @override
  String get evaluationCardStatusPending => 'Volgende';

  @override
  String get evaluationCardStatusProcessing => 'Bezig…';

  @override
  String get evaluationCardStatusReady => 'Rapport klaar';

  @override
  String get evaluationCardStatusNoChange => 'Geen aanpassing nodig';

  @override
  String get evaluationCardStatusAccepted => 'Toegepast';

  @override
  String get evaluationCardStatusDismissed => 'Genegeerd';

  @override
  String get evaluationCardCtaView => 'Openen';

  @override
  String get evaluationDetailTitle => '2-weken evaluatie';

  @override
  String get evaluationDetailReportHeader => 'Wat je coach zegt';

  @override
  String get evaluationDetailProposalHeader => 'Voorgestelde aanpassing';

  @override
  String get evaluationDetailApply => 'AANPASSING TOEPASSEN';

  @override
  String get evaluationDetailDismiss => 'VERWIJDEREN';

  @override
  String get evaluationDetailClose => 'SLUITEN';

  @override
  String get evaluationDetailNoReport => 'Nog geen rapport beschikbaar.';

  @override
  String evaluationDetailLoadError(String error) {
    return 'Kon de evaluatie niet laden.\n$error';
  }

  @override
  String get hrZoneNameZ1 => 'Duurvermogen';

  @override
  String get hrZoneNameZ2 => 'Matig';

  @override
  String get hrZoneNameZ3 => 'Tempo';

  @override
  String get hrZoneNameZ4 => 'Drempel';

  @override
  String get hrZoneNameZ5 => 'Anaeroob';

  @override
  String get hrZoneBpm => 'bpm';

  @override
  String get settingsTitle => 'Instellingen';

  @override
  String get settingsLanguageTitle => 'Taal';

  @override
  String get settingsLanguageSubtitle =>
      'Kies in welke taal RunCoach met je communiceert.';

  @override
  String get settingsLanguageAuto => 'Systeemstandaard';

  @override
  String get settingsLanguageAutoSubtitle => 'Volgt je apparaattaal.';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageDutch => 'Nederlands';

  @override
  String get settingsLanguageActiveBadge => 'ACTIEF';

  @override
  String weeklyPlanWeekRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String weeklyPlanDayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count runs',
      one: '1 run',
    );
    return '$_temp0';
  }

  @override
  String get bootPopupTitle => 'Actie vereist';

  @override
  String bootPopupBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Je hebt $count openstaande suggesties die je aandacht nodig hebben.',
      one: 'Je hebt 1 openstaande suggestie die je aandacht nodig heeft.',
    );
    return '$_temp0';
  }

  @override
  String get bootPopupLater => 'Later';

  @override
  String get bootPopupView => 'Bekijk';

  @override
  String get tabDashboard => 'Dashboard';

  @override
  String get tabSchedule => 'Schema';

  @override
  String get tabChat => 'Chat';

  @override
  String get tabGoals => 'Doelen';

  @override
  String get trainingStatusMissed => 'GEMIST';

  @override
  String get trainingStatusSynced => 'ACTIVITEIT GESYNCED';

  @override
  String get trainingStatusAwaitingSync => 'WACHT OP SYNC';

  @override
  String get trainingStatusUpcoming => 'RUN STAAT GEPLAND';

  @override
  String get trainingDayStatusMissed => 'GEMIST';

  @override
  String get trainingDayStatusCompleted => 'VOLTOOID';

  @override
  String get trainingDayStatusUpcoming => 'GEPLAND';

  @override
  String get workoutChatBarrierLabel => 'Sluit workout-chat';

  @override
  String get trainingDayWatchCouldNotSend => 'Verzenden mislukt';

  @override
  String get analyzingChipSyncingTitle => 'Je runs synchroniseren';

  @override
  String get analyzingChipSyncingSubtitle =>
      'Nieuwe runs ophalen uit Apple Health…';

  @override
  String get analyzingChipMatchingTitle => 'Koppelen aan je trainingsplan';

  @override
  String get analyzingChipMatchingSubtitle => 'Een moment…';

  @override
  String get analyzingChipAnalysingTitle => 'AI analyseert je run';

  @override
  String get analyzingChipAnalysingSubtitle =>
      'Persoonlijke feedback wordt gegenereerd…';

  @override
  String get analyzingChipReadyTitle => 'Analyse klaar';

  @override
  String analyzingChipReadyComplianceSubtitle(String score) {
    return 'Compliance $score/10';
  }

  @override
  String get analyzingChipReadyTapToView => 'Tik om te bekijken';

  @override
  String get analyzingChipLoggedTitle => 'Run vastgelegd';

  @override
  String get analyzingChipLoggedNoMatch => 'Geen passende trainingsdag';

  @override
  String get trainingResultNoResultYet => 'Nog geen resultaat vastgelegd.';

  @override
  String get goalDetailSectionTraining => 'Training';

  @override
  String get goalDetailSectionNotActive => 'Niet actief';

  @override
  String get chatErrorConnectionInterrupted =>
      'Verbinding onderbroken. Tik om opnieuw te proberen.';

  @override
  String get chatErrorRequestTimedOut => 'Verzoek verlopen';

  @override
  String get chatErrorCannotReachServer => 'Server niet bereikbaar';

  @override
  String chatErrorServerStatus(String status) {
    return 'Serverfout ($status)';
  }

  @override
  String get chatErrorUnknown => 'Onbekende fout';

  @override
  String get watchOnlyOnIos =>
      'Workouts naar je watch sturen kan alleen op iOS.';

  @override
  String get watchNativeBridgeError => 'Native-bridge fout.';

  @override
  String watchRecomputeFailed(String error) {
    return 'Herberekenen mislukt: $error';
  }

  @override
  String get toolIndicatorDefault => 'Bezig…';

  @override
  String get toolIndicatorGetRecentRuns => 'Je laatste runs ophalen…';

  @override
  String get toolIndicatorSearchActivities => 'Je activiteiten doorzoeken…';

  @override
  String get toolIndicatorGetActivityDetails => 'Die run nader bekijken…';

  @override
  String get toolIndicatorGetCurrentSchedule => 'Je schema laden…';

  @override
  String get toolIndicatorGetGoalInfo => 'Je doel controleren…';

  @override
  String get toolIndicatorGetComplianceReport => 'Compliance beoordelen…';

  @override
  String get toolIndicatorCreateSchedule => 'Je trainingsplan opbouwen…';

  @override
  String get toolIndicatorEditSchedule => 'Je plan herzien…';

  @override
  String get toolIndicatorModifySchedule => 'Je schema aanpassen…';

  @override
  String get toolIndicatorGetCurrentProposal => 'Het voorstel bekijken…';

  @override
  String get toolIndicatorGetRunningProfile =>
      'Je hardloopgeschiedenis analyseren…';

  @override
  String get toolIndicatorPresentRunningStats => 'Je stats voorbereiden…';

  @override
  String get toolIndicatorOfferChoices => 'Opties klaarzetten…';

  @override
  String get toolIndicatorEditWorkout => 'Deze workout aanpassen…';

  @override
  String get toolIndicatorRescheduleWorkout => 'Deze workout verplaatsen…';

  @override
  String get toolIndicatorEscalateToCoach => 'Doorsturen naar je coach…';

  @override
  String get choiceGroupOther => 'Anders';

  @override
  String get orgJoinedSnack => 'Aangesloten bij organisatie';

  @override
  String get newChatTitle => 'Nieuwe chat';

  @override
  String get trainingCoachSuggestion1 => 'Verplaats deze run naar morgen…';

  @override
  String get trainingCoachSuggestion2 => 'Maak dit lichter, ik voel me moe…';

  @override
  String get trainingCoachSuggestion3 => 'Waarom is het tempo vandaag zo snel?';

  @override
  String get trainingCoachSuggestion4 => 'Wissel om naar een rustdag…';

  @override
  String get trainingCoachSuggestion5 => 'Verkort dit naar 5 km…';

  @override
  String get trainingCoachSuggestion6 => 'Wat als ik de intervallen oversla?';

  @override
  String get trainingCoachSuggestion7 => 'Kan dit op de loopband?';

  @override
  String get trainingCoachSuggestion8 => 'Leg het doel van deze sessie uit…';

  @override
  String get scheduleCoachSuggestion1 => 'Maak van de easy run een interval...';

  @override
  String get scheduleCoachSuggestion2 =>
      'Verplaats maandag-workouts naar donderdag...';

  @override
  String get scheduleCoachSuggestion3 => 'Word ik in het juiste tempo beter?';

  @override
  String get scheduleCoachSuggestion4 => 'Zet mijn long run op zaterdag...';

  @override
  String get scheduleCoachSuggestion5 =>
      'Maak van deze week een hersteldweek...';

  @override
  String get scheduleCoachSuggestion6 => 'Moet ik harder trainen deze week?';

  @override
  String get scheduleCoachSuggestion7 => 'Wat is het doel van woensdag?';

  @override
  String get scheduleCoachSuggestion8 =>
      'Schrap één easy run, ik heb rust nodig...';

  @override
  String get scheduleCoachSuggestion9 => 'Lig ik op koers voor mijn race?';

  @override
  String get scheduleCoachSuggestion10 => 'Leg de tempo-sessie uit...';

  @override
  String get scheduleCoachSuggestion11 =>
      'Kunnen we een heuvel-sessie toevoegen?';

  @override
  String get scheduleCoachSuggestion12 => 'Ik was gisteren kapot, pas aan...';

  @override
  String get goalCoachSuggestion1 => 'Train me voor een marathon...';

  @override
  String get goalCoachSuggestion2 => 'Help me sneller te worden op 10k...';

  @override
  String get goalCoachSuggestion3 => 'Ik heb een halve marathon in mei...';

  @override
  String get goalCoachSuggestion4 => 'Wat is een realistisch PR-doel?';

  @override
  String get goalCoachSuggestion5 => 'Bouw een fitnessplan voor me...';

  @override
  String get goalCoachSuggestion6 => 'Ik wil onder 45 op 10k...';

  @override
  String get goalCoachSuggestion7 => 'Maak me racefit in 12 weken...';

  @override
  String get goalCoachSuggestion8 => 'Kunnen we een sub-4 marathon mikken?';

  @override
  String get goalCoachSuggestion9 => 'Ontwerp een base-building blok...';

  @override
  String get goalCoachSuggestion10 => 'Plan mijn volgende trainingscyclus...';

  @override
  String get wearableActivityFallbackName => 'Run';

  @override
  String get trainingTypeEasy => 'Rustig';

  @override
  String get trainingTypeTempo => 'Tempo';

  @override
  String get trainingTypeInterval => 'Intervals';

  @override
  String get trainingTypeLongRun => 'Lange duurloop';

  @override
  String get trainingTypeThreshold => 'Drempel';

  @override
  String get paywallEyebrow => 'JOUW PLAN';

  @override
  String get paywallPreviewTitle => 'Jouw trainingsplan';

  @override
  String get paywallUnlockCta => 'ONTGRENDEL RUNCOACH PRO';

  @override
  String get paywallNoDaysPlaceholder => 'Geen sessies deze week.';

  @override
  String get paywallLockedHint => 'PRO';

  @override
  String paywallWeekEyebrow(int weekNumber) {
    return 'WEEK $weekNumber';
  }

  @override
  String paywallWeekTotalKm(String km) {
    return '$km km totaal';
  }

  @override
  String get paywallManageSubscription => 'Beheer abonnement';

  @override
  String get paywallProBadge => 'PRO';

  @override
  String get paywallProTrialBadge => 'PRO · PROEF';

  @override
  String paywallLockedWeeksTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Nog $count weken',
      one: 'Nog 1 week',
    );
    return '$_temp0';
  }

  @override
  String get paywallLockedWeeksSubtitle =>
      'Ontgrendel RunCoach Pro om je volledige plan te zien';

  @override
  String get paywallLapsedTitle => 'Je RunCoach Pro is verlopen';

  @override
  String get paywallLapsedSubtitle =>
      'Sluit opnieuw een abonnement af om je AI-coach te gebruiken, je runs te synchroniseren en je trainingsschema actueel te houden.';
}
