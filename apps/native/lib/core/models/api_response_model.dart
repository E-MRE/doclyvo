import 'package:json_annotation/json_annotation.dart';

part 'api_response_model.g.dart';

@JsonSerializable(genericArgumentFactories: true)
final class ApiResponseModel<TData> {
  const ApiResponseModel({
    this.data,
    this.isSuccess = false,
    this.message = '',
  });

  factory ApiResponseModel.fromJson(
    Map<String, dynamic> json,
    TData Function(Object?) parser,
  ) =>
      _$ApiResponseModelFromJson(json, parser);

  final TData? data;

  @JsonKey(defaultValue: false)
  final bool isSuccess;

  @JsonKey(defaultValue: '', fromJson: _defaultIfNull)
  final String message;

  Map<String, dynamic> toJson(Object? Function(TData) toJsonT) =>
      _$ApiResponseModelToJson(this, toJsonT);

  static String _defaultIfNull(dynamic value) => value as String? ?? '';
}
