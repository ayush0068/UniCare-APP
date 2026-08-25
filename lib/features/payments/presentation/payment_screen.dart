import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../data/payment_api.dart';

/// Opens the actual Razorpay checkout UI (Cards / Netbanking / Wallet /
/// UPI / Pay Later) — the native Android equivalent of the popup you see
/// on the website via razorpay-checkout.js. Same flow, same options,
/// just rendered natively instead of in a browser iframe.
///
/// Flow (mirrors backend/routes/payment.js exactly):
///   1. POST /api/payment/create-order  -> { orderId, amount, key }
///      (or { free: true } if a loyalty discount covers it fully)
///   2. razorpay.open(...) with that orderId/amount/key
///   3. Razorpay's own UI handles card/UPI/etc. entry
///   4. On success -> POST /api/payment/verify-payment with the 3
///      values Razorpay returns (order_id, payment_id, signature) —
///      the backend verifies the HMAC signature before marking Paid.
class PaymentScreen extends StatefulWidget {
  final String appointmentId;
  final num amount;
  final String? doctorName;
  final String? patientName;
  final String? patientEmail;
  final String? patientPhone;

  const PaymentScreen({
    super.key,
    required this.appointmentId,
    required this.amount,
    this.doctorName,
    this.patientName,
    this.patientEmail,
    this.patientPhone,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late final Razorpay _razorpay;
  final _paymentApi = PaymentApi();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear(); // required by the plugin to release listeners
    super.dispose();
  }

  Future<void> _startPayment() async {
    setState(() => _isProcessing = true);
    try {
      final orderData = await _paymentApi.createOrder(widget.appointmentId);

      // Loyalty discount covered the full amount — nothing to charge.
      if (orderData['free'] == true) {
        if (!mounted) return;
        _goToSuccess();
        return;
      }

      final options = {
        'key': orderData['key'],
        'amount': (orderData['amount'] as num) * 100, // Razorpay wants paise
        'order_id': orderData['orderId'],
        'currency': orderData['currency'] ?? 'INR',
        'name': 'UniCare+',
        'description': widget.doctorName != null
            ? 'Consultation with ${widget.doctorName}'
            : 'Doctor Consultation',
        'prefill': {
          if (widget.patientName != null) 'name': widget.patientName,
          if (widget.patientEmail != null) 'email': widget.patientEmail,
          if (widget.patientPhone != null) 'contact': widget.patientPhone,
        },
        'theme': {'color': '#0D9488'}, // matches AppColors.primary
      };

      _razorpay.open(options);
    } catch (e) {
      setState(() => _isProcessing = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start payment: $e')),
      );
    }
  }

  void _onPaymentSuccess(PaymentSuccessResponse response) async {
    try {
      await _paymentApi.verifyPayment(
        appointmentId: widget.appointmentId,
        razorpayOrderId: response.orderId!,
        razorpayPaymentId: response.paymentId!,
        razorpaySignature: response.signature!,
      );
      if (!mounted) return;
      _goToSuccess();
    } catch (e) {
      setState(() => _isProcessing = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment succeeded but verification failed: $e')),
      );
    }
  }

  void _onPaymentError(PaymentFailureResponse response) {
    setState(() => _isProcessing = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment failed: ${response.message ?? "Please try again"}')),
    );
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    setState(() => _isProcessing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Redirected to ${response.walletName}')),
    );
  }

  void _goToSuccess() {
    context.go('/booking-success', extra: {
      'consultationType': 'Payment Confirmed',
      'totalAmount': widget.amount,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Payment')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.payments_rounded, color: AppColors.primaryDark, size: 48),
              ),
              const SizedBox(height: 24),
              Text(
                '₹${widget.amount}',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                widget.doctorName != null
                    ? 'Consultation with ${widget.doctorName}'
                    : 'Doctor consultation fee',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _startPayment,
                  child: _isProcessing
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                      : const Text('Pay Now'),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Secured by Razorpay',
                style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}