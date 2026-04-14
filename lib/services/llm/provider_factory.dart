import '../db/database.dart';
import '../secure_key_store.dart';
import '../settings_provider.dart';
import 'anthropic_provider.dart';
import 'llm_provider.dart';
import 'openai_provider.dart';

/// Builds a [LlmProvider] instance from a saved [ProviderConfig] by
/// fetching the API key out of the OS keychain.
Future<LlmProvider> buildProvider(ProviderConfig config) async {
  final apiKey = await SecureKeyStore.instance.readApiKey(config.id);
  if (apiKey == null || apiKey.isEmpty) {
    throw LlmException(
      'API key for "${config.displayName}" is missing from the keychain.',
    );
  }
  switch (config.kind) {
    case ProviderKinds.anthropic:
      return AnthropicProvider(baseUrl: config.baseUrl, apiKey: apiKey);
    default:
      // All other providers use the OpenAI-compatible protocol.
      return OpenAiProvider(baseUrl: config.baseUrl, apiKey: apiKey);
  }
}
