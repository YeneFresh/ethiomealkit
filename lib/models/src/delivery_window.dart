import 'package:freezed_annotation/freezed_annotation.dart';

part 'delivery_window.freezed.dart';
part 'delivery_window.g.dart';

@freezed
class DeliveryWindow with _$DeliveryWindow {
  const factory DeliveryWindow({
    required String id,
    required String label,
    String? dayOfWeek,
    String? startTime,
    String? endTime,
  }) = _DeliveryWindow;
  factory DeliveryWindow.fromJson(Map<String, dynamic> json) => _$DeliveryWindowFromJson(json);
}



