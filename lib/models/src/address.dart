import 'package:freezed_annotation/freezed_annotation.dart';

part 'address.freezed.dart';
part 'address.g.dart';

@freezed
class Address with _$Address {
  const factory Address({
    required String id,
    String? label,
    required String line1,
    String? line2,
    String? city,
    String? region,
    double? latitude,
    double? longitude,
    String? instructions,
    @Default(false) bool isDefault,
  }) = _Address;
  factory Address.fromJson(Map<String, dynamic> json) => _$AddressFromJson(json);
}


