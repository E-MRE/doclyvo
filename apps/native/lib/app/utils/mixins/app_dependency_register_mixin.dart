import 'package:dio/dio.dart';
import 'package:doclyvo/app/theme/theme_manager.dart';
import 'package:doclyvo/app/theme/theme_service.dart';
import 'package:doclyvo/core/config/configurations.dart';
import 'package:doclyvo/core/dependency/dependency_injector.dart';
import 'package:doclyvo/core/network/dio_network_manager.dart';
import 'package:doclyvo/core/network/network_service.dart';
import 'package:doclyvo/core/pdf/pdf_engine_service.dart';
import 'package:doclyvo/core/pdf/pdf_manipulator_engine_service.dart';
import 'package:doclyvo/core/widgets/upload/file_picker_service.dart';
import 'package:doclyvo/core/widgets/upload/platform_file_picker_manager.dart';
import 'package:doclyvo/features/compress/data/repositories/compress_repository.dart';
import 'package:doclyvo/features/compress/data/repositories/pdf_engine_compress_repository.dart';
import 'package:doclyvo/features/compress/presentation/cubit/compress_cubit.dart';
import 'package:doclyvo/features/home/presentation/cubit/home_cubit.dart';
import 'package:doclyvo/features/merge/data/repositories/merge_repository.dart';
import 'package:doclyvo/features/merge/data/repositories/pdf_engine_merge_repository.dart';
import 'package:doclyvo/features/merge/presentation/cubit/merge_cubit.dart';
import 'package:doclyvo/features/reorder/data/repositories/pdf_engine_reorder_repository.dart';
import 'package:doclyvo/features/reorder/data/repositories/reorder_repository.dart';
import 'package:doclyvo/features/reorder/presentation/cubit/reorder_cubit.dart';
import 'package:doclyvo/features/rotate/data/repositories/pdf_engine_rotate_repository.dart';
import 'package:doclyvo/features/rotate/data/repositories/rotate_repository.dart';
import 'package:doclyvo/features/rotate/presentation/cubit/rotate_cubit.dart';
import 'package:doclyvo/features/split/data/repositories/pdf_engine_split_repository.dart';
import 'package:doclyvo/features/split/data/repositories/split_repository.dart';
import 'package:doclyvo/features/split/presentation/cubit/split_cubit.dart';
import 'package:doclyvo/features/watermark/data/repositories/pdf_engine_watermark_repository.dart';
import 'package:doclyvo/features/watermark/data/repositories/watermark_repository.dart';
import 'package:doclyvo/features/watermark/presentation/cubit/watermark_cubit.dart';

mixin AppDependencyRegisterMixin {
  void registerDependencies(DependencyInjector injector) {
    _registerCoreDependencies(injector);
    _registerNetworkDependencies(injector);
    if (Configurations.isDevelopment) {
      _registerDevelopmentDependencies(injector);
    } else {
      _registerReleaseDependencies(injector);
    }
    _registerRepositories(injector);
    _registerCubits(injector);
  }

  void _registerCoreDependencies(DependencyInjector injector) {
    // The engine owns a worker and a loaded native binary — one shared
    // instance for the whole app, created on first use by whichever tool
    // needs it first.
    injector
      ..registerLazySingleton<PdfEngineService>(
        PdfManipulatorEngineService.new,
        dispose: (service) => service.dispose(),
      )
      ..registerLazySingleton<ThemeService>(ThemeManager.new)
      // Stateless — a single instance keeps every tool's dropzone on the same
      // PDF-only validation rules.
      ..registerLazySingleton<FilePickerService>(
        PlatformFilePickerManager.new,
      );
  }

  void _registerNetworkDependencies(DependencyInjector injector) {
    injector
      ..registerFactory<Dio>(
        () => Dio(
          BaseOptions(
            baseUrl: Configurations.environmentProfile.baseUrl,
            connectTimeout: const Duration(seconds: 32),
            receiveTimeout: const Duration(seconds: 32),
            sendTimeout: const Duration(seconds: 32),
          ),
        ),
      )
      ..registerSingleton<NetworkService>(
        DioNetworkManager(injector.get<Dio>()),
      );
  }

  void _registerDevelopmentDependencies(DependencyInjector injector) {}

  void _registerReleaseDependencies(DependencyInjector injector) {}

  void _registerRepositories(DependencyInjector injector) {
    injector
      ..registerFactory<CompressRepository>(
        () => PdfEngineCompressRepository(injector.get<PdfEngineService>()),
      )
      ..registerFactory<SplitRepository>(
        () => PdfEngineSplitRepository(injector.get<PdfEngineService>()),
      )
      ..registerFactory<MergeRepository>(
        () => PdfEngineMergeRepository(injector.get<PdfEngineService>()),
      )
      ..registerFactory<RotateRepository>(
        () => PdfEngineRotateRepository(injector.get<PdfEngineService>()),
      )
      ..registerFactory<ReorderRepository>(
        () => PdfEngineReorderRepository(injector.get<PdfEngineService>()),
      )
      ..registerFactory<WatermarkRepository>(
        () => PdfEngineWatermarkRepository(injector.get<PdfEngineService>()),
      );
  }

  void _registerCubits(DependencyInjector injector) {
    injector
      ..registerFactory<HomeCubit>(HomeCubit.new)
      ..registerFactory<CompressCubit>(
        () => CompressCubit(injector.get<CompressRepository>()),
      )
      ..registerFactory<SplitCubit>(
        () => SplitCubit(injector.get<SplitRepository>()),
      )
      ..registerFactory<MergeCubit>(
        () => MergeCubit(injector.get<MergeRepository>()),
      )
      ..registerFactory<RotateCubit>(
        () => RotateCubit(injector.get<RotateRepository>()),
      )
      ..registerFactory<ReorderCubit>(
        () => ReorderCubit(injector.get<ReorderRepository>()),
      )
      ..registerFactory<WatermarkCubit>(
        () => WatermarkCubit(injector.get<WatermarkRepository>()),
      );
  }
}
