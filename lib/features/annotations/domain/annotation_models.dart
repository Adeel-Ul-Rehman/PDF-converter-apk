import 'dart:typed_data';
import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show Colors, FontStyle, FontWeight, TextAlign;

/// One freehand stroke (doodle). Points are in local widget coordinates.
class DoodleStroke extends Equatable {
  const DoodleStroke({
    required this.points,
    required this.color,
    required this.width,
    this.isEraser = false,
    this.pageIndex = 0,
  });

  final List<Offset> points;
  final Color color;
  final double width;
  final bool isEraser;
  final int pageIndex;

  DoodleStroke copyWith({
    List<Offset>? points,
    Color? color,
    double? width,
    bool? isEraser,
    int? pageIndex,
  }) => DoodleStroke(
    points: points ?? this.points,
    color: color ?? this.color,
    width: width ?? this.width,
    isEraser: isEraser ?? this.isEraser,
    pageIndex: pageIndex ?? this.pageIndex,
  );

  @override
  List<Object?> get props => [points, color, width, isEraser, pageIndex];
}

/// Signature element for the editor canvas
class SignatureElement extends Equatable {
  const SignatureElement({
    required this.id,
    required this.strokes,
    required this.color,
    required this.offset,
    required this.scale,
    required this.rotation,
    required this.pageIndex,
    this.isTyped = false,
    this.text = '',
    this.fontFamily = '',
    this.fontSize = 36.0,
  });

  final String id;
  final List<DoodleStroke> strokes;
  final Color color;
  final Offset offset;
  final double scale;
  final double rotation;
  final int pageIndex;
  final bool isTyped;
  final String text;
  final String fontFamily;
  final double fontSize;

  SignatureElement copyWith({
    String? id,
    List<DoodleStroke>? strokes,
    Color? color,
    Offset? offset,
    double? scale,
    double? rotation,
    int? pageIndex,
    bool? isTyped,
    String? text,
    String? fontFamily,
    double? fontSize,
  }) => SignatureElement(
    id: id ?? this.id,
    strokes: strokes ?? this.strokes,
    color: color ?? this.color,
    offset: offset ?? this.offset,
    scale: scale ?? this.scale,
    rotation: rotation ?? this.rotation,
    pageIndex: pageIndex ?? this.pageIndex,
    isTyped: isTyped ?? this.isTyped,
    text: text ?? this.text,
    fontFamily: fontFamily ?? this.fontFamily,
    fontSize: fontSize ?? this.fontSize,
  );

  @override
  List<Object?> get props => [
    id,
    strokes,
    color,
    offset,
    scale,
    rotation,
    pageIndex,
    isTyped,
    text,
    fontFamily,
    fontSize,
  ];
}

/// Saved signature item in user's signature library
class SavedSignature extends Equatable {
  const SavedSignature({
    required this.id,
    required this.name,
    required this.strokes,
    this.previewData,
    this.createdDate,
  });

  final String id;
  final String name;
  final List<DoodleStroke> strokes;
  final Uint8List? previewData;
  final DateTime? createdDate;

  SavedSignature copyWith({
    String? id,
    String? name,
    List<DoodleStroke>? strokes,
    Uint8List? previewData,
    DateTime? createdDate,
  }) => SavedSignature(
    id: id ?? this.id,
    name: name ?? this.name,
    strokes: strokes ?? this.strokes,
    previewData: previewData ?? this.previewData,
    createdDate: createdDate ?? this.createdDate,
  );

  @override
  List<Object?> get props => [id, name, strokes, previewData, createdDate];
}

/// Signature annotation for PDF export
class SignatureAnnotation extends Equatable {
  const SignatureAnnotation({
    required this.id,
    required this.strokes,
    required this.offset,
    required this.scale,
    required this.rotation,
    required this.color,
    this.isTyped = false,
    this.text = '',
    this.fontFamily = '',
    this.fontSize = 36.0,
    this.pageIndex = 0,
  });

  final String id;
  final List<DoodleStroke> strokes;
  final Offset offset;
  final double scale;
  final double rotation;
  final Color color;
  final bool isTyped;
  final String text;
  final String fontFamily;
  final double fontSize;
  final int pageIndex;

  SignatureAnnotation copyWith({
    String? id,
    List<DoodleStroke>? strokes,
    Offset? offset,
    double? scale,
    double? rotation,
    Color? color,
    bool? isTyped,
    String? text,
    String? fontFamily,
    double? fontSize,
    int? pageIndex,
  }) => SignatureAnnotation(
    id: id ?? this.id,
    strokes: strokes ?? this.strokes,
    offset: offset ?? this.offset,
    scale: scale ?? this.scale,
    rotation: rotation ?? this.rotation,
    color: color ?? this.color,
    isTyped: isTyped ?? this.isTyped,
    text: text ?? this.text,
    fontFamily: fontFamily ?? this.fontFamily,
    fontSize: fontSize ?? this.fontSize,
    pageIndex: pageIndex ?? this.pageIndex,
  );

  @override
  List<Object?> get props => [
    id,
    strokes,
    offset,
    scale,
    rotation,
    color,
    isTyped,
    text,
    fontFamily,
    fontSize,
    pageIndex,
  ];
}

