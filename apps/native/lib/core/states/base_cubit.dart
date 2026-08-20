import 'package:doclyvo/core/error/json_exception.dart';
import 'package:doclyvo/core/error/response_exception.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdf_manipulator/pdf_manipulator.dart';

abstract class BaseCubit<State> extends Cubit<State> {
  BaseCubit(super.initialState);

  void safeEmit(State state) {
    if (!isClosed) emit(state);
  }

  Future<void> safeCall<T>({
    required Future<T> Function() action,
    required State loadingState,
    required State Function(T data) successState,
    required State Function(String message) errorState,
    void Function(T data)? onAfterAction,
    void Function(String error)? onAfterError,
    VoidCallback? onBeforeAction,
  }) async {
    try {
      safeEmit(loadingState);
      onBeforeAction?.call();

      final result = await action();

      onAfterAction?.call(result);
      safeEmit(successState(result));
    } on ResponseException catch (e) {
      safeEmit(errorState(e.message));
    } on JsonException catch (e) {
      safeEmit(errorState(e.message));
    } on PdfError catch (e) {
      safeEmit(errorState(e.message));
    } on Exception catch (e) {
      safeEmit(errorState(e.toString()));
    }
  }
}
