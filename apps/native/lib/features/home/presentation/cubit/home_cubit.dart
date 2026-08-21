import 'package:doclyvo/core/states/base_cubit.dart';
import 'package:doclyvo/features/home/presentation/cubit/home_state.dart';

final class HomeCubit extends BaseCubit<HomeState> {
  HomeCubit() : super(const HomeInitial());
}
