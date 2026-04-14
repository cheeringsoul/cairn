// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'Cairn';

  @override
  String get getStarted => '开始使用';

  @override
  String get welcomeDescription =>
      '一个兼具英语学习功能的个人 LLM 客户端。使用你自己的 API 密钥，所有数据留在本地。';

  @override
  String get chooseProvider => '选择 AI 服务商';

  @override
  String get pickProviderHint => '选择你拥有 API 密钥的服务商。';

  @override
  String get youProvideBaseUrl => '由你提供 Base URL';

  @override
  String get apiKeyStoredLocally => '密钥存储在设备钥匙串中，不会发送到其他地方。';

  @override
  String get apiKey => 'API 密钥';

  @override
  String get baseUrl => 'Base URL';

  @override
  String get fetchModels => '获取模型列表';

  @override
  String get selectAModel => '选择模型';

  @override
  String modelsAvailable(int count, String provider) {
    return '$provider 提供了 $count 个可用模型';
  }

  @override
  String get verifyAndContinue => '验证并继续';

  @override
  String get apiKeyRequired => '请输入 API 密钥。';

  @override
  String get baseUrlRequired => '请输入 Base URL。';

  @override
  String get couldNotFetchModels => '无法获取模型列表，请检查密钥和 URL。';

  @override
  String networkError(String error) {
    return '网络错误：$error';
  }

  @override
  String unexpectedError(String error) {
    return '未知错误：$error';
  }

  @override
  String get pleaseSelectModel => '请选择一个模型。';

  @override
  String get apiKeyInvalid => 'API 密钥无效或未授权。';

  @override
  String get endpointNotFound => '找不到接口地址，请检查 Base URL。';

  @override
  String get rateLimited => '请求过于频繁或额度已用完。';

  @override
  String get providerIssues => '服务商暂时出现问题，请稍后重试。';

  @override
  String requestFailed(int status) {
    return '请求失败，状态码 $status。';
  }

  @override
  String get profile => '个人中心';

  @override
  String get tapToSetName => '点击设置名称';

  @override
  String get displayName => '显示名称';

  @override
  String get yourName => '你的名字';

  @override
  String get aboutMe => '关于我';

  @override
  String get aboutMePlaceholder => '告诉 AI 一些关于你的信息——背景、兴趣或目标。这有助于让每次对话更贴合你。';

  @override
  String get aboutMeHint => '我是一名后端工程师，正在做……';

  @override
  String get conversations => '对话';

  @override
  String get messages => '消息';

  @override
  String get saved => '已保存';

  @override
  String get library => '资料库';

  @override
  String get savedKnowledgeItems => '已保存的知识条目';

  @override
  String get connections => '知识关联';

  @override
  String get knowledgeGraphClusters => '知识图谱聚类';

  @override
  String get review => '复习';

  @override
  String itemsDue(int count) {
    return '$count 项待复习';
  }

  @override
  String get allCaughtUp => '已全部完成';

  @override
  String get knowledgeReport => '知识报告';

  @override
  String get statsAboutKnowledge => '关于已保存知识的统计';

  @override
  String get providers => '服务商';

  @override
  String providersConfigured(int count) {
    return '已配置 $count 个服务商';
  }

  @override
  String get personas => '角色';

  @override
  String get noCustomInstruction => '无自定义指令';

  @override
  String get addPersona => '添加角色';

  @override
  String get newPersona => '新建角色';

  @override
  String get editPersona => '编辑角色';

  @override
  String get deletePersona => '删除角色？';

  @override
  String get cannotBeUndone => '此操作无法撤销。';

  @override
  String get cancel => '取消';

  @override
  String get save => '保存';

  @override
  String get delete => '删除';

  @override
  String get create => '创建';

  @override
  String get pickAnIcon => '选择图标';

  @override
  String get name => '名称';

  @override
  String get systemInstruction => '系统指令';

  @override
  String get customInstructionsHint => '附加到每条消息的自定义指令……';

  @override
  String get leaveEmptyForGeneral => '留空则作为通用助手。';

  @override
  String get theme => '主题';

  @override
  String get explainPromptTemplate => '释义提示词模板';

  @override
  String explainPromptHint(String word) {
    return '使用 $word 作为查询词的占位符。';
  }

  @override
  String get apiUsage => 'API 用量';

  @override
  String get apiCalls => 'API 调用';

  @override
  String get inputTokens => '输入 Token';

  @override
  String get outputTokens => '输出 Token';

  @override
  String get addProvider => '添加服务商';

  @override
  String get deleteProvider => '删除服务商？';

  @override
  String removeProviderMessage(String name) {
    return '从此设备移除「$name」。';
  }

  @override
  String get setAsDefault => '设为默认';

  @override
  String get connectionTimedOut => '连接超时，请检查 Base URL 后重试。';

  @override
  String validationFailed(String error) {
    return '验证失败：$error';
  }

  @override
  String get validating => '验证中……';

  @override
  String get kind => '类型';

  @override
  String get selectModel => '选择模型';

  @override
  String get refreshModels => '刷新模型列表';

  @override
  String get welcomeToCairn => '欢迎使用 Cairn';

  @override
  String get typeMessageBelow => '在下方输入消息';

  @override
  String get untitled => '无标题';

  @override
  String get messageHint => '输入消息……';

  @override
  String get savedToLibrary => '已保存到资料库';

  @override
  String get view => '查看';

  @override
  String get searchConversations => '搜索对话……';

  @override
  String get recent => '最近';

  @override
  String get chatHistory => '历史对话';

  @override
  String get noConversationsYet => '暂无对话';

  @override
  String get newChat => '新对话';

  @override
  String get saveToLibrary => '保存到知识库';

  @override
  String get regenerate => '重新生成';

  @override
  String get copy => '复制';

  @override
  String get editAndResend => '编辑并重发';

  @override
  String get editMessage => '编辑消息';

  @override
  String get editWillRerun => '编辑后将从此轮重新生成回复。';

  @override
  String get saveAndResend => '保存并重发';

  @override
  String get noConnectionsYet => '暂无关联';

  @override
  String get saveMoreForConnections => '保存更多条目以发现知识关联。';

  @override
  String get refresh => '刷新';

  @override
  String remaining(int count) {
    return '剩余 $count 项';
  }

  @override
  String get allCaughtUpTitle => '全部完成！';

  @override
  String get noItemsDueForReview => '目前没有需要复习的条目。';

  @override
  String get enableReviewForAll => '为所有条目开启复习';

  @override
  String get viewFullItem => '查看完整条目';

  @override
  String get relatedKnowledge => '相关知识';

  @override
  String get knowledgeHubs => '知识枢纽';

  @override
  String get topTags => '热门标签';

  @override
  String get isolatedKnowledge => '孤立知识';

  @override
  String similarityPercent(int percent) {
    return '$percent% 相关';
  }

  @override
  String get tapToReveal => '点击揭示';

  @override
  String get skip => '下一个';

  @override
  String get gotIt => '记住了';

  @override
  String get forgot => '忘了';

  @override
  String get hard => '模糊';

  @override
  String get good => '记得';

  @override
  String get easy => '轻松';

  @override
  String get stopReview => '不再复习';

  @override
  String get graduated => '已掌握';

  @override
  String intervalDays(int days) {
    return '$days天';
  }

  @override
  String selectedCount(int count) {
    return '已选 $count 项';
  }

  @override
  String get deselectAll => '取消全选';

  @override
  String get selectAll => '全选';

  @override
  String get saveFromUrl => '从 URL 保存';

  @override
  String get importMarkdown => '导入 Markdown';

  @override
  String get exportAsMarkdown => '导出为 Markdown';

  @override
  String get exportAsJson => '导出为 JSON';

  @override
  String get batchDelete => '批量删除';

  @override
  String get quickNote => '快速笔记';

  @override
  String get searchHint => '搜索标题、正文、笔记……';

  @override
  String get all => '全部';

  @override
  String get vocab => '词汇';

  @override
  String get insight => '见解';

  @override
  String get action => '行动';

  @override
  String get fact => '事实';

  @override
  String get question => '问题';

  @override
  String get noItemsToExport => '没有可导出的条目';

  @override
  String importedCount(int count) {
    return '已导入 $count 个条目';
  }

  @override
  String deleteCountItems(int count) {
    return '删除 $count 个条目？';
  }

  @override
  String get fetch => '获取';

  @override
  String get fetchingPage => '正在获取页面……';

  @override
  String savedTitle(String title) {
    return '已保存：$title';
  }

  @override
  String failedError(String error) {
    return '失败：$error';
  }

  @override
  String get titleOptional => '标题（可选）';

  @override
  String get writeYourNote => '写下你的笔记……';

  @override
  String deleteFolderTitle(String folder) {
    return '删除「$folder」？';
  }

  @override
  String get deleteFolderMessage => '文件夹中的条目将移至「全部」。此操作无法撤销。';

  @override
  String get analyzing => '分析中……';

  @override
  String get noMatches => '未找到匹配';

  @override
  String get messageMatches => '消息内容匹配';

  @override
  String get geminiRecommended => '推荐：通义千问（免费额度）';

  @override
  String get geminiRecommendedDesc => '国内访问流畅，注册即送免费 Token，支持对话和知识库语义检索。';

  @override
  String get getFreApiKey => '获取免费 API Key';

  @override
  String get nothingSavedYet => '还没有保存任何内容';

  @override
  String get tryDifferentKeyword => '试试其他关键词。';

  @override
  String get longPressToSave => '长按 AI 回复即可保存。';

  @override
  String get justNow => '刚刚';

  @override
  String minutesAgo(int count) {
    return '$count分钟前';
  }

  @override
  String hoursAgo(int count) {
    return '$count小时前';
  }

  @override
  String daysAgo(int count) {
    return '$count天前';
  }

  @override
  String get deleteItem => '删除条目？';

  @override
  String get copyAsMarkdown => '复制为 Markdown';

  @override
  String get shareAsFile => '分享为文件';

  @override
  String get title => '标题';

  @override
  String get myNotes => '我的笔记';

  @override
  String get edit => '编辑';

  @override
  String get addNotesHint => '添加你自己的例句、记忆方法、上下文……';

  @override
  String get saveChanges => '保存更改';

  @override
  String get aiAnalyzingTags => 'AI 正在分析标签……';

  @override
  String get source => '来源';

  @override
  String get tapToOpenSource => '点击打开来源对话';

  @override
  String get copiedToClipboard => '已复制到剪贴板';

  @override
  String get week => '周';

  @override
  String get month => '月';

  @override
  String get allTime => '全部';

  @override
  String get itemsSaved => '已保存条目';

  @override
  String get totalTags => '标签';

  @override
  String get totalEntities => '实体';

  @override
  String get typeDistribution => '类型分布';

  @override
  String get byType => '按类型';

  @override
  String entitiesCount(int count) {
    return '实体（$count）';
  }

  @override
  String get offlineDictNotLoaded => '离线词典未加载，请使用下方 AI 释义。';

  @override
  String get wordNotFoundInDict => '离线词典中未找到该词，可使用下方 AI 释义。';

  @override
  String get aiDetailedExplanation => 'AI 详细释义';

  @override
  String tokensCount(String count) {
    return '$count tokens';
  }

  @override
  String get aboutCairnTagline => '积石成塔，聚知成识。';

  @override
  String get aboutCairnBody =>
      'Cairn 是一个注重隐私的 AI 客户端。它了解你是谁，帮你在每一次对话中积累属于自己的知识库。\n\n自由对话，随心所欲。使用你自己的 API 密钥，在不同服务商和模型之间自由切换。设定不同的 AI 角色——写作教练、编程导师、语言伙伴——每个角色都知道该怎么和你交流。\n\n留住重要的东西。长按任意 AI 回复即可保存。Cairn 会自动标注和分类你保存的知识。日积月累，你的资料库会成为一个可搜索的第二大脑。\n\n永远不忘。内置间隔重复算法，在你即将遗忘时主动提醒复习。知识如果会褪色就没有意义——Cairn 确保它留下来。\n\n发现更大的图景。知识图谱会自动发现你保存内容之间隐藏的关联——串联起那些你自己都没意识到相关的概念。\n\n顺便学好英语。对话中点击任意单词，即刻查词并获取 AI 详细释义。它不是一个独立的学习应用——而是融入你日常使用 AI 的方式之中。\n\n数据只属于你。无需注册，不同步云端，不追踪隐私。API 密钥存储在设备安全钥匙串中。一切都在你的手机上。';

  @override
  String get madeWithLove => '积石成塔，聚知成识，为己所用。';

  @override
  String get aboutAndFeedback => '关于与反馈';

  @override
  String get sendFeedback => '发送反馈';

  @override
  String get reportIssue => '报告问题';

  @override
  String get rateApp => '给应用评分';

  @override
  String get openSourceLicenses => '开源许可';

  @override
  String get privacyPolicy => '隐私政策';

  @override
  String get termsOfService => '使用条款';

  @override
  String version(String version) {
    return '版本 $version';
  }

  @override
  String get tools => '工具';

  @override
  String get functionCalling => 'Function Calling';

  @override
  String get functionCallingSubtitle => '允许 AI 获取实时信息';

  @override
  String get aiPersonalization => 'AI 个性化';

  @override
  String get aiPersonalizationSubtitle => '关于我与角色设定';

  @override
  String get language => '语言';

  @override
  String get systemDefault => '跟随系统';

  @override
  String get lookup => '查词';

  @override
  String get askFollowUp => '继续追问……';

  @override
  String get customModel => '自定义模型';

  @override
  String get newConversation => '新对话';

  @override
  String exportFailed(String error) {
    return '导出失败：$error';
  }

  @override
  String importFailed(String error) {
    return '导入失败：$error';
  }

  @override
  String get feeds => '信息源';

  @override
  String get signals => '信号';

  @override
  String get dailyBrief => '每日简报';

  @override
  String get addFeed => '添加信息源';

  @override
  String get enterFeedUrl => '输入 RSS 或网站地址';

  @override
  String get fetchingFeed => '正在获取…';

  @override
  String get feedAdded => '已添加';

  @override
  String get noFeeds => '暂无信息源';

  @override
  String get addFeedsHint => '添加 RSS 信息源，开始接收信号';

  @override
  String get noSignals => '暂无信号';

  @override
  String get noSignalsHint => '重要信号会出现在这里';

  @override
  String get noBriefItems => '今日简报为空';

  @override
  String get noBriefHint => '抓取信息源后，新文章会出现在这里';

  @override
  String get readOriginal => '阅读原文';

  @override
  String get dismiss => '忽略';

  @override
  String get act => '行动';

  @override
  String get readAction => '细读';

  @override
  String get skimAction => '略读';

  @override
  String signalCount(int count) {
    return '$count 条信号';
  }

  @override
  String get refreshing => '正在刷新…';

  @override
  String get strategiesLabel => '策略';

  @override
  String get addStrategy => '添加策略';

  @override
  String get strategyName => '策略名称';

  @override
  String get strategyDescription => '描述要监控什么';

  @override
  String feedAddFailed(String error) {
    return '添加失败：$error';
  }
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');

  @override
  String get appName => 'Cairn';

  @override
  String get getStarted => '開始使用';

  @override
  String get welcomeDescription =>
      '一個兼具英語學習功能的個人 LLM 用戶端。使用你自己的 API 金鑰，所有資料留在本地。';

  @override
  String get chooseProvider => '選擇 AI 服務商';

  @override
  String get pickProviderHint => '選擇你擁有 API 金鑰的服務商。';

  @override
  String get youProvideBaseUrl => '由你提供 Base URL';

  @override
  String get apiKeyStoredLocally => '金鑰儲存在裝置鑰匙圈中，不會傳送到其他地方。';

  @override
  String get apiKey => 'API 金鑰';

  @override
  String get baseUrl => 'Base URL';

  @override
  String get fetchModels => '取得模型列表';

  @override
  String get selectAModel => '選擇模型';

  @override
  String modelsAvailable(int count, String provider) {
    return '$provider 提供了 $count 個可用模型';
  }

  @override
  String get verifyAndContinue => '驗證並繼續';

  @override
  String get apiKeyRequired => '請輸入 API 金鑰。';

  @override
  String get baseUrlRequired => '請輸入 Base URL。';

  @override
  String get couldNotFetchModels => '無法取得模型列表，請檢查金鑰和 URL。';

  @override
  String networkError(String error) {
    return '網路錯誤：$error';
  }

  @override
  String unexpectedError(String error) {
    return '未知錯誤：$error';
  }

  @override
  String get pleaseSelectModel => '請選擇一個模型。';

  @override
  String get apiKeyInvalid => 'API 金鑰無效或未授權。';

  @override
  String get endpointNotFound => '找不到介面位址，請檢查 Base URL。';

  @override
  String get rateLimited => '請求過於頻繁或額度已用完。';

  @override
  String get providerIssues => '服務商暫時出現問題，請稍後重試。';

  @override
  String requestFailed(int status) {
    return '請求失敗，狀態碼 $status。';
  }

  @override
  String get profile => '個人中心';

  @override
  String get tapToSetName => '點擊設定名稱';

  @override
  String get displayName => '顯示名稱';

  @override
  String get yourName => '你的名字';

  @override
  String get aboutMe => '關於我';

  @override
  String get aboutMePlaceholder => '告訴 AI 一些關於你的資訊——背景、興趣或目標。這有助於讓每次對話更貼合你。';

  @override
  String get aboutMeHint => '我是一名後端工程師，正在做……';

  @override
  String get conversations => '對話';

  @override
  String get messages => '訊息';

  @override
  String get saved => '已儲存';

  @override
  String get library => '資料庫';

  @override
  String get savedKnowledgeItems => '已儲存的知識條目';

  @override
  String get connections => '知識關聯';

  @override
  String get knowledgeGraphClusters => '知識圖譜聚類';

  @override
  String get review => '複習';

  @override
  String itemsDue(int count) {
    return '$count 項待複習';
  }

  @override
  String get allCaughtUp => '已全部完成';

  @override
  String get knowledgeReport => '知識報告';

  @override
  String get statsAboutKnowledge => '關於已儲存知識的統計';

  @override
  String get providers => '服務商';

  @override
  String providersConfigured(int count) {
    return '已設定 $count 個服務商';
  }

  @override
  String get personas => '角色';

  @override
  String get noCustomInstruction => '無自訂指令';

  @override
  String get addPersona => '新增角色';

  @override
  String get newPersona => '新建角色';

  @override
  String get editPersona => '編輯角色';

  @override
  String get deletePersona => '刪除角色？';

  @override
  String get cannotBeUndone => '此操作無法復原。';

  @override
  String get cancel => '取消';

  @override
  String get save => '儲存';

  @override
  String get delete => '刪除';

  @override
  String get create => '建立';

  @override
  String get pickAnIcon => '選擇圖示';

  @override
  String get name => '名稱';

  @override
  String get systemInstruction => '系統指令';

  @override
  String get customInstructionsHint => '附加到每則訊息的自訂指令……';

  @override
  String get leaveEmptyForGeneral => '留空則作為通用助手。';

  @override
  String get theme => '主題';

  @override
  String get explainPromptTemplate => '釋義提示詞範本';

  @override
  String explainPromptHint(String word) {
    return '使用 $word 作為查詢詞的佔位符。';
  }

  @override
  String get apiUsage => 'API 用量';

  @override
  String get apiCalls => 'API 呼叫';

  @override
  String get inputTokens => '輸入 Token';

  @override
  String get outputTokens => '輸出 Token';

  @override
  String get addProvider => '新增服務商';

  @override
  String get deleteProvider => '刪除服務商？';

  @override
  String removeProviderMessage(String name) {
    return '從此裝置移除「$name」。';
  }

  @override
  String get setAsDefault => '設為預設';

  @override
  String get connectionTimedOut => '連線逾時，請檢查 Base URL 後重試。';

  @override
  String validationFailed(String error) {
    return '驗證失敗：$error';
  }

  @override
  String get validating => '驗證中……';

  @override
  String get kind => '類型';

  @override
  String get selectModel => '選擇模型';

  @override
  String get refreshModels => '重新整理模型列表';

  @override
  String get welcomeToCairn => '歡迎使用 Cairn';

  @override
  String get typeMessageBelow => '在下方輸入訊息';

  @override
  String get untitled => '無標題';

  @override
  String get messageHint => '輸入訊息……';

  @override
  String get savedToLibrary => '已儲存到資料庫';

  @override
  String get view => '檢視';

  @override
  String get searchConversations => '搜尋對話……';

  @override
  String get recent => '最近';

  @override
  String get noConversationsYet => '暫無對話';

  @override
  String get newChat => '新對話';

  @override
  String get saveToLibrary => '儲存到知識庫';

  @override
  String get regenerate => '重新產生';

  @override
  String get copy => '複製';

  @override
  String get editAndResend => '編輯並重發';

  @override
  String get editMessage => '編輯訊息';

  @override
  String get editWillRerun => '編輯後將從此輪重新產生回覆。';

  @override
  String get saveAndResend => '儲存並重發';

  @override
  String get noConnectionsYet => '暫無關聯';

  @override
  String get saveMoreForConnections => '儲存更多條目以發現知識關聯。';

  @override
  String get refresh => '重新整理';

  @override
  String remaining(int count) {
    return '剩餘 $count 項';
  }

  @override
  String get allCaughtUpTitle => '全部完成！';

  @override
  String get noItemsDueForReview => '目前沒有需要複習的條目。';

  @override
  String get enableReviewForAll => '為所有條目開啟複習';

  @override
  String get viewFullItem => '檢視完整條目';

  @override
  String get relatedKnowledge => '相關知識';

  @override
  String get knowledgeHubs => '知識樞紐';

  @override
  String get topTags => '熱門標籤';

  @override
  String get isolatedKnowledge => '孤立知識';

  @override
  String similarityPercent(int percent) {
    return '$percent% 相關';
  }

  @override
  String get tapToReveal => '點擊揭示';

  @override
  String get skip => '下一個';

  @override
  String get gotIt => '記住了';

  @override
  String get forgot => '忘了';

  @override
  String get hard => '模糊';

  @override
  String get good => '記得';

  @override
  String get easy => '輕鬆';

  @override
  String get stopReview => '不再複習';

  @override
  String get graduated => '已掌握';

  @override
  String intervalDays(int days) {
    return '$days天';
  }

  @override
  String selectedCount(int count) {
    return '已選 $count 項';
  }

  @override
  String get deselectAll => '取消全選';

  @override
  String get selectAll => '全選';

  @override
  String get saveFromUrl => '從 URL 儲存';

  @override
  String get importMarkdown => '匯入 Markdown';

  @override
  String get exportAsMarkdown => '匯出為 Markdown';

  @override
  String get exportAsJson => '匯出為 JSON';

  @override
  String get batchDelete => '批次刪除';

  @override
  String get quickNote => '快速筆記';

  @override
  String get searchHint => '搜尋標題、正文、筆記……';

  @override
  String get all => '全部';

  @override
  String get vocab => '詞彙';

  @override
  String get insight => '見解';

  @override
  String get action => '行動';

  @override
  String get fact => '事實';

  @override
  String get question => '問題';

  @override
  String get noItemsToExport => '沒有可匯出的條目';

  @override
  String importedCount(int count) {
    return '已匯入 $count 個條目';
  }

  @override
  String deleteCountItems(int count) {
    return '刪除 $count 個條目？';
  }

  @override
  String get fetch => '取得';

  @override
  String get fetchingPage => '正在取得頁面……';

  @override
  String savedTitle(String title) {
    return '已儲存：$title';
  }

  @override
  String failedError(String error) {
    return '失敗：$error';
  }

  @override
  String get titleOptional => '標題（可選）';

  @override
  String get writeYourNote => '寫下你的筆記……';

  @override
  String deleteFolderTitle(String folder) {
    return '刪除「$folder」？';
  }

  @override
  String get deleteFolderMessage => '資料夾中的條目將移至「全部」。此操作無法復原。';

  @override
  String get analyzing => '分析中……';

  @override
  String get noMatches => '未找到符合項目';

  @override
  String get messageMatches => '訊息內容符合';

  @override
  String get geminiRecommended => '推薦：通義千問（免費額度）';

  @override
  String get geminiRecommendedDesc => '國內存取流暢，註冊即送免費 Token，同時支援對話和知識庫語意檢索。';

  @override
  String get getFreApiKey => '取得免費 API Key';

  @override
  String get nothingSavedYet => '還沒有儲存任何內容';

  @override
  String get tryDifferentKeyword => '試試其他關鍵字。';

  @override
  String get longPressToSave => '長按 AI 回覆即可儲存。';

  @override
  String get justNow => '剛剛';

  @override
  String minutesAgo(int count) {
    return '$count分鐘前';
  }

  @override
  String hoursAgo(int count) {
    return '$count小時前';
  }

  @override
  String daysAgo(int count) {
    return '$count天前';
  }

  @override
  String get deleteItem => '刪除條目？';

  @override
  String get copyAsMarkdown => '複製為 Markdown';

  @override
  String get shareAsFile => '分享為檔案';

  @override
  String get title => '標題';

  @override
  String get myNotes => '我的筆記';

  @override
  String get edit => '編輯';

  @override
  String get addNotesHint => '新增你自己的例句、記憶方法、上下文……';

  @override
  String get saveChanges => '儲存變更';

  @override
  String get aiAnalyzingTags => 'AI 正在分析標籤……';

  @override
  String get source => '來源';

  @override
  String get tapToOpenSource => '點擊開啟來源對話';

  @override
  String get copiedToClipboard => '已複製到剪貼簿';

  @override
  String get week => '週';

  @override
  String get month => '月';

  @override
  String get allTime => '全部';

  @override
  String get itemsSaved => '已儲存條目';

  @override
  String get totalTags => '標籤';

  @override
  String get totalEntities => '實體';

  @override
  String get typeDistribution => '類型分佈';

  @override
  String get byType => '按類型';

  @override
  String entitiesCount(int count) {
    return '實體（$count）';
  }

  @override
  String get offlineDictNotLoaded => '離線詞典未載入，請使用下方 AI 釋義。';

  @override
  String get wordNotFoundInDict => '離線詞典中未找到該詞，可使用下方 AI 釋義。';

  @override
  String get aiDetailedExplanation => 'AI 詳細釋義';

  @override
  String tokensCount(String count) {
    return '$count tokens';
  }

  @override
  String get aboutCairnTagline => '積石成塔，聚知成識。';

  @override
  String get aboutCairnBody =>
      'Cairn 是一個注重隱私的 AI 用戶端。它了解你是誰，幫你在每一次對話中積累屬於自己的知識庫。\n\n自由對話，隨心所欲。使用你自己的 API 金鑰，在不同服務商和模型之間自由切換。設定不同的 AI 角色——寫作教練、程式導師、語言夥伴——每個角色都知道該怎麼和你交流。\n\n留住重要的東西。長按任意 AI 回覆即可儲存。Cairn 會自動標注和分類你儲存的知識。日積月累，你的資料庫會成為一個可搜尋的第二大腦。\n\n永遠不忘。內建間隔重複演算法，在你即將遺忘時主動提醒複習。知識如果會褪色就沒有意義——Cairn 確保它留下來。\n\n發現更大的圖景。知識圖譜會自動發現你儲存內容之間隱藏的關聯——串聯起那些你自己都沒意識到相關的概念。\n\n順便學好英語。對話中點擊任意單詞，即刻查詞並獲取 AI 詳細釋義。它不是一個獨立的學習應用——而是融入你日常使用 AI 的方式之中。\n\n資料只屬於你。無需註冊，不同步雲端，不追蹤隱私。API 金鑰儲存在裝置安全鑰匙圈中。一切都在你的手機上。';

  @override
  String get madeWithLove => '積石成塔，聚知成識，為己所用。';

  @override
  String get aboutAndFeedback => '關於與回饋';

  @override
  String get sendFeedback => '傳送回饋';

  @override
  String get reportIssue => '回報問題';

  @override
  String get rateApp => '為應用程式評分';

  @override
  String get openSourceLicenses => '開放原始碼授權';

  @override
  String get privacyPolicy => '隱私權政策';

  @override
  String get termsOfService => '使用條款';

  @override
  String version(String version) {
    return '版本 $version';
  }

  @override
  String get tools => '工具';

  @override
  String get functionCalling => 'Function Calling';

  @override
  String get functionCallingSubtitle => '允許 AI 獲取即時資訊';

  @override
  String get aiPersonalization => 'AI 個人化';

  @override
  String get aiPersonalizationSubtitle => '關於我與角色設定';

  @override
  String get language => '語言';

  @override
  String get systemDefault => '跟隨系統';

  @override
  String get lookup => '查詞';

  @override
  String get askFollowUp => '繼續追問……';

  @override
  String get customModel => '自訂模型';

  @override
  String get newConversation => '新對話';

  @override
  String exportFailed(String error) {
    return '匯出失敗：$error';
  }

  @override
  String importFailed(String error) {
    return '匯入失敗：$error';
  }

  @override
  String get feeds => '資訊源';

  @override
  String get signals => '信號';

  @override
  String get dailyBrief => '每日簡報';

  @override
  String get addFeed => '新增資訊源';

  @override
  String get enterFeedUrl => '輸入 RSS 或網站網址';

  @override
  String get fetchingFeed => '正在取得…';

  @override
  String get feedAdded => '已新增';

  @override
  String get noFeeds => '尚無資訊源';

  @override
  String get addFeedsHint => '新增 RSS 資訊源，開始接收信號';

  @override
  String get noSignals => '尚無信號';

  @override
  String get noSignalsHint => '重要信號會出現在這裡';

  @override
  String get noBriefItems => '今日簡報為空';

  @override
  String get noBriefHint => '擷取資訊源後，新文章會出現在這裡';

  @override
  String get readOriginal => '閱讀原文';

  @override
  String get dismiss => '忽略';

  @override
  String get act => '行動';

  @override
  String get readAction => '細讀';

  @override
  String get skimAction => '略讀';

  @override
  String signalCount(int count) {
    return '$count 條信號';
  }

  @override
  String get refreshing => '正在重新整理…';

  @override
  String get strategiesLabel => '策略';

  @override
  String get addStrategy => '新增策略';

  @override
  String get strategyName => '策略名稱';

  @override
  String get strategyDescription => '描述要監控什麼';

  @override
  String feedAddFailed(String error) {
    return '新增失敗：$error';
  }
}
