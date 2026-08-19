import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/localization/export.dart';

/// Picks an image from disk and normalizes it into the form an app icon
/// is stored in: a square-ish PNG no larger than [iconMaxSize] px,
/// base64-encoded so it travels with the app record.
abstract class AppIconDataSource {
  /// Returns the encoded icon, or null when the user cancels.
  Future<String?> pickIcon();
}

/// Longest edge an icon is kept at. Icons are drawn at 64px at most, so
/// this leaves room for high-density displays without letting a 4000px
/// screenshot into local storage.
const int iconMaxSize = 256;

/// Refuse anything that would bloat the stored app list; a photo picked
/// by mistake trips this rather than silently costing megabytes.
const int _maxSourceBytes = 8 * 1024 * 1024;

class AppIconDataSourceImpl implements AppIconDataSource {
  const AppIconDataSourceImpl();

  @override
  Future<String?> pickIcon() async {
    final FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Select an app icon',
        type: FileType.custom,
        allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp', 'bmp', 'gif'],
        withData: true,
      );
    } on Exception catch (e) {
      throw FileException(
        LocaleKeys.errorsImagePickerOpen.tr(namedArgs: {'error': '$e'}),
      );
    }

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final bytes = result.files.first.bytes;
    if (bytes == null || bytes.isEmpty) {
      throw FileException(LocaleKeys.errorsImageUnreadable.tr());
    }
    if (bytes.length > _maxSourceBytes) {
      throw FileException(LocaleKeys.errorsImageTooLarge.tr());
    }

    return encodeIconBytes(bytes);
  }
}

/// Decodes [bytes], scales the image down so its longest edge is at most
/// [iconMaxSize], and returns it as base64 PNG.
///
/// Re-encoding is what makes any picked format storable and bounded: the
/// stored string is always a PNG of known size, whatever came in.
Future<String> encodeIconBytes(Uint8List bytes) async {
  final ui.Codec codec;
  try {
    codec = await ui.instantiateImageCodec(bytes);
  } on Exception catch (e) {
    throw FileException(
      LocaleKeys.errorsNotAnImage.tr(namedArgs: {'error': '$e'}),
    );
  }

  final ui.Image source;
  try {
    source = (await codec.getNextFrame()).image;
  } finally {
    codec.dispose();
  }

  final longestEdge = source.width > source.height
      ? source.width
      : source.height;

  ui.Image image = source;
  if (longestEdge > iconMaxSize) {
    final scale = iconMaxSize / longestEdge;
    final targetWidth = (source.width * scale).round().clamp(1, iconMaxSize);
    final scaled = await ui.instantiateImageCodec(
      bytes,
      targetWidth: targetWidth,
    );
    try {
      image = (await scaled.getNextFrame()).image;
    } finally {
      scaled.dispose();
    }
    source.dispose();
  }

  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  if (data == null) {
    throw FileException(LocaleKeys.errorsImageConvert.tr());
  }

  return base64Encode(data.buffer.asUint8List());
}
