import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/action.dart';
import 'package:fl_clash/providers/app.dart';
import 'package:fl_clash/providers/config.dart';
import 'package:fl_clash/providers/database.dart';
import 'package:fl_clash/state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  group('ProfilesAction', () {
    test('keeps edited profile data when remote update fails', () async {
      final original = Profile.normal(label: 'old label', url: 'bad-url');
      final edited = original.copyWith(
        label: 'new label',
        url: 'still-bad-url',
      );
      final container = ProviderContainer(
        overrides: [
          currentProfileIdProvider.overrideWithBuild((_, _) => null),
          profilesProvider.overrideWith(() => _TestProfiles([original])),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(profilesProvider).getProfile(original.id),
        original,
      );

      await expectLater(
        container.read(profilesActionProvider.notifier).updateProfile(edited),
        throwsA(anything),
      );

      final profile = container.read(profilesProvider).getProfile(original.id);
      expect(profile?.label, edited.label);
      expect(profile?.url, edited.url);
    });
  });

  group('GeoResourceAction', () {
    test('GeoResource has correct updatingKey', () {
      expect(GeoResource.MMDB.updatingKey, 'geo_resource_MMDB');
      expect(GeoResource.ASN.updatingKey, 'geo_resource_ASN');
      expect(GeoResource.GEOIP.updatingKey, 'geo_resource_GEOIP');
      expect(GeoResource.GEOSITE.updatingKey, 'geo_resource_GEOSITE');
    });

    test('IsUpdating provider works with geo resource key', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final key = GeoResource.MMDB.updatingKey;
      expect(container.read(isUpdatingProvider(key)), false);

      container.read(isUpdatingProvider(key).notifier).value = true;
      expect(container.read(isUpdatingProvider(key)), true);

      container.read(isUpdatingProvider(key).notifier).value = false;
      expect(container.read(isUpdatingProvider(key)), false);
    });
  });

  group('SetupAction polling', () {
    test('pausePolling preserves startTime and only toggles pause flag', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      globalState.container = container;

      final setup = container.read(setupActionProvider.notifier);
      final startTime = DateTime.now().subtract(const Duration(seconds: 5));
      setup.startTime = startTime;

      expect(setup.isStart, isTrue);
      expect(setup.isPollingPaused, isFalse);

      setup.pausePolling();
      expect(setup.isPollingPaused, isTrue);
      expect(setup.startTime, startTime);
      expect(setup.isStart, isTrue);

      setup.resumePolling();
      expect(setup.isPollingPaused, isFalse);
      expect(setup.startTime, startTime);
      expect(setup.isStart, isTrue);
    });

    test('pausePolling is a no-op when proxy is not started', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      globalState.container = container;

      final setup = container.read(setupActionProvider.notifier);
      setup.startTime = null;
      setup.pausePolling();
      expect(setup.isPollingPaused, isFalse);
    });
  });
}

class _TestProfiles extends Profiles {
  final List<Profile> initial;

  _TestProfiles(this.initial);

  @override
  List<Profile> build() => initial;

  @override
  void put(Profile profile) {
    final next = List<Profile>.from(state);
    final index = next.indexWhere((item) => item.id == profile.id);
    if (index == -1) {
      next.add(profile);
    } else {
      next[index] = profile;
    }
    state = next;
  }
}
