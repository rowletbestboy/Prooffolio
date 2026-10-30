import 'package:app_name/features/dashboard/presentation/home_profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the supplied profile photo URL', (tester) async {
    const photoUrl = 'https://example.test/alex.png';
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HomeProfileAvatar(
            displayName: 'Alex Rivera',
            photoUrl: photoUrl,
            onTap: null,
          ),
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<NetworkImage>());
    expect((image.image as NetworkImage).url, photoUrl);
  });

  testWidgets('shows initials when there is no profile photo', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HomeProfileAvatar(
            displayName: 'Alex Rivera',
            photoUrl: null,
            onTap: null,
          ),
        ),
      ),
    );

    expect(find.text('AR'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('shows initials when the profile photo cannot load', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HomeProfileAvatar(
            displayName: 'Alex Rivera',
            photoUrl: 'unsupported://photo',
            onTap: null,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('AR'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('exposes an accessible action to open the profile', (
    tester,
  ) async {
    var opened = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeProfileAvatar(
            displayName: 'Alex Rivera',
            photoUrl: null,
            onTap: () => opened = true,
          ),
        ),
      ),
    );

    expect(find.byTooltip('Profile and background'), findsOneWidget);
    await tester.tap(find.byTooltip('Profile and background'));
    expect(opened, isTrue);
  });

  testWidgets('does not overflow with a long display name', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HomeProfileAvatar(
            displayName:
                'Avery With A Name That Is Much Longer Than The Header',
            photoUrl: null,
            onTap: null,
          ),
        ),
      ),
    );

    expect(find.text('AW'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
