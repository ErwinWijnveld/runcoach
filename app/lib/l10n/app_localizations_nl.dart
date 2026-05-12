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
}
