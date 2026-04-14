// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Cairn';

  @override
  String get getStarted => 'Get started';

  @override
  String get welcomeDescription =>
      'A personal LLM client that doubles as an English companion. You bring your own API key — everything stays on this device.';

  @override
  String get chooseProvider => 'Choose an AI provider';

  @override
  String get pickProviderHint => 'Pick any provider you have an API key for.';

  @override
  String get youProvideBaseUrl => 'You provide the base URL';

  @override
  String get apiKeyStoredLocally =>
      'Stored in your device keychain. Never sent anywhere else.';

  @override
  String get apiKey => 'API key';

  @override
  String get baseUrl => 'Base URL';

  @override
  String get fetchModels => 'Fetch models';

  @override
  String get selectAModel => 'Select a model';

  @override
  String modelsAvailable(int count, String provider) {
    return '$count models available from $provider';
  }

  @override
  String get verifyAndContinue => 'Verify and continue';

  @override
  String get apiKeyRequired => 'API key is required.';

  @override
  String get baseUrlRequired => 'Base URL is required.';

  @override
  String get couldNotFetchModels =>
      'Could not fetch models. Check key and URL.';

  @override
  String networkError(String error) {
    return 'Network error: $error';
  }

  @override
  String unexpectedError(String error) {
    return 'Unexpected error: $error';
  }

  @override
  String get pleaseSelectModel => 'Please select a model.';

  @override
  String get apiKeyInvalid => 'API key is invalid or unauthorized.';

  @override
  String get endpointNotFound => 'Endpoint not found. Check the base URL.';

  @override
  String get rateLimited => 'Rate limited or out of credit on this provider.';

  @override
  String get providerIssues =>
      'Provider is having issues. Try again in a moment.';

  @override
  String requestFailed(int status) {
    return 'Request failed with status $status.';
  }

  @override
  String get profile => 'Profile';

  @override
  String get tapToSetName => 'Tap to set name';

  @override
  String get displayName => 'Display Name';

  @override
  String get yourName => 'Your name';

  @override
  String get aboutMe => 'About me';

  @override
  String get aboutMePlaceholder =>
      'Tell AI a bit about yourself — your background, interests, or goals. This helps every conversation feel more relevant to you.';

  @override
  String get aboutMeHint => 'I\'m a backend engineer working on...';

  @override
  String get conversations => 'Conversations';

  @override
  String get messages => 'Messages';

  @override
  String get saved => 'Saved';

  @override
  String get library => 'Library';

  @override
  String get savedKnowledgeItems => 'Saved knowledge items';

  @override
  String get connections => 'Connections';

  @override
  String get knowledgeGraphClusters => 'Knowledge graph clusters';

  @override
  String get review => 'Review';

  @override
  String itemsDue(int count) {
    return '$count items due';
  }

  @override
  String get allCaughtUp => 'All caught up';

  @override
  String get knowledgeReport => 'Report';

  @override
  String get statsAboutKnowledge => 'Stats about your saved knowledge';

  @override
  String get providers => 'Providers';

  @override
  String providersConfigured(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 's',
      one: '',
    );
    return '$count provider$_temp0 configured';
  }

  @override
  String get personas => 'Personas';

  @override
  String get noCustomInstruction => 'No custom instruction';

  @override
  String get addPersona => 'Add persona';

  @override
  String get newPersona => 'New persona';

  @override
  String get editPersona => 'Edit persona';

  @override
  String get deletePersona => 'Delete persona?';

  @override
  String get cannotBeUndone => 'This cannot be undone.';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get create => 'Create';

  @override
  String get pickAnIcon => 'Pick an icon';

  @override
  String get name => 'Name';

  @override
  String get systemInstruction => 'System instruction';

  @override
  String get customInstructionsHint =>
      'Custom instructions appended to every message...';

  @override
  String get leaveEmptyForGeneral =>
      'Leave empty for a general-purpose assistant.';

  @override
  String get theme => 'Theme';

  @override
  String get explainPromptTemplate => 'Explain prompt template';

  @override
  String explainPromptHint(String word) {
    return 'Use $word as a placeholder for the looked-up word.';
  }

  @override
  String get apiUsage => 'API Usage';

  @override
  String get apiCalls => 'API calls';

  @override
  String get inputTokens => 'Input tokens';

  @override
  String get outputTokens => 'Output tokens';

  @override
  String get addProvider => 'Add provider';

  @override
  String get deleteProvider => 'Delete provider?';

  @override
  String removeProviderMessage(String name) {
    return 'Remove \"$name\" from this device.';
  }

  @override
  String get setAsDefault => 'Set as default';

  @override
  String get connectionTimedOut =>
      'Connection timed out. Check the base URL and try again.';

  @override
  String validationFailed(String error) {
    return 'Validation failed: $error';
  }

  @override
  String get validating => 'Validating...';

  @override
  String get kind => 'Kind';

  @override
  String get selectModel => 'Select Model';

  @override
  String get refreshModels => 'Refresh models';

  @override
  String get welcomeToCairn => 'Welcome to Cairn';

  @override
  String get typeMessageBelow => 'Type a message below';

  @override
  String get untitled => 'Untitled';

  @override
  String get messageHint => 'Message...';

  @override
  String get savedToLibrary => 'Saved to Library';

  @override
  String get view => 'View';

  @override
  String get searchConversations => 'Search conversations...';

  @override
  String get recent => 'Recent';

  @override
  String get chatHistory => 'Chat History';

  @override
  String get noConversationsYet => 'No conversations yet';

  @override
  String get newChat => 'New Chat';

  @override
  String get saveToLibrary => 'Save to Library';

  @override
  String get regenerate => 'Regenerate';

  @override
  String get copy => 'Copy';

  @override
  String get editAndResend => 'Edit & resend';

  @override
  String get editMessage => 'Edit message';

  @override
  String get editWillRerun => 'Editing will re-run the reply from this turn.';

  @override
  String get saveAndResend => 'Save & resend';

  @override
  String get noConnectionsYet => 'No connections yet';

  @override
  String get saveMoreForConnections =>
      'Save more items to discover knowledge connections.';

  @override
  String get refresh => 'Refresh';

  @override
  String remaining(int count) {
    return '$count remaining';
  }

  @override
  String get allCaughtUpTitle => 'All caught up!';

  @override
  String get noItemsDueForReview => 'No items due for review right now.';

  @override
  String get enableReviewForAll => 'Enable review for all items';

  @override
  String get viewFullItem => 'View full item';

  @override
  String get relatedKnowledge => 'Related knowledge';

  @override
  String get knowledgeHubs => 'Knowledge hubs';

  @override
  String get topTags => 'Top Tags';

  @override
  String get isolatedKnowledge => 'Isolated knowledge';

  @override
  String similarityPercent(int percent) {
    return '$percent% match';
  }

  @override
  String get tapToReveal => 'Tap to reveal';

  @override
  String get skip => 'Next';

  @override
  String get gotIt => 'Got it';

  @override
  String get forgot => 'Forgot';

  @override
  String get hard => 'Hard';

  @override
  String get good => 'Good';

  @override
  String get easy => 'Easy';

  @override
  String get stopReview => 'Don\'t review';

  @override
  String get graduated => 'Mastered';

  @override
  String intervalDays(int days) {
    return '${days}d';
  }

  @override
  String selectedCount(int count) {
    return '$count selected';
  }

  @override
  String get deselectAll => 'Deselect all';

  @override
  String get selectAll => 'Select all';

  @override
  String get saveFromUrl => 'Save from URL';

  @override
  String get importMarkdown => 'Import markdown';

  @override
  String get exportAsMarkdown => 'Export as Markdown';

  @override
  String get exportAsJson => 'Export as JSON';

  @override
  String get batchDelete => 'Batch delete';

  @override
  String get quickNote => 'Quick Note';

  @override
  String get searchHint => 'Search title, body, notes...';

  @override
  String get all => 'All';

  @override
  String get vocab => 'Vocab';

  @override
  String get insight => 'Insight';

  @override
  String get action => 'Action';

  @override
  String get fact => 'Fact';

  @override
  String get question => 'Question';

  @override
  String get noItemsToExport => 'No items to export';

  @override
  String importedCount(int count) {
    return 'Imported $count item(s)';
  }

  @override
  String deleteCountItems(int count) {
    return 'Delete $count item(s)?';
  }

  @override
  String get fetch => 'Fetch';

  @override
  String get fetchingPage => 'Fetching page...';

  @override
  String savedTitle(String title) {
    return 'Saved: $title';
  }

  @override
  String failedError(String error) {
    return 'Failed: $error';
  }

  @override
  String get titleOptional => 'Title (optional)';

  @override
  String get writeYourNote => 'Write your note...';

  @override
  String deleteFolderTitle(String folder) {
    return 'Delete \"$folder\"?';
  }

  @override
  String get deleteFolderMessage =>
      'Items in this folder will be moved to \"All\". This cannot be undone.';

  @override
  String get analyzing => 'Analyzing...';

  @override
  String get noMatches => 'No matches';

  @override
  String get messageMatches => 'In messages';

  @override
  String get geminiRecommended => 'Recommended: Qwen (Free tier)';

  @override
  String get geminiRecommendedDesc =>
      'Easy signup in China. Free tokens, supports both chat and knowledge-base semantic search.';

  @override
  String get getFreApiKey => 'Get free API key';

  @override
  String get nothingSavedYet => 'Nothing saved yet';

  @override
  String get tryDifferentKeyword => 'Try a different keyword.';

  @override
  String get longPressToSave => 'Long-press an AI reply in chat to save it.';

  @override
  String get justNow => 'just now';

  @override
  String minutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String hoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String daysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String get deleteItem => 'Delete item?';

  @override
  String get copyAsMarkdown => 'Copy as markdown';

  @override
  String get shareAsFile => 'Share as file';

  @override
  String get title => 'Title';

  @override
  String get myNotes => 'My notes';

  @override
  String get edit => 'Edit';

  @override
  String get addNotesHint => 'Add your own examples, memory hooks, context...';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get aiAnalyzingTags => 'AI is analyzing tags...';

  @override
  String get source => 'Source';

  @override
  String get tapToOpenSource => 'Tap to open source conversation';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String get week => 'Week';

  @override
  String get month => 'Month';

  @override
  String get allTime => 'All time';

  @override
  String get itemsSaved => 'Items saved';

  @override
  String get totalTags => 'Tags';

  @override
  String get totalEntities => 'Entities';

  @override
  String get typeDistribution => 'Type distribution';

  @override
  String get byType => 'By Type';

  @override
  String entitiesCount(int count) {
    return 'Entities ($count)';
  }

  @override
  String get offlineDictNotLoaded =>
      'Offline dictionary not loaded. Use AI explanation below.';

  @override
  String get wordNotFoundInDict =>
      'Not found in offline dictionary. Try AI explanation below.';

  @override
  String get aiDetailedExplanation => 'AI detailed explanation';

  @override
  String tokensCount(String count) {
    return '$count tokens';
  }

  @override
  String get aboutCairnTagline => 'Stack your knowledge, one stone at a time.';

  @override
  String get aboutCairnBody =>
      'Cairn is a privacy-first AI client that learns who you are and helps you build a personal knowledge base — one conversation at a time.\n\nTalk to any AI, your way. Bring your own API keys. Switch between providers and models freely. Set up AI personas with custom instructions — a writing coach, a coding mentor, a language partner — each one remembers how to talk to you.\n\nSave what matters. Long-press any AI reply to save it. Cairn automatically tags and categorizes your saved knowledge. Over time, your library becomes a searchable second brain.\n\nNever forget. Built-in spaced repetition surfaces saved items right when you\'re about to forget them. Knowledge isn\'t useful if it fades — Cairn makes sure it sticks.\n\nSee the bigger picture. The knowledge graph finds hidden connections between things you\'ve saved — linking concepts you didn\'t realize were related.\n\nLearn English along the way. Tap any word in a conversation for instant lookup and AI-powered explanations. It\'s not a separate app — it\'s woven into how you already use AI.\n\nYour data stays yours. No accounts. No cloud sync. No tracking. API keys are stored in your device\'s secure keychain. Everything lives on your phone.';

  @override
  String get madeWithLove => 'Stack stones. Build knowledge. Make it yours.';

  @override
  String get aboutAndFeedback => 'About & Feedback';

  @override
  String get sendFeedback => 'Send feedback';

  @override
  String get reportIssue => 'Report an issue';

  @override
  String get rateApp => 'Rate the app';

  @override
  String get openSourceLicenses => 'Open source licenses';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get termsOfService => 'Terms of service';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String get tools => 'Tools';

  @override
  String get functionCalling => 'Function Calling';

  @override
  String get functionCallingSubtitle =>
      'Allow AI to fetch real-time information';

  @override
  String get aiPersonalization => 'AI Personalization';

  @override
  String get aiPersonalizationSubtitle => 'About me & personas';

  @override
  String get language => 'Language';

  @override
  String get systemDefault => 'System default';

  @override
  String get lookup => 'Lookup';

  @override
  String get askFollowUp => 'Ask a follow-up...';

  @override
  String get customModel => 'Custom Model';

  @override
  String get newConversation => 'New conversation';

  @override
  String exportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String importFailed(String error) {
    return 'Import failed: $error';
  }

  @override
  String get feeds => 'Feeds';

  @override
  String get signals => 'Signals';

  @override
  String get dailyBrief => 'Daily Brief';

  @override
  String get addFeed => 'Add Feed';

  @override
  String get enterFeedUrl => 'Enter RSS or website URL';

  @override
  String get fetchingFeed => 'Fetching feed…';

  @override
  String get feedAdded => 'Feed added';

  @override
  String get noFeeds => 'No feeds yet';

  @override
  String get addFeedsHint => 'Add RSS feeds to start receiving signals';

  @override
  String get noSignals => 'No signals';

  @override
  String get noSignalsHint => 'Important signals will appear here';

  @override
  String get noBriefItems => 'Nothing in today\'s brief';

  @override
  String get noBriefHint => 'New articles will appear after feeds are fetched';

  @override
  String get readOriginal => 'Read original';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get act => 'Act';

  @override
  String get readAction => 'Read';

  @override
  String get skimAction => 'Skim';

  @override
  String signalCount(int count) {
    return '$count signals';
  }

  @override
  String get refreshing => 'Refreshing feeds…';

  @override
  String get strategiesLabel => 'Strategies';

  @override
  String get addStrategy => 'Add Strategy';

  @override
  String get strategyName => 'Strategy name';

  @override
  String get strategyDescription => 'Describe what to watch for';

  @override
  String feedAddFailed(String error) {
    return 'Failed to add feed: $error';
  }
}
