// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'delivery_window.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

DeliveryWindow _$DeliveryWindowFromJson(Map<String, dynamic> json) {
  return _DeliveryWindow.fromJson(json);
}

/// @nodoc
mixin _$DeliveryWindow {
  String get id => throw _privateConstructorUsedError;
  String get label => throw _privateConstructorUsedError;
  String? get dayOfWeek => throw _privateConstructorUsedError;
  String? get startTime => throw _privateConstructorUsedError;
  String? get endTime => throw _privateConstructorUsedError;

  /// Serializes this DeliveryWindow to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DeliveryWindow
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DeliveryWindowCopyWith<DeliveryWindow> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DeliveryWindowCopyWith<$Res> {
  factory $DeliveryWindowCopyWith(
    DeliveryWindow value,
    $Res Function(DeliveryWindow) then,
  ) = _$DeliveryWindowCopyWithImpl<$Res, DeliveryWindow>;
  @useResult
  $Res call({
    String id,
    String label,
    String? dayOfWeek,
    String? startTime,
    String? endTime,
  });
}

/// @nodoc
class _$DeliveryWindowCopyWithImpl<$Res, $Val extends DeliveryWindow>
    implements $DeliveryWindowCopyWith<$Res> {
  _$DeliveryWindowCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DeliveryWindow
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? label = null,
    Object? dayOfWeek = freezed,
    Object? startTime = freezed,
    Object? endTime = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            label: null == label
                ? _value.label
                : label // ignore: cast_nullable_to_non_nullable
                      as String,
            dayOfWeek: freezed == dayOfWeek
                ? _value.dayOfWeek
                : dayOfWeek // ignore: cast_nullable_to_non_nullable
                      as String?,
            startTime: freezed == startTime
                ? _value.startTime
                : startTime // ignore: cast_nullable_to_non_nullable
                      as String?,
            endTime: freezed == endTime
                ? _value.endTime
                : endTime // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DeliveryWindowImplCopyWith<$Res>
    implements $DeliveryWindowCopyWith<$Res> {
  factory _$$DeliveryWindowImplCopyWith(
    _$DeliveryWindowImpl value,
    $Res Function(_$DeliveryWindowImpl) then,
  ) = __$$DeliveryWindowImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String label,
    String? dayOfWeek,
    String? startTime,
    String? endTime,
  });
}

/// @nodoc
class __$$DeliveryWindowImplCopyWithImpl<$Res>
    extends _$DeliveryWindowCopyWithImpl<$Res, _$DeliveryWindowImpl>
    implements _$$DeliveryWindowImplCopyWith<$Res> {
  __$$DeliveryWindowImplCopyWithImpl(
    _$DeliveryWindowImpl _value,
    $Res Function(_$DeliveryWindowImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DeliveryWindow
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? label = null,
    Object? dayOfWeek = freezed,
    Object? startTime = freezed,
    Object? endTime = freezed,
  }) {
    return _then(
      _$DeliveryWindowImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        label: null == label
            ? _value.label
            : label // ignore: cast_nullable_to_non_nullable
                  as String,
        dayOfWeek: freezed == dayOfWeek
            ? _value.dayOfWeek
            : dayOfWeek // ignore: cast_nullable_to_non_nullable
                  as String?,
        startTime: freezed == startTime
            ? _value.startTime
            : startTime // ignore: cast_nullable_to_non_nullable
                  as String?,
        endTime: freezed == endTime
            ? _value.endTime
            : endTime // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$DeliveryWindowImpl implements _DeliveryWindow {
  const _$DeliveryWindowImpl({
    required this.id,
    required this.label,
    this.dayOfWeek,
    this.startTime,
    this.endTime,
  });

  factory _$DeliveryWindowImpl.fromJson(Map<String, dynamic> json) =>
      _$$DeliveryWindowImplFromJson(json);

  @override
  final String id;
  @override
  final String label;
  @override
  final String? dayOfWeek;
  @override
  final String? startTime;
  @override
  final String? endTime;

  @override
  String toString() {
    return 'DeliveryWindow(id: $id, label: $label, dayOfWeek: $dayOfWeek, startTime: $startTime, endTime: $endTime)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DeliveryWindowImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.dayOfWeek, dayOfWeek) ||
                other.dayOfWeek == dayOfWeek) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.endTime, endTime) || other.endTime == endTime));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, label, dayOfWeek, startTime, endTime);

  /// Create a copy of DeliveryWindow
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DeliveryWindowImplCopyWith<_$DeliveryWindowImpl> get copyWith =>
      __$$DeliveryWindowImplCopyWithImpl<_$DeliveryWindowImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$DeliveryWindowImplToJson(this);
  }
}

abstract class _DeliveryWindow implements DeliveryWindow {
  const factory _DeliveryWindow({
    required final String id,
    required final String label,
    final String? dayOfWeek,
    final String? startTime,
    final String? endTime,
  }) = _$DeliveryWindowImpl;

  factory _DeliveryWindow.fromJson(Map<String, dynamic> json) =
      _$DeliveryWindowImpl.fromJson;

  @override
  String get id;
  @override
  String get label;
  @override
  String? get dayOfWeek;
  @override
  String? get startTime;
  @override
  String? get endTime;

  /// Create a copy of DeliveryWindow
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DeliveryWindowImplCopyWith<_$DeliveryWindowImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
