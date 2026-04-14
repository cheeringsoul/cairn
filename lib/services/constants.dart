// lib/services/constants.dart

// ==== State enums ====

class EmbeddingCapability {
  EmbeddingCapability._();
  static const unknown = 'unknown';
  static const yes = 'yes';
  static const no = 'no';
  static const rateLimited = 'rate_limited';
}

class EmbeddingStatus {
  EmbeddingStatus._();
  static const pending = 'pending';
  static const processing = 'processing';
  static const ready = 'ready';
  static const failed = 'failed';
}

class MetaStatus {
  MetaStatus._();
  static const pending = 'pending';
  static const done = 'done';
  static const failed = 'failed';
}

class MessageRole {
  MessageRole._();
  static const user = 'user';
  static const assistant = 'assistant';
  static const system = 'system';
}

class ConversationKind {
  ConversationKind._();
  static const chat = 'chat';
  static const explain = 'explain';
}

class UsageKind {
  UsageKind._();
  static const chat = 'chat';
  static const explain = 'explain';
  static const analyze = 'analyze';
  static const embedding = 'embedding';
}

// ==== Numeric limits ====

class TitleLimits {
  TitleLimits._();
  static const fallback = 30;
  static const urlTruncation = 80;
}

class EmbeddingLimits {
  EmbeddingLimits._();
  static const inputMaxChars = 8000;
  static const recallTopK = 5;
}

class EmbeddingTiming {
  EmbeddingTiming._();
  static const probeTimeout = Duration(seconds: 15);
  static const embedTimeout = Duration(seconds: 30);
  static const probeInterval = Duration(minutes: 10);
  static const bootstrapFirstOffset = Duration(seconds: 3);
  static const bootstrapOffsetStep = Duration(seconds: 60);
  static const bootstrapMaxOffset = Duration(seconds: 570);
  static const unreachableLatency = Duration(days: 365);
  static const rollingSampleCount = 5;
}

class FanoutLimits {
  FanoutLimits._();
  static const tickInterval = Duration(seconds: 5);
  static const batchSize = 10;
  static const backfillConcurrency = 5;
}

class ChatLimits {
  ChatLimits._();
  static const messagePageSize = 50;
  static const loadMoreTriggerPixels = 200.0;
}

/// Context-window guardrails applied when NO provider in the user's
/// settings has embedding capability. In that state there is no
/// cross-conversation recall fallback and the full user-question
/// transcript is otherwise sent verbatim each turn, so we compress
/// older turns and nudge the user toward a fresh conversation before
/// they hit the provider's hard window limit.
///
/// Char counts — rough token proxy (conservative for CJK, loose for
/// latin). Tuned for the ~200k Anthropic window minus tools + system.
class NoEmbedContext {
  NoEmbedContext._();
  static const warnChars = 32000;
  static const compressChars = 40000;
  static const keepRecentTurns = 10;
}
