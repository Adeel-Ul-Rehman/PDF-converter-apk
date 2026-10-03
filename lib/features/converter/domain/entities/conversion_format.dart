/// Supported file categories and formats for conversion.
enum ConversionFormat {
  // Documents
  pdf(displayName: 'PDF', mimeType: 'application/pdf', category: 'Document'),
  docx(displayName: 'DOCX', mimeType: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', category: 'Document'),
  txt(displayName: 'TXT', mimeType: 'text/plain', category: 'Document'),
  epub(displayName: 'EPUB', mimeType: 'application/epub+zip', category: 'Document'),
  xlsx(displayName: 'XLSX', mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', category: 'Document'),
  xls(displayName: 'XLS', mimeType: 'application/vnd.ms-excel', category: 'Document'),
  pptx(displayName: 'PPTX', mimeType: 'application/vnd.openxmlformats-officedocument.presentationml.presentation', category: 'Document'),
  ppt(displayName: 'PPT', mimeType: 'application/vnd.ms-powerpoint', category: 'Document'),
  html(displayName: 'HTML', mimeType: 'text/html', category: 'Document'),

  // Images
  png(displayName: 'PNG', mimeType: 'image/png', category: 'Image'),
  jpg(displayName: 'JPG', mimeType: 'image/jpeg', category: 'Image'),
  webp(displayName: 'WEBP', mimeType: 'image/webp', category: 'Image'),

  // Audio
  mp3(displayName: 'MP3', mimeType: 'audio/mpeg', category: 'Audio'),
  wav(displayName: 'WAV', mimeType: 'audio/wav', category: 'Audio'),
  m4a(displayName: 'M4A', mimeType: 'audio/x-m4a', category: 'Audio'),

  // Video
  mp4(displayName: 'MP4', mimeType: 'video/mp4', category: 'Video'),
  mkv(displayName: 'MKV', mimeType: 'video/x-matroska', category: 'Video');

  const ConversionFormat({
    required this.displayName,
    required this.mimeType,
    required this.category,
  });

  final String displayName;
  final String mimeType;
  final String category;
}
