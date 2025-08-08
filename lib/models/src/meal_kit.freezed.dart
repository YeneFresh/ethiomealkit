// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'meal_kit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

MealKit _$MealKitFromJson(Map<String, dynamic> json) {
  return _MealKit.fromJson(json);
}

/// @nodoc
mixin _$MealKit {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  int get priceCents => throw _privateConstructorUsedError;
  String? get imageUrl => throw _privateConstructorUsedError;
  List<Meal>? get meals => throw _privateConstructorUsedError;

  /// Serializes this MealKit to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MealKit
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MealKitCopyWith<MealKit> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MealKitCopyWith<$Res> {
  factory $MealKitCopyWith(MealKit value, $Res Function(MealKit) then) =
      _$MealKitCopyWithImpl<$Res, MealKit>;
  @useResult
  $Res call({
    String id,
    String title,
    String? description,
    int priceCents,
    String? imageUrl,
    List<Meal>? meals,
  });
}

/// @nodoc
class _$MealKitCopyWithImpl<$Res, $Val extends MealKit>
    implements $MealKitCopyWith<$Res> {
  _$MealKitCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MealKit
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = freezed,
    Object? priceCents = null,
    Object? imageUrl = freezed,
    Object? meals = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            priceCents: null == priceCents
                ? _value.priceCents
                : priceCents // ignore: cast_nullable_to_non_nullable
                      as int,
            imageUrl: freezed == imageUrl
                ? _value.imageUrl
                : imageUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            meals: freezed == meals
                ? _value.meals
                : meals // ignore: cast_nullable_to_non_nullable
                      as List<Meal>?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MealKitImplCopyWith<$Res> implements $MealKitCopyWith<$Res> {
  factory _$$MealKitImplCopyWith(
    _$MealKitImpl value,
    $Res Function(_$MealKitImpl) then,
  ) = __$$MealKitImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String title,
    String? description,
    int priceCents,
    String? imageUrl,
    List<Meal>? meals,
  });
}

/// @nodoc
class __$$MealKitImplCopyWithImpl<$Res>
    extends _$MealKitCopyWithImpl<$Res, _$MealKitImpl>
    implements _$$MealKitImplCopyWith<$Res> {
  __$$MealKitImplCopyWithImpl(
    _$MealKitImpl _value,
    $Res Function(_$MealKitImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MealKit
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = freezed,
    Object? priceCents = null,
    Object? imageUrl = freezed,
    Object? meals = freezed,
  }) {
    return _then(
      _$MealKitImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        priceCents: null == priceCents
            ? _value.priceCents
            : priceCents // ignore: cast_nullable_to_non_nullable
                  as int,
        imageUrl: freezed == imageUrl
            ? _value.imageUrl
            : imageUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        meals: freezed == meals
            ? _value._meals
            : meals // ignore: cast_nullable_to_non_nullable
                  as List<Meal>?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MealKitImpl implements _MealKit {
  const _$MealKitImpl({
    required this.id,
    required this.title,
    this.description,
    required this.priceCents,
    this.imageUrl,
    final List<Meal>? meals,
  }) : _meals = meals;

  factory _$MealKitImpl.fromJson(Map<String, dynamic> json) =>
      _$$MealKitImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String? description;
  @override
  final int priceCents;
  @override
  final String? imageUrl;
  final List<Meal>? _meals;
  @override
  List<Meal>? get meals {
    final value = _meals;
    if (value == null) return null;
    if (_meals is EqualUnmodifiableListView) return _meals;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'MealKit(id: $id, title: $title, description: $description, priceCents: $priceCents, imageUrl: $imageUrl, meals: $meals)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MealKitImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.priceCents, priceCents) ||
                other.priceCents == priceCents) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            const DeepCollectionEquality().equals(other._meals, _meals));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    title,
    description,
    priceCents,
    imageUrl,
    const DeepCollectionEquality().hash(_meals),
  );

  /// Create a copy of MealKit
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MealKitImplCopyWith<_$MealKitImpl> get copyWith =>
      __$$MealKitImplCopyWithImpl<_$MealKitImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MealKitImplToJson(this);
  }
}

abstract class _MealKit implements MealKit {
  const factory _MealKit({
    required final String id,
    required final String title,
    final String? description,
    required final int priceCents,
    final String? imageUrl,
    final List<Meal>? meals,
  }) = _$MealKitImpl;

  factory _MealKit.fromJson(Map<String, dynamic> json) = _$MealKitImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String? get description;
  @override
  int get priceCents;
  @override
  String? get imageUrl;
  @override
  List<Meal>? get meals;

  /// Create a copy of MealKit
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MealKitImplCopyWith<_$MealKitImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
