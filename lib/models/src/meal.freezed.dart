// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'meal.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Meal _$MealFromJson(Map<String, dynamic> json) {
  return _Meal.fromJson(json);
}

/// @nodoc
mixin _$Meal {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  int? get calories => throw _privateConstructorUsedError;
  int? get protein => throw _privateConstructorUsedError;
  int? get carbs => throw _privateConstructorUsedError;
  int? get fat => throw _privateConstructorUsedError;
  int? get cookTimeMinutes => throw _privateConstructorUsedError;
  List<String>? get tags => throw _privateConstructorUsedError;
  String? get imageUrl => throw _privateConstructorUsedError;

  /// Serializes this Meal to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Meal
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MealCopyWith<Meal> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MealCopyWith<$Res> {
  factory $MealCopyWith(Meal value, $Res Function(Meal) then) =
      _$MealCopyWithImpl<$Res, Meal>;
  @useResult
  $Res call({
    String id,
    String title,
    String? description,
    int? calories,
    int? protein,
    int? carbs,
    int? fat,
    int? cookTimeMinutes,
    List<String>? tags,
    String? imageUrl,
  });
}

/// @nodoc
class _$MealCopyWithImpl<$Res, $Val extends Meal>
    implements $MealCopyWith<$Res> {
  _$MealCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Meal
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = freezed,
    Object? calories = freezed,
    Object? protein = freezed,
    Object? carbs = freezed,
    Object? fat = freezed,
    Object? cookTimeMinutes = freezed,
    Object? tags = freezed,
    Object? imageUrl = freezed,
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
            calories: freezed == calories
                ? _value.calories
                : calories // ignore: cast_nullable_to_non_nullable
                      as int?,
            protein: freezed == protein
                ? _value.protein
                : protein // ignore: cast_nullable_to_non_nullable
                      as int?,
            carbs: freezed == carbs
                ? _value.carbs
                : carbs // ignore: cast_nullable_to_non_nullable
                      as int?,
            fat: freezed == fat
                ? _value.fat
                : fat // ignore: cast_nullable_to_non_nullable
                      as int?,
            cookTimeMinutes: freezed == cookTimeMinutes
                ? _value.cookTimeMinutes
                : cookTimeMinutes // ignore: cast_nullable_to_non_nullable
                      as int?,
            tags: freezed == tags
                ? _value.tags
                : tags // ignore: cast_nullable_to_non_nullable
                      as List<String>?,
            imageUrl: freezed == imageUrl
                ? _value.imageUrl
                : imageUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MealImplCopyWith<$Res> implements $MealCopyWith<$Res> {
  factory _$$MealImplCopyWith(
    _$MealImpl value,
    $Res Function(_$MealImpl) then,
  ) = __$$MealImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String title,
    String? description,
    int? calories,
    int? protein,
    int? carbs,
    int? fat,
    int? cookTimeMinutes,
    List<String>? tags,
    String? imageUrl,
  });
}

/// @nodoc
class __$$MealImplCopyWithImpl<$Res>
    extends _$MealCopyWithImpl<$Res, _$MealImpl>
    implements _$$MealImplCopyWith<$Res> {
  __$$MealImplCopyWithImpl(_$MealImpl _value, $Res Function(_$MealImpl) _then)
    : super(_value, _then);

  /// Create a copy of Meal
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = freezed,
    Object? calories = freezed,
    Object? protein = freezed,
    Object? carbs = freezed,
    Object? fat = freezed,
    Object? cookTimeMinutes = freezed,
    Object? tags = freezed,
    Object? imageUrl = freezed,
  }) {
    return _then(
      _$MealImpl(
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
        calories: freezed == calories
            ? _value.calories
            : calories // ignore: cast_nullable_to_non_nullable
                  as int?,
        protein: freezed == protein
            ? _value.protein
            : protein // ignore: cast_nullable_to_non_nullable
                  as int?,
        carbs: freezed == carbs
            ? _value.carbs
            : carbs // ignore: cast_nullable_to_non_nullable
                  as int?,
        fat: freezed == fat
            ? _value.fat
            : fat // ignore: cast_nullable_to_non_nullable
                  as int?,
        cookTimeMinutes: freezed == cookTimeMinutes
            ? _value.cookTimeMinutes
            : cookTimeMinutes // ignore: cast_nullable_to_non_nullable
                  as int?,
        tags: freezed == tags
            ? _value._tags
            : tags // ignore: cast_nullable_to_non_nullable
                  as List<String>?,
        imageUrl: freezed == imageUrl
            ? _value.imageUrl
            : imageUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MealImpl implements _Meal {
  const _$MealImpl({
    required this.id,
    required this.title,
    this.description,
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.cookTimeMinutes,
    final List<String>? tags,
    this.imageUrl,
  }) : _tags = tags;

  factory _$MealImpl.fromJson(Map<String, dynamic> json) =>
      _$$MealImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String? description;
  @override
  final int? calories;
  @override
  final int? protein;
  @override
  final int? carbs;
  @override
  final int? fat;
  @override
  final int? cookTimeMinutes;
  final List<String>? _tags;
  @override
  List<String>? get tags {
    final value = _tags;
    if (value == null) return null;
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final String? imageUrl;

  @override
  String toString() {
    return 'Meal(id: $id, title: $title, description: $description, calories: $calories, protein: $protein, carbs: $carbs, fat: $fat, cookTimeMinutes: $cookTimeMinutes, tags: $tags, imageUrl: $imageUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MealImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.calories, calories) ||
                other.calories == calories) &&
            (identical(other.protein, protein) || other.protein == protein) &&
            (identical(other.carbs, carbs) || other.carbs == carbs) &&
            (identical(other.fat, fat) || other.fat == fat) &&
            (identical(other.cookTimeMinutes, cookTimeMinutes) ||
                other.cookTimeMinutes == cookTimeMinutes) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    title,
    description,
    calories,
    protein,
    carbs,
    fat,
    cookTimeMinutes,
    const DeepCollectionEquality().hash(_tags),
    imageUrl,
  );

  /// Create a copy of Meal
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MealImplCopyWith<_$MealImpl> get copyWith =>
      __$$MealImplCopyWithImpl<_$MealImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MealImplToJson(this);
  }
}

abstract class _Meal implements Meal {
  const factory _Meal({
    required final String id,
    required final String title,
    final String? description,
    final int? calories,
    final int? protein,
    final int? carbs,
    final int? fat,
    final int? cookTimeMinutes,
    final List<String>? tags,
    final String? imageUrl,
  }) = _$MealImpl;

  factory _Meal.fromJson(Map<String, dynamic> json) = _$MealImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String? get description;
  @override
  int? get calories;
  @override
  int? get protein;
  @override
  int? get carbs;
  @override
  int? get fat;
  @override
  int? get cookTimeMinutes;
  @override
  List<String>? get tags;
  @override
  String? get imageUrl;

  /// Create a copy of Meal
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MealImplCopyWith<_$MealImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