/// A text annotation element with full styling support
class TextAnnotationElement extends Equatable {
  const TextAnnotationElement({
    required this.id,
    required this.text,
    required this.offset,
    required this.color,
    required this.fontSize,
    required this.fontFamily,
    required this.fontWeight,
    required this.fontStyle,
    required this.alignment,
    this.rotation = 0.0,
    this.backgroundColor = Colors.transparent,
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
    this.pageIndex = 0,
  });

  final String id;
  final String text;
  final Offset offset;
  final Color color;
  final Color backgroundColor;
  final double fontSize;
  final String fontFamily;
  final FontWeight fontWeight;
  final FontStyle fontStyle;
  final TextAlign alignment;
  final double rotation;
  final bool isBold;
  final bool isItalic;
  final bool isUnderline;
  final int pageIndex;

  TextAnnotationElement copyWith({
    String? text,
    Offset? offset,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    String? fontFamily,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    TextAlign? alignment,
    double? rotation,
    bool? isBold,
    bool? isItalic,
    bool? isUnderline,
    int? pageIndex,
  }) => TextAnnotationElement(
    id: id,
    text: text ?? this.text,
    offset: offset ?? this.offset,
    color: color ?? this.color,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    fontSize: fontSize ?? this.fontSize,
    fontFamily: fontFamily ?? this.fontFamily,
    fontWeight: fontWeight ?? this.fontWeight,
    fontStyle: fontStyle ?? this.fontStyle,
    alignment: alignment ?? this.alignment,
    rotation: rotation ?? this.rotation,
    isBold: isBold ?? this.isBold,
    isItalic: isItalic ?? this.isItalic,
    isUnderline: isUnderline ?? this.isUnderline,
    pageIndex: pageIndex ?? this.pageIndex,
  );

  @override
  List<Object?> get props => [
    id,
    text,
    offset,
    color,
    backgroundColor,
    fontSize,
    fontFamily,
    fontWeight,
    fontStyle,
    alignment,
    rotation,
    isBold,
    isItalic,
    isUnderline,
    pageIndex,
  ];
}

/// A text annotation for PDF export
class TextAnnotation extends Equatable {
  const TextAnnotation({
    required this.id,
    required this.text,
    required this.offset,
    required this.color,
    required this.fontSize,
    required this.fontFamily,
    required this.fontWeight,
    required this.fontStyle,
    required this.alignment,
    this.rotation = 0.0,
    this.backgroundColor = Colors.transparent,
    this.isUnderline = false,
    this.pageIndex = 0,
  });

  final String id;
  final String text;
  final Offset offset;
  final Color color;
  final Color backgroundColor;
  final double fontSize;
  final String fontFamily;
  final String fontWeight;
  final String fontStyle;
  final TextAlign alignment;
  final double rotation;
  final bool isUnderline;
  final int pageIndex;

  TextAnnotation copyWith({
    String? text,
    Offset? offset,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    String? fontFamily,
    String? fontWeight,
    String? fontStyle,
    TextAlign? alignment,
    double? rotation,
    bool? isUnderline,
    int? pageIndex,
  }) => TextAnnotation(
    id: id,
    text: text ?? this.text,
    offset: offset ?? this.offset,
    color: color ?? this.color,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    fontSize: fontSize ?? this.fontSize,
    fontFamily: fontFamily ?? this.fontFamily,
    fontWeight: fontWeight ?? this.fontWeight,
    fontStyle: fontStyle ?? this.fontStyle,
    alignment: alignment ?? this.alignment,
    rotation: rotation ?? this.rotation,
    isUnderline: isUnderline ?? this.isUnderline,
    pageIndex: pageIndex ?? this.pageIndex,
  );

  @override
  List<Object?> get props => [
    id,
    text,
    offset,
    color,
    backgroundColor,
    fontSize,
    fontFamily,
    fontWeight,
    fontStyle,
    alignment,
    rotation,
    isUnderline,
    pageIndex,
  ];
}

/// A single page's full set of annotations with dynamic dimensions.
class PageAnnotations extends Equatable {
  const PageAnnotations({
    this.doodles = const [],
    this.texts = const [],
    this.signatures = const [],
    this.width = 0,
    this.height = 0,
    this.pageIndex = 0,
  });

  final List<DoodleStroke> doodles;
  final List<TextAnnotation> texts;
  final List<SignatureAnnotation> signatures;
  final double width;
  final double height;
  final int pageIndex;

  PageAnnotations copyWith({
    List<DoodleStroke>? doodles,
    List<TextAnnotation>? texts,
    List<SignatureAnnotation>? signatures,
    double? width,
    double? height,
    int? pageIndex,
  }) => PageAnnotations(
    doodles: doodles ?? this.doodles,
    texts: texts ?? this.texts,
    signatures: signatures ?? this.signatures,
    width: width ?? this.width,
    height: height ?? this.height,
    pageIndex: pageIndex ?? this.pageIndex,
  );

  @override
  List<Object?> get props => [
    doodles,
    texts,
    signatures,
    width,
    height,
    pageIndex,
  ];
}
