// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApiResponseModel<TData> _$ApiResponseModelFromJson<TData>(
  Map<String, dynamic> json,
  TData Function(Object? json) fromJsonTData,
) => ApiResponseModel<TData>(
  data: _$nullableGenericFromJson(json['data'], fromJsonTData),
  isSuccess: json['isSuccess'] as bool? ?? false,
  message: json['message'] == null
      ? ''
      : ApiResponseModel._defaultIfNull(json['message']),
);

Map<String, dynamic> _$ApiResponseModelToJson<TData>(
  ApiResponseModel<TData> instance,
  Object? Function(TData value) toJsonTData,
) => <String, dynamic>{
  'data': ?_$nullableGenericToJson(instance.data, toJsonTData),
  'isSuccess': instance.isSuccess,
  'message': instance.message,
};

T? _$nullableGenericFromJson<T>(
  Object? input,
  T Function(Object? json) fromJson,
) => input == null ? null : fromJson(input);

Object? _$nullableGenericToJson<T>(
  T? input,
  Object? Function(T value) toJson,
) => input == null ? null : toJson(input);
