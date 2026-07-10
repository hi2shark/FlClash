import 'package:test/test.dart';

import '../setup.dart' as setup;

void main() {
  group('setup.dart', () {
    test('parses -v as verbose mode', () {
      final results = setup.createSetupArgParser().parse(['android', '-v']);

      expect(results['verbose'], isTrue);
      expect(results.rest, ['android']);
    });

    test('parses --repository option', () {
      final results = setup.createSetupArgParser().parse([
        'android',
        '--repository',
        'owner/repo',
      ]);

      expect(results['repository'], 'owner/repo');
    });

    test('omits verbose from flutter build args by default', () {
      final args = setup.createFlutterBuildArgs(
        platform: 'android',
        verbose: false,
      );

      expect(args, ['dart-define-from-file=env.json', 'split-per-abi']);
    });

    test('adds verbose to flutter build args with -v', () {
      final args = setup.createFlutterBuildArgs(
        platform: 'android',
        verbose: true,
      );

      expect(args, [
        'verbose',
        'dart-define-from-file=env.json',
        'split-per-abi',
      ]);
    });

    test('resolveRepository prefers CLI value', () {
      expect(
        setup.resolveRepository(
          'hi2shark/FlClash',
          environment: const {'GITHUB_REPOSITORY': 'environment/repo'},
        ),
        'hi2shark/FlClash',
      );
    });

    test('resolveRepository falls back to environment', () {
      expect(
        setup.resolveRepository(
          null,
          environment: const {'GITHUB_REPOSITORY': 'hi2shark/FlClash'},
        ),
        'hi2shark/FlClash',
      );
    });

    test('resolveRepository falls back to default', () {
      expect(
        setup.resolveRepository(null, environment: const {}),
        'chen08209/FlClash',
      );
      expect(
        setup.resolveRepository('', environment: const {}),
        'chen08209/FlClash',
      );
      expect(
        setup.resolveRepository('  ', environment: const {}),
        'chen08209/FlClash',
      );
    });
  });
}
