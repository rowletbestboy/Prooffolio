import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:app_name/features/profile/presentation/profile_background_screen.dart';

void main() {
  const pngSignature = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];

  test('validates PNG signature and the five megabyte limit', () {
    final validPhoto = PickedProfilePhoto(
      fileName: 'portrait.png',
      mimeType: 'image/png',
      bytes: Uint8List.fromList(pngSignature),
    );
    final oversizedPhoto = PickedProfilePhoto(
      fileName: 'portrait.png',
      mimeType: 'image/png',
      bytes: Uint8List.fromList([
        ...pngSignature,
        ...List<int>.filled(5_000_000, 0),
      ]),
    );

    expect(ProfilePhotoPolicy.validate(validPhoto), isNull);
    expect(ProfilePhotoPolicy.validate(oversizedPhoto), isNotNull);
  });

  test('accepts matching JPEG and WEBP signatures', () {
    final jpeg = PickedProfilePhoto(
      fileName: 'portrait.jpg',
      mimeType: 'image/jpeg',
      bytes: Uint8List.fromList([0xff, 0xd8, 0xff]),
    );
    final webp = PickedProfilePhoto(
      fileName: 'portrait.webp',
      mimeType: 'image/webp',
      bytes: Uint8List.fromList([
        0x52,
        0x49,
        0x46,
        0x46,
        0,
        0,
        0,
        0,
        0x57,
        0x45,
        0x42,
        0x50,
      ]),
    );

    expect(ProfilePhotoPolicy.validate(jpeg), isNull);
    expect(ProfilePhotoPolicy.validate(webp), isNull);
  });

  test('rejects an image whose bytes do not match its declared MIME type', () {
    final mislabeledPhoto = PickedProfilePhoto(
      fileName: 'portrait.jpg',
      mimeType: 'image/jpeg',
      bytes: Uint8List.fromList(pngSignature),
    );

    expect(ProfilePhotoPolicy.validate(mislabeledPhoto), isNotNull);
  });

  test('infers a missing MIME type from the selected image filename', () {
    expect(
      ProfilePhotoPolicy.normaliseMimeType(null, 'portrait.webp'),
      'image/webp',
    );
  });
}
