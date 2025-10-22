import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ethiomealkit/core/providers/cart_pricing_providers.dart';
import 'package:ethiomealkit/core/providers/address_providers.dart';
import 'package:ethiomealkit/core/providers/delivery_window_provider.dart';
import 'package:ethiomealkit/core/providers/payment_providers.dart';
import 'package:ethiomealkit/services/payments/adapters/ussd_helper.dart';
import 'package:ethiomealkit/services/webview_service.dart';

enum PaymentProviderId { telebirr, chapa, arifpay, cbe, cod }

final paymentControllerProvider =
    StateNotifierProvider<PaymentController, void>(
      (ref) => PaymentController(ref),
    );

class PaymentController extends StateNotifier<void> {
  PaymentController(this.ref) : super(null);
  final Ref ref;

  Future<String?> placeOrderAndPay() async {
    ref.read(isPlacingOrderProvider.notifier).state = true;
    try {
      final sb = Supabase.instance.client;
      final totals = ref.read(cartTotalsProvider);
      final address = ref.read(activeAddressProvider);
      final window = ref.read(deliveryWindowProvider);
      final method = ref.read(paymentMethodProvider);

      if (address == null || window == null || method == null) return null;

      final provider = _mapMethodToProvider(method);
      final body = {
        'amount_cents': (totals.total * 100).round(),
        'currency': 'ETB',
        'provider_id': provider.name,
        'method_id': null,
        'address_id': address.id,
        'delivery_window_id': window.id,
        'idempotency_key':
            'yf_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}',
      };

      final resp = await sb.functions.invoke('payments-intent', body: body);
      final data = (resp.data as Map?) ?? {};
      final redirect = data['redirect_url'] as String?;
      final orderId = data['order_id'] as String?;

      if (redirect != null) {
        if (provider == PaymentProviderId.telebirr ||
            provider == PaymentProviderId.cbe) {
          await UssdHelper.open(redirect);
        } else {
          await WebviewService.open(redirect);
        }
      }
      return orderId;
    } finally {
      ref.read(isPlacingOrderProvider.notifier).state = false;
    }
  }

  PaymentProviderId _mapMethodToProvider(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.chapa:
        return PaymentProviderId.chapa;
      case PaymentMethod.telebirr:
        return PaymentProviderId.telebirr;
    }
  }
}
