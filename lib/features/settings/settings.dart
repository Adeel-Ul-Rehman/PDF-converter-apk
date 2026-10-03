/// Settings Feature Module Barrel.
///
/// Exposes the public Surface of the settings feature module.
/// Internal implementation files (data layer, widgets, private classes)
/// are intentionally not exported.
library;

// ── Domain ─────────────────────────────────────────────────────────────────
export 'domain/entities/settings_entity.dart';
export 'domain/failures/settings_failure.dart';
export 'domain/repositories/settings_repository.dart';
export 'domain/usecases/clear_preferences_usecase.dart';
export 'domain/usecases/get_settings_usecase.dart';
export 'domain/usecases/reset_settings_usecase.dart';
export 'domain/usecases/save_settings_usecase.dart';
export 'domain/usecases/update_setting_usecase.dart';

// ── Presentation ───────────────────────────────────────────────────────────
export 'presentation/controllers/settings_controller.dart';
export 'presentation/events/settings_events.dart';
export 'presentation/pages/about_page.dart';
export 'presentation/pages/developer_page.dart';
export 'presentation/pages/settings_page.dart';
export 'presentation/providers/settings_providers.dart';
export 'presentation/state/settings_state.dart';

// ── Shared ─────────────────────────────────────────────────────────────────
export 'shared/settings_category.dart';
