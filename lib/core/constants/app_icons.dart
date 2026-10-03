import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// AppIcons — Centralized Icon Catalog
///
/// Ensures all screens use consistent icon assets. Never use raw Icons.xyz in
/// screens — reference a property here.
/// ─────────────────────────────────────────────────────────────────────────────
abstract final class AppIcons {
  static const IconData back = Icons.arrow_back_ios_new_rounded;
  static const IconData settings = Icons.settings_rounded;
  static const IconData convert = Icons.transform_rounded;
  static const IconData history = Icons.history_rounded;
  static const IconData storage = Icons.folder_rounded;
  static const IconData upload = Icons.cloud_upload_outlined;
  
  // File types
  static const IconData document = Icons.description_rounded;
  static const IconData image = Icons.image_rounded;
  static const IconData audio = Icons.audiotrack_rounded;
  static const IconData video = Icons.videocam_rounded;
  static const IconData unknownFile = Icons.insert_drive_file_rounded;

  // States & Alerts
  static const IconData success = Icons.check_circle_rounded;
  static const IconData warning = Icons.warning_amber_rounded;
  static const IconData error = Icons.error_outline_rounded;
  static const IconData info = Icons.info_outline_rounded;

  // Actions
  static const IconData close = Icons.close_rounded;
  static const IconData check = Icons.check_rounded;
  static const IconData delete = Icons.delete_outline_rounded;
  static const IconData retry = Icons.refresh_rounded;
  static const IconData search = Icons.search_rounded;
  static const IconData share = Icons.share_rounded;
  static const IconData copy = Icons.copy_rounded;
  static const IconData dropdown = Icons.keyboard_arrow_down_rounded;
}
