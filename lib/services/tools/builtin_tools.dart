import '../db/database.dart';
import '../settings_provider.dart';
import 'device/add_calendar_event_tool.dart';
import 'device/call_taxi_tool.dart';
import 'device/find_nearby_tool.dart';
import 'device/location_tool.dart';
import 'device/open_maps_tool.dart';
import 'device/set_reminder_tool.dart';
import 'library/get_by_tag_tool.dart';
import 'library/get_note_detail_tool.dart';
import 'library/get_recent_tool.dart';
import 'library/get_stats_tool.dart';
import 'library/get_tag_distribution_tool.dart';
import 'library/get_tag_trend_tool.dart';
import 'library/sample_random_tool.dart';
import 'tool_registry.dart';
import 'web/app_search_tool.dart';
import 'web/brave_backend_tool.dart';
import 'web/crypto_price_tool.dart';
import 'web/tavily_backend_tool.dart';
import 'web/weather_tool.dart';
import 'web/web_search_tool.dart';

/// Create a [ToolRegistry] populated with all built-in tools.
///
/// Pass [libraryDb] so the library-aware tools can read the user's
/// saved notes. When null (e.g. the settings UI rendering tool toggles)
/// library tools still register their metadata but return an error if
/// invoked.
///
/// Pass [settings] so the `web_search` dispatcher can read backend
/// toggles + the Tavily/Brave key-tail indicators. When null, the
/// dispatcher silently falls back to DDG — fine for the UI-only
/// registry built by the settings page.
ToolRegistry createBuiltinRegistry({
  AppDatabase? libraryDb,
  SettingsProvider? settings,
}) {
  final registry = ToolRegistry();
  registry.register(LocationTool());
  registry.register(OpenMapsTool());
  registry.register(FindNearbyTool());
  registry.register(CallTaxiTool());
  registry.register(AppSearchTool());
  registry.register(SetReminderTool());
  registry.register(AddCalendarEventTool());
  registry.register(CryptoPriceTool());
  registry.register(WeatherTool());
  registry.register(WebSearchTool(settings: settings));
  registry.register(TavilyBackendTool());
  registry.register(BraveBackendTool());
  registry.register(GetStatsTool(libraryDb));
  registry.register(GetTagDistributionTool(libraryDb));
  registry.register(GetTagTrendTool(libraryDb));
  registry.register(GetRecentTool(libraryDb));
  registry.register(GetByTagTool(libraryDb));
  registry.register(SampleRandomTool(libraryDb));
  registry.register(GetNoteDetailTool(libraryDb));
  return registry;
}
