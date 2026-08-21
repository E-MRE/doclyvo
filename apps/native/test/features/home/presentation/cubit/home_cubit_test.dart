import 'package:doclyvo/features/home/presentation/cubit/home_cubit.dart';
import 'package:doclyvo/features/home/presentation/cubit/home_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HomeCubit', () {
    late HomeCubit homeCubit;

    setUp(() {
      homeCubit = HomeCubit();
    });

    tearDown(() async {
      await homeCubit.close();
    });

    test('initial state is HomeInitial', () {
      expect(homeCubit.state, isA<HomeInitial>());
    });

    test('can emit state safely', () {
      expect(homeCubit.state, isA<HomeInitial>());
      homeCubit.safeEmit(const HomeSuccess());
      expect(homeCubit.state, isA<HomeSuccess>());
    });

    test('does not emit after close', () async {
      await homeCubit.close();
      expect(
        () => homeCubit.safeEmit(const HomeSuccess()),
        returnsNormally,
      );
    });
  });
}
