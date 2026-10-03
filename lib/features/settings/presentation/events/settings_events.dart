/// Events emitted by the settings screen.
sealed class SettingsEvent {
  const SettingsEvent();
}

class SettingsLoaded extends SettingsEvent {
  const SettingsLoaded();
}

class SettingsSaved extends SettingsEvent {
  const SettingsSaved();
}

class SettingsReset extends SettingsEvent {
  const SettingsReset();
}

class SettingsError extends SettingsEvent {
  const SettingsError(this.message);

  final String message;
}
