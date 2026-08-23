import 'package:flutter_test/flutter_test.dart';
import 'package:freeplix/core/widgets/wordmark.dart';

import '../../helpers/helpers.dart';

void main() {
  group('Wordmark', () {
    testWidgets('renders the Freeplix mark', (tester) async {
      await tester.pumpApp(const Wordmark());
      expect(find.byType(Wordmark), findsOneWidget);
    });
  });
}
