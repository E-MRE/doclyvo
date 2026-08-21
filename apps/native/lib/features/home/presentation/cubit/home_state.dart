abstract class HomeState {
  const HomeState();
}

final class HomeInitial implements HomeState {
  const HomeInitial();
}

final class HomeLoading implements HomeState {
  const HomeLoading();
}

final class HomeSuccess implements HomeState {
  const HomeSuccess();
}

final class HomeError implements HomeState {
  const HomeError({this.message = ''});
  final String message;
}
