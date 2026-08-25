import '../../../core/network/dio_client.dart';

/// Maps to backend/routes/payment.js
class PaymentApi {
  final _dioClient = DioClient();

  /// POST /api/payment/create-order
  /// Returns either:
  ///   { free: true, appointmentId }                     -- fully loyalty-discounted, skip Razorpay
  ///   { orderId, amount, currency, key }                 -- open Razorpay checkout with these
  Future<Map<String, dynamic>> createOrder(String appointmentId) async {
    final response = await _dioClient.safeRequest(
          () => _dioClient.dio.post('/payment/create-order', data: {
        'appointmentId': appointmentId,
      }),
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  /// POST /api/payment/verify-payment
  /// Called after Razorpay checkout succeeds, with the 3 values Razorpay
  /// hands back. Backend verifies the HMAC signature server-side before
  /// marking the appointment Paid — this call is what actually confirms
  /// payment, not the Razorpay success callback itself.
  Future<Map<String, dynamic>> verifyPayment({
    required String appointmentId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    final response = await _dioClient.safeRequest(
          () => _dioClient.dio.post('/payment/verify-payment', data: {
        'appointmentId': appointmentId,
        'razorpay_order_id': razorpayOrderId,
        'razorpay_payment_id': razorpayPaymentId,
        'razorpay_signature': razorpaySignature,
      }),
    );
    return response.data['data'] as Map<String, dynamic>;
  }
}