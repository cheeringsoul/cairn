import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Cairn'**
  String get appName;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @welcomeDescription.
  ///
  /// In en, this message translates to:
  /// **'A personal LLM client that doubles as an English companion. You bring your own API key — everything stays on this device.'**
  String get welcomeDescription;

  /// No description provided for @chooseProvider.
  ///
  /// In en, this message translates to:
  /// **'Choose an AI provider'**
  String get chooseProvider;

  /// No description provided for @pickProviderHint.
  ///
  /// In en, this message translates to:
  /// **'Pick any provider you have an API key for.'**
  String get pickProviderHint;

  /// No description provided for @youProvideBaseUrl.
  ///
  /// In en, this message translates to:
  /// **'You provide the base URL'**
  String get youProvideBaseUrl;

  /// No description provided for @apiKeyStoredLocally.
  ///
  /// In en, this message translates to:
  /// **'Stored in your device keychain. Never sent anywhere else.'**
  String get apiKeyStoredLocally;

  /// No description provided for @apiKey.
  ///
  /// In en, this message translates to:
  /// **'API key'**
  String get apiKey;

  /// No description provided for @baseUrl.
  ///
  /// In en, this message translates to:
  /// **'Base URL'**
  String get baseUrl;

  /// No description provided for @fetchModels.
  ///
  /// In en, this message translates to:
  /// **'Fetch models'**
  String get fetchModels;

  /// No description provided for @selectAModel.
  ///
  /// In en, this message translates to:
  /// **'Select a model'**
  String get selectAModel;

  /// No description provided for @modelsAvailable.
  ///
  /// In en, this message translates to:
  /// **'{count} models available from {provider}'**
  String modelsAvailable(int count, String provider);

  /// No description provided for @verifyAndContinue.
  ///
  /// In en, this message translates to:
  /// **'Verify and continue'**
  String get verifyAndContinue;

  /// No description provided for @apiKeyRequired.
  ///
  /// In en, this message translates to:
  /// **'API key is required.'**
  String get apiKeyRequired;

  /// No description provided for @baseUrlRequired.
  ///
  /// In en, this message translates to:
  /// **'Base URL is required.'**
  String get baseUrlRequired;

  /// No description provided for @couldNotFetchModels.
  ///
  /// In en, this message translates to:
  /// **'Could not fetch models. Check key and URL.'**
  String get couldNotFetchModels;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error: {error}'**
  String networkError(String error);

  /// No description provided for @unexpectedError.
  ///
  /// In en, this message translates to:
  /// **'Unexpected error: {error}'**
  String unexpectedError(String error);

  /// No description provided for @pleaseSelectModel.
  ///
  /// In en, this message translates to:
  /// **'Please select a model.'**
  String get pleaseSelectModel;

  /// No description provided for @apiKeyInvalid.
  ///
  /// In en, this message translates to:
  /// **'API key is invalid or unauthorized.'**
  String get apiKeyInvalid;

  /// No description provided for @endpointNotFound.
  ///
  /// In en, this message translates to:
  /// **'Endpoint not found. Check the base URL.'**
  String get endpointNotFound;

  /// No description provided for @rateLimited.
  ///
  /// In en, this message translates to:
  /// **'Rate limited or out of credit on this provider.'**
  String get rateLimited;

  /// No description provided for @providerIssues.
  ///
  /// In en, this message translates to:
  /// **'Provider is having issues. Try again in a moment.'**
  String get providerIssues;

  /// No description provided for @requestFailed.
  ///
  /// In en, this message translates to:
  /// **'Request failed with status {status}.'**
  String requestFailed(int status);

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @tapToSetName.
  ///
  /// In en, this message translates to:
  /// **'Tap to set name'**
  String get tapToSetName;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get displayName;

  /// No description provided for @yourName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get yourName;

  /// No description provided for @aboutMe.
  ///
  /// In en, this message translates to:
  /// **'About me'**
  String get aboutMe;

  /// No description provided for @aboutMePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Tell AI a bit about yourself — your background, interests, or goals. This helps every conversation feel more relevant to you.'**
  String get aboutMePlaceholder;

  /// No description provided for @aboutMeHint.
  ///
  /// In en, this message translates to:
  /// **'I\'m a backend engineer working on...'**
  String get aboutMeHint;

  /// No description provided for @conversations.
  ///
  /// In en, this message translates to:
  /// **'Conversations'**
  String get conversations;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @library.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get library;

  /// No description provided for @savedKnowledgeItems.
  ///
  /// In en, this message translates to:
  /// **'Saved knowledge items'**
  String get savedKnowledgeItems;

  /// No description provided for @connections.
  ///
  /// In en, this message translates to:
  /// **'Connections'**
  String get connections;

  /// No description provided for @knowledgeGraphClusters.
  ///
  /// In en, this message translates to:
  /// **'Knowledge graph clusters'**
  String get knowledgeGraphClusters;

  /// No description provided for @review.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get review;

  /// No description provided for @itemsDue.
  ///
  /// In en, this message translates to:
  /// **'{count} items due'**
  String itemsDue(int count);

  /// No description provided for @allCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'All caught up'**
  String get allCaughtUp;

  /// No description provided for @knowledgeReport.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get knowledgeReport;

  /// No description provided for @statsAboutKnowledge.
  ///
  /// In en, this message translates to:
  /// **'Stats about your saved knowledge'**
  String get statsAboutKnowledge;

  /// No description provided for @providers.
  ///
  /// In en, this message translates to:
  /// **'Providers'**
  String get providers;

  /// No description provided for @providersConfigured.
  ///
  /// In en, this message translates to:
  /// **'{count} provider{count, plural, =1{} other{s}} configured'**
  String providersConfigured(int count);

  /// No description provided for @personas.
  ///
  /// In en, this message translates to:
  /// **'Personas'**
  String get personas;

  /// No description provided for @noCustomInstruction.
  ///
  /// In en, this message translates to:
  /// **'No custom instruction'**
  String get noCustomInstruction;

  /// No description provided for @addPersona.
  ///
  /// In en, this message translates to:
  /// **'Add persona'**
  String get addPersona;

  /// No description provided for @newPersona.
  ///
  /// In en, this message translates to:
  /// **'New persona'**
  String get newPersona;

  /// No description provided for @editPersona.
  ///
  /// In en, this message translates to:
  /// **'Edit persona'**
  String get editPersona;

  /// No description provided for @deletePersona.
  ///
  /// In en, this message translates to:
  /// **'Delete persona?'**
  String get deletePersona;

  /// No description provided for @cannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get cannotBeUndone;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @pickAnIcon.
  ///
  /// In en, this message translates to:
  /// **'Pick an icon'**
  String get pickAnIcon;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @systemInstruction.
  ///
  /// In en, this message translates to:
  /// **'System instruction'**
  String get systemInstruction;

  /// No description provided for @customInstructionsHint.
  ///
  /// In en, this message translates to:
  /// **'Custom instructions appended to every message...'**
  String get customInstructionsHint;

  /// No description provided for @leaveEmptyForGeneral.
  ///
  /// In en, this message translates to:
  /// **'Leave empty for a general-purpose assistant.'**
  String get leaveEmptyForGeneral;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @explainPromptTemplate.
  ///
  /// In en, this message translates to:
  /// **'Explain prompt template'**
  String get explainPromptTemplate;

  /// No description provided for @explainPromptHint.
  ///
  /// In en, this message translates to:
  /// **'Use {word} as a placeholder for the looked-up word.'**
  String explainPromptHint(String word);

  /// No description provided for @apiUsage.
  ///
  /// In en, this message translates to:
  /// **'API Usage'**
  String get apiUsage;

  /// No description provided for @apiCalls.
  ///
  /// In en, this message translates to:
  /// **'API calls'**
  String get apiCalls;

  /// No description provided for @inputTokens.
  ///
  /// In en, this message translates to:
  /// **'Input tokens'**
  String get inputTokens;

  /// No description provided for @outputTokens.
  ///
  /// In en, this message translates to:
  /// **'Output tokens'**
  String get outputTokens;

  /// No description provided for @addProvider.
  ///
  /// In en, this message translates to:
  /// **'Add provider'**
  String get addProvider;

  /// No description provided for @deleteProvider.
  ///
  /// In en, this message translates to:
  /// **'Delete provider?'**
  String get deleteProvider;

  /// No description provided for @removeProviderMessage.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{name}\" from this device.'**
  String removeProviderMessage(String name);

  /// No description provided for @setAsDefault.
  ///
  /// In en, this message translates to:
  /// **'Set as default'**
  String get setAsDefault;

  /// No description provided for @connectionTimedOut.
  ///
  /// In en, this message translates to:
  /// **'Connection timed out. Check the base URL and try again.'**
  String get connectionTimedOut;

  /// No description provided for @validationFailed.
  ///
  /// In en, this message translates to:
  /// **'Validation failed: {error}'**
  String validationFailed(String error);

  /// No description provided for @validating.
  ///
  /// In en, this message translates to:
  /// **'Validating...'**
  String get validating;

  /// No description provided for @kind.
  ///
  /// In en, this message translates to:
  /// **'Kind'**
  String get kind;

  /// No description provided for @selectModel.
  ///
  /// In en, this message translates to:
  /// **'Select Model'**
  String get selectModel;

  /// No description provided for @refreshModels.
  ///
  /// In en, this message translates to:
  /// **'Refresh models'**
  String get refreshModels;

  /// No description provided for @welcomeToCairn.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Cairn'**
  String get welcomeToCairn;

  /// No description provided for @typeMessageBelow.
  ///
  /// In en, this message translates to:
  /// **'Type a message below'**
  String get typeMessageBelow;

  /// No description provided for @untitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get untitled;

  /// No description provided for @messageHint.
  ///
  /// In en, this message translates to:
  /// **'Message...'**
  String get messageHint;

  /// No description provided for @savedToLibrary.
  ///
  /// In en, this message translates to:
  /// **'Saved to Library'**
  String get savedToLibrary;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @searchConversations.
  ///
  /// In en, this message translates to:
  /// **'Search conversations...'**
  String get searchConversations;

  /// No description provided for @recent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recent;

  /// No description provided for @chatHistory.
  ///
  /// In en, this message translates to:
  /// **'Chat History'**
  String get chatHistory;

  /// No description provided for @noConversationsYet.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get noConversationsYet;

  /// No description provided for @newChat.
  ///
  /// In en, this message translates to:
  /// **'New Chat'**
  String get newChat;

  /// No description provided for @saveToLibrary.
  ///
  /// In en, this message translates to:
  /// **'Save to Library'**
  String get saveToLibrary;

  /// No description provided for @regenerate.
  ///
  /// In en, this message translates to:
  /// **'Regenerate'**
  String get regenerate;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @editAndResend.
  ///
  /// In en, this message translates to:
  /// **'Edit & resend'**
  String get editAndResend;

  /// No description provided for @editMessage.
  ///
  /// In en, this message translates to:
  /// **'Edit message'**
  String get editMessage;

  /// No description provided for @editWillRerun.
  ///
  /// In en, this message translates to:
  /// **'Editing will re-run the reply from this turn.'**
  String get editWillRerun;

  /// No description provided for @saveAndResend.
  ///
  /// In en, this message translates to:
  /// **'Save & resend'**
  String get saveAndResend;

  /// No description provided for @noConnectionsYet.
  ///
  /// In en, this message translates to:
  /// **'No connections yet'**
  String get noConnectionsYet;

  /// No description provided for @saveMoreForConnections.
  ///
  /// In en, this message translates to:
  /// **'Save more items to discover knowledge connections.'**
  String get saveMoreForConnections;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'{count} remaining'**
  String remaining(int count);

  /// No description provided for @allCaughtUpTitle.
  ///
  /// In en, this message translates to:
  /// **'All caught up!'**
  String get allCaughtUpTitle;

  /// No description provided for @noItemsDueForReview.
  ///
  /// In en, this message translates to:
  /// **'No items due for review right now.'**
  String get noItemsDueForReview;

  /// No description provided for @enableReviewForAll.
  ///
  /// In en, this message translates to:
  /// **'Enable review for all items'**
  String get enableReviewForAll;

  /// No description provided for @viewFullItem.
  ///
  /// In en, this message translates to:
  /// **'View full item'**
  String get viewFullItem;

  /// No description provided for @relatedKnowledge.
  ///
  /// In en, this message translates to:
  /// **'Related knowledge'**
  String get relatedKnowledge;

  /// No description provided for @knowledgeHubs.
  ///
  /// In en, this message translates to:
  /// **'Knowledge hubs'**
  String get knowledgeHubs;

  /// No description provided for @topTags.
  ///
  /// In en, this message translates to:
  /// **'Top Tags'**
  String get topTags;

  /// No description provided for @isolatedKnowledge.
  ///
  /// In en, this message translates to:
  /// **'Isolated knowledge'**
  String get isolatedKnowledge;

  /// No description provided for @similarityPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}% match'**
  String similarityPercent(int percent);

  /// No description provided for @tapToReveal.
  ///
  /// In en, this message translates to:
  /// **'Tap to reveal'**
  String get tapToReveal;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get skip;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @forgot.
  ///
  /// In en, this message translates to:
  /// **'Forgot'**
  String get forgot;

  /// No description provided for @hard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get hard;

  /// No description provided for @good.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get good;

  /// No description provided for @easy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get easy;

  /// No description provided for @stopReview.
  ///
  /// In en, this message translates to:
  /// **'Don\'t review'**
  String get stopReview;

  /// No description provided for @graduated.
  ///
  /// In en, this message translates to:
  /// **'Mastered'**
  String get graduated;

  /// No description provided for @intervalDays.
  ///
  /// In en, this message translates to:
  /// **'{days}d'**
  String intervalDays(int days);

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectedCount(int count);

  /// No description provided for @deselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect all'**
  String get deselectAll;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectAll;

  /// No description provided for @saveFromUrl.
  ///
  /// In en, this message translates to:
  /// **'Save from URL'**
  String get saveFromUrl;

  /// No description provided for @importMarkdown.
  ///
  /// In en, this message translates to:
  /// **'Import markdown'**
  String get importMarkdown;

  /// No description provided for @exportAsMarkdown.
  ///
  /// In en, this message translates to:
  /// **'Export as Markdown'**
  String get exportAsMarkdown;

  /// No description provided for @exportAsJson.
  ///
  /// In en, this message translates to:
  /// **'Export as JSON'**
  String get exportAsJson;

  /// No description provided for @batchDelete.
  ///
  /// In en, this message translates to:
  /// **'Batch delete'**
  String get batchDelete;

  /// No description provided for @quickNote.
  ///
  /// In en, this message translates to:
  /// **'Quick Note'**
  String get quickNote;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search title, body, notes...'**
  String get searchHint;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @vocab.
  ///
  /// In en, this message translates to:
  /// **'Vocab'**
  String get vocab;

  /// No description provided for @insight.
  ///
  /// In en, this message translates to:
  /// **'Insight'**
  String get insight;

  /// No description provided for @action.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get action;

  /// No description provided for @fact.
  ///
  /// In en, this message translates to:
  /// **'Fact'**
  String get fact;

  /// No description provided for @question.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get question;

  /// No description provided for @noItemsToExport.
  ///
  /// In en, this message translates to:
  /// **'No items to export'**
  String get noItemsToExport;

  /// No description provided for @importedCount.
  ///
  /// In en, this message translates to:
  /// **'Imported {count} item(s)'**
  String importedCount(int count);

  /// No description provided for @deleteCountItems.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} item(s)?'**
  String deleteCountItems(int count);

  /// No description provided for @fetch.
  ///
  /// In en, this message translates to:
  /// **'Fetch'**
  String get fetch;

  /// No description provided for @fetchingPage.
  ///
  /// In en, this message translates to:
  /// **'Fetching page...'**
  String get fetchingPage;

  /// No description provided for @savedTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved: {title}'**
  String savedTitle(String title);

  /// No description provided for @failedError.
  ///
  /// In en, this message translates to:
  /// **'Failed: {error}'**
  String failedError(String error);

  /// No description provided for @titleOptional.
  ///
  /// In en, this message translates to:
  /// **'Title (optional)'**
  String get titleOptional;

  /// No description provided for @writeYourNote.
  ///
  /// In en, this message translates to:
  /// **'Write your note...'**
  String get writeYourNote;

  /// No description provided for @deleteFolderTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{folder}\"?'**
  String deleteFolderTitle(String folder);

  /// No description provided for @deleteFolderMessage.
  ///
  /// In en, this message translates to:
  /// **'Items in this folder will be moved to \"All\". This cannot be undone.'**
  String get deleteFolderMessage;

  /// No description provided for @analyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing...'**
  String get analyzing;

  /// No description provided for @noMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get noMatches;

  /// No description provided for @messageMatches.
  ///
  /// In en, this message translates to:
  /// **'In messages'**
  String get messageMatches;

  /// No description provided for @geminiRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended: Qwen (Free tier)'**
  String get geminiRecommended;

  /// No description provided for @geminiRecommendedDesc.
  ///
  /// In en, this message translates to:
  /// **'Easy signup in China. Free tokens, supports both chat and knowledge-base semantic search.'**
  String get geminiRecommendedDesc;

  /// No description provided for @getFreApiKey.
  ///
  /// In en, this message translates to:
  /// **'Get free API key'**
  String get getFreApiKey;

  /// No description provided for @nothingSavedYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing saved yet'**
  String get nothingSavedYet;

  /// No description provided for @tryDifferentKeyword.
  ///
  /// In en, this message translates to:
  /// **'Try a different keyword.'**
  String get tryDifferentKeyword;

  /// No description provided for @longPressToSave.
  ///
  /// In en, this message translates to:
  /// **'Long-press an AI reply in chat to save it.'**
  String get longPressToSave;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String minutesAgo(int count);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String hoursAgo(int count);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String daysAgo(int count);

  /// No description provided for @deleteItem.
  ///
  /// In en, this message translates to:
  /// **'Delete item?'**
  String get deleteItem;

  /// No description provided for @copyAsMarkdown.
  ///
  /// In en, this message translates to:
  /// **'Copy as markdown'**
  String get copyAsMarkdown;

  /// No description provided for @shareAsFile.
  ///
  /// In en, this message translates to:
  /// **'Share as file'**
  String get shareAsFile;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @myNotes.
  ///
  /// In en, this message translates to:
  /// **'My notes'**
  String get myNotes;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @addNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Add your own examples, memory hooks, context...'**
  String get addNotesHint;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @aiAnalyzingTags.
  ///
  /// In en, this message translates to:
  /// **'AI is analyzing tags...'**
  String get aiAnalyzingTags;

  /// No description provided for @source.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get source;

  /// No description provided for @tapToOpenSource.
  ///
  /// In en, this message translates to:
  /// **'Tap to open source conversation'**
  String get tapToOpenSource;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @week.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get week;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// No description provided for @allTime.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get allTime;

  /// No description provided for @itemsSaved.
  ///
  /// In en, this message translates to:
  /// **'Items saved'**
  String get itemsSaved;

  /// No description provided for @totalTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get totalTags;

  /// No description provided for @totalEntities.
  ///
  /// In en, this message translates to:
  /// **'Entities'**
  String get totalEntities;

  /// No description provided for @typeDistribution.
  ///
  /// In en, this message translates to:
  /// **'Type distribution'**
  String get typeDistribution;

  /// No description provided for @byType.
  ///
  /// In en, this message translates to:
  /// **'By Type'**
  String get byType;

  /// No description provided for @entitiesCount.
  ///
  /// In en, this message translates to:
  /// **'Entities ({count})'**
  String entitiesCount(int count);

  /// No description provided for @offlineDictNotLoaded.
  ///
  /// In en, this message translates to:
  /// **'Offline dictionary not loaded. Use AI explanation below.'**
  String get offlineDictNotLoaded;

  /// No description provided for @wordNotFoundInDict.
  ///
  /// In en, this message translates to:
  /// **'Not found in offline dictionary. Try AI explanation below.'**
  String get wordNotFoundInDict;

  /// No description provided for @aiDetailedExplanation.
  ///
  /// In en, this message translates to:
  /// **'AI detailed explanation'**
  String get aiDetailedExplanation;

  /// No description provided for @tokensCount.
  ///
  /// In en, this message translates to:
  /// **'{count} tokens'**
  String tokensCount(String count);

  /// No description provided for @aboutCairnTagline.
  ///
  /// In en, this message translates to:
  /// **'Stack your knowledge, one stone at a time.'**
  String get aboutCairnTagline;

  /// No description provided for @aboutCairnBody.
  ///
  /// In en, this message translates to:
  /// **'Cairn is a privacy-first AI client that learns who you are and helps you build a personal knowledge base — one conversation at a time.\n\nTalk to any AI, your way. Bring your own API keys. Switch between providers and models freely. Set up AI personas with custom instructions — a writing coach, a coding mentor, a language partner — each one remembers how to talk to you.\n\nSave what matters. Long-press any AI reply to save it. Cairn automatically tags and categorizes your saved knowledge. Over time, your library becomes a searchable second brain.\n\nNever forget. Built-in spaced repetition surfaces saved items right when you\'re about to forget them. Knowledge isn\'t useful if it fades — Cairn makes sure it sticks.\n\nSee the bigger picture. The knowledge graph finds hidden connections between things you\'ve saved — linking concepts you didn\'t realize were related.\n\nLearn English along the way. Tap any word in a conversation for instant lookup and AI-powered explanations. It\'s not a separate app — it\'s woven into how you already use AI.\n\nYour data stays yours. No accounts. No cloud sync. No tracking. API keys are stored in your device\'s secure keychain. Everything lives on your phone.'**
  String get aboutCairnBody;

  /// No description provided for @madeWithLove.
  ///
  /// In en, this message translates to:
  /// **'Stack stones. Build knowledge. Make it yours.'**
  String get madeWithLove;

  /// No description provided for @aboutAndFeedback.
  ///
  /// In en, this message translates to:
  /// **'About & Feedback'**
  String get aboutAndFeedback;

  /// No description provided for @sendFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send feedback'**
  String get sendFeedback;

  /// No description provided for @reportIssue.
  ///
  /// In en, this message translates to:
  /// **'Report an issue'**
  String get reportIssue;

  /// No description provided for @rateApp.
  ///
  /// In en, this message translates to:
  /// **'Rate the app'**
  String get rateApp;

  /// No description provided for @openSourceLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open source licenses'**
  String get openSourceLicenses;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of service'**
  String get termsOfService;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String version(String version);

  /// No description provided for @tools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get tools;

  /// No description provided for @functionCalling.
  ///
  /// In en, this message translates to:
  /// **'Function Calling'**
  String get functionCalling;

  /// No description provided for @functionCallingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Allow AI to fetch real-time information'**
  String get functionCallingSubtitle;

  /// No description provided for @aiPersonalization.
  ///
  /// In en, this message translates to:
  /// **'AI Personalization'**
  String get aiPersonalization;

  /// No description provided for @aiPersonalizationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'About me & personas'**
  String get aiPersonalizationSubtitle;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get systemDefault;

  /// No description provided for @lookup.
  ///
  /// In en, this message translates to:
  /// **'Lookup'**
  String get lookup;

  /// No description provided for @askFollowUp.
  ///
  /// In en, this message translates to:
  /// **'Ask a follow-up...'**
  String get askFollowUp;

  /// No description provided for @customModel.
  ///
  /// In en, this message translates to:
  /// **'Custom Model'**
  String get customModel;

  /// No description provided for @newConversation.
  ///
  /// In en, this message translates to:
  /// **'New conversation'**
  String get newConversation;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String exportFailed(String error);

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String importFailed(String error);

  /// No description provided for @feeds.
  ///
  /// In en, this message translates to:
  /// **'Feeds'**
  String get feeds;

  /// No description provided for @signals.
  ///
  /// In en, this message translates to:
  /// **'Signals'**
  String get signals;

  /// No description provided for @dailyBrief.
  ///
  /// In en, this message translates to:
  /// **'Daily Brief'**
  String get dailyBrief;

  /// No description provided for @addFeed.
  ///
  /// In en, this message translates to:
  /// **'Add Feed'**
  String get addFeed;

  /// No description provided for @enterFeedUrl.
  ///
  /// In en, this message translates to:
  /// **'Enter RSS or website URL'**
  String get enterFeedUrl;

  /// No description provided for @fetchingFeed.
  ///
  /// In en, this message translates to:
  /// **'Fetching feed…'**
  String get fetchingFeed;

  /// No description provided for @feedAdded.
  ///
  /// In en, this message translates to:
  /// **'Feed added'**
  String get feedAdded;

  /// No description provided for @noFeeds.
  ///
  /// In en, this message translates to:
  /// **'No feeds yet'**
  String get noFeeds;

  /// No description provided for @addFeedsHint.
  ///
  /// In en, this message translates to:
  /// **'Add RSS feeds to start receiving signals'**
  String get addFeedsHint;

  /// No description provided for @noSignals.
  ///
  /// In en, this message translates to:
  /// **'No signals'**
  String get noSignals;

  /// No description provided for @noSignalsHint.
  ///
  /// In en, this message translates to:
  /// **'Important signals will appear here'**
  String get noSignalsHint;

  /// No description provided for @noBriefItems.
  ///
  /// In en, this message translates to:
  /// **'Nothing in today\'s brief'**
  String get noBriefItems;

  /// No description provided for @noBriefHint.
  ///
  /// In en, this message translates to:
  /// **'New articles will appear after feeds are fetched'**
  String get noBriefHint;

  /// No description provided for @readOriginal.
  ///
  /// In en, this message translates to:
  /// **'Read original'**
  String get readOriginal;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @act.
  ///
  /// In en, this message translates to:
  /// **'Act'**
  String get act;

  /// No description provided for @readAction.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get readAction;

  /// No description provided for @skimAction.
  ///
  /// In en, this message translates to:
  /// **'Skim'**
  String get skimAction;

  /// No description provided for @signalCount.
  ///
  /// In en, this message translates to:
  /// **'{count} signals'**
  String signalCount(int count);

  /// No description provided for @refreshing.
  ///
  /// In en, this message translates to:
  /// **'Refreshing feeds…'**
  String get refreshing;

  /// No description provided for @strategiesLabel.
  ///
  /// In en, this message translates to:
  /// **'Strategies'**
  String get strategiesLabel;

  /// No description provided for @addStrategy.
  ///
  /// In en, this message translates to:
  /// **'Add Strategy'**
  String get addStrategy;

  /// No description provided for @strategyName.
  ///
  /// In en, this message translates to:
  /// **'Strategy name'**
  String get strategyName;

  /// No description provided for @strategyDescription.
  ///
  /// In en, this message translates to:
  /// **'Describe what to watch for'**
  String get strategyDescription;

  /// No description provided for @feedAddFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to add feed: {error}'**
  String feedAddFailed(String error);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hant':
            return AppLocalizationsZhHant();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
