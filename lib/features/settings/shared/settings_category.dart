/// Categories used to group settings sections and filter search results.
enum SettingsCategory {
  general,
  conversion,
  storage,
  history,
  notifications,
  appearance,
  accessibility,
  privacy,
  developer,
  about;

  String get label {
    switch (this) {
      case general:
        return 'General';
      case conversion:
        return 'Conversion';
      case storage:
        return 'Storage';
      case history:
        return 'History';
      case notifications:
        return 'Notifications';
      case appearance:
        return 'Appearance';
      case accessibility:
        return 'Accessibility';
      case privacy:
        return 'Privacy';
      case developer:
        return 'Developer';
      case about:
        return 'About';
    }
  }
}
