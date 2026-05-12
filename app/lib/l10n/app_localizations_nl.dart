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
  String get authWelcomeHeadlineLine1 => 'Slimmer trainen,';

  @override
  String get authWelcomeHeadlineLine2 => 'Niet zwaarder';

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
  String get dashEmptyTitle => 'Geen actief plan';

  @override
  String get dashEmptyBody =>
      'Kies een doel (of vraag de coach er een te bouwen) om je training op het dashboard te zien.';

  @override
  String get dashEmptyCta => 'Naar Doelen';

  @override
  String get schedWeeklyPlanTitle => 'Weekplan';

  @override
  String get schedKmTotal => 'KM TOTAAL';

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
  String get commonOk => 'OK';

  @override
  String get commonCancel => 'Annuleren';

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
}
