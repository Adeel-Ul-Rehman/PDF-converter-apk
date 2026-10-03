import 'package:equatable/equatable.dart';

import 'package:flux_convert/features/settings/domain/entities/settings_entity.dart';

/// UI state for the settings screen.
class SettingsState extends Equatable {
  const SettingsState({
    this.isLoading = false,
    this.searchQuery = '',
    this.settings = SettingsEntityDefaults.instance,
    this.errorMessage,
  });

  final bool isLoading;
  final String searchQuery;
  final SettingsEntity settings;
  final String? errorMessage;

  SettingsState copyWith({
    bool? isLoading,
    String? searchQuery,
    SettingsEntity? settings,
    String? errorMessage,
  }) => SettingsState(
    isLoading: isLoading ?? this.isLoading,
    searchQuery: searchQuery ?? this.searchQuery,
    settings: settings ?? this.settings,
    errorMessage: errorMessage ?? this.errorMessage,
  );

  @override
  List<Object?> get props => [isLoading, searchQuery, settings, errorMessage];
}
