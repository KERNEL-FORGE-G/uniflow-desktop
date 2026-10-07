import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../services/flutterwave_service.dart';
import '../widgets/phosphor.dart';

/// Boîte de dialogue grand format pour les abonnements UniFlow sur Desktop.
class SubscriptionDialog extends ConsumerStatefulWidget {
  const SubscriptionDialog({super.key});

  @override
  ConsumerState<SubscriptionDialog> createState() => _SubscriptionDialogState();
}

class _SubscriptionDialogState extends ConsumerState<SubscriptionDialog> {
  bool _isAnnual = false;
  String _selectedPlanCode = 'PRO_CAMPUS';
  String? _successMessage;

  Future<void> _payViaWhatsApp(DesktopSubscriptionPlanInfo plan) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final service = ref.read(desktopFlutterwaveServiceProvider);

    await service.openWhatsAppBilling(
      plan: plan,
      isAnnual: _isAnnual,
      user: user,
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(desktopFlutterwaveServiceProvider);
    final plans = service.getAvailablePlans();
    final selectedPlan = plans.firstWhere(
      (p) => p.code == _selectedPlanCode,
      orElse: () => plans[1],
    );
    final amount =
        _isAnnual ? selectedPlan.annualAmount : selectedPlan.monthlyAmount;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const PhosphorIcon(PhosphorIconsFill.sparkle,
                            color: Color(0xFF1E3A8A), size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Abonnements & Accès Pro',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Validation immédiate et accompagnement officiel via WhatsApp (+237 6 57 63 56 44)',
                            style: TextStyle(
                                fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const PhosphorIcon(PhosphorIconsBold.x, size: 20),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Cycle Selector
              Center(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _isAnnual = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color:
                                !_isAnnual ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: !_isAnnual
                                ? [
                                    BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.08),
                                        blurRadius: 6)
                                  ]
                                : null,
                          ),
                          child: Text(
                            'Mensuel',
                            style: TextStyle(
                              color: !_isAnnual
                                  ? const Color(0xFF1E3A8A)
                                  : const Color(0xFF64748B),
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _isAnnual = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: _isAnnual
                                ? const Color(0xFF1E3A8A)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: _isAnnual
                                ? [
                                    BoxShadow(
                                        color: const Color(0xFF1E3A8A)
                                            .withValues(alpha: 0.2),
                                        blurRadius: 8)
                                  ]
                                : null,
                          ),
                          child: Row(
                            children: [
                              Text(
                                'Annuel',
                                style: TextStyle(
                                  color: _isAnnual
                                      ? Colors.white
                                      : const Color(0xFF64748B),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _isAnnual
                                      ? const Color(0xFFF59E0B)
                                      : const Color(0xFF10B981),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  '2 mois offerts',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Contenu principal : 3 cartes de plan OU écran de paiement
              Expanded(
                child: _successMessage != null
                    ? Center(
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const PhosphorIcon(PhosphorIconsFill.checkCircle,
                                  color: Color(0xFF16A34A), size: 54),
                              const SizedBox(height: 16),
                              const Text(
                                'Paiement Flutterwave Confirmé !',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF15803D)),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _successMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 14, color: Color(0xFF166534)),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF16A34A),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 28, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text(
                                    'Fermer et profiter de l\'accès Pro'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 3 colonnes de plans
                          for (final plan in plans)
                            Expanded(
                              child: Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: _selectedPlanCode == plan.code
                                      ? const Color(0xFFF0FDF4)
                                      : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: _selectedPlanCode == plan.code
                                        ? const Color(0xFF0D9488)
                                        : const Color(0xFFE2E8F0),
                                    width:
                                        _selectedPlanCode == plan.code ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (plan.isPopular)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0D9488),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: const Text(
                                          'POPULAIRE',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 6),
                                    Text(
                                      plan.name,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      plan.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF64748B)),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      (_isAnnual
                                                  ? plan.annualAmount
                                                  : plan.monthlyAmount) ==
                                              0
                                          ? 'Gratuit'
                                          : '${_isAnnual ? plan.annualAmount : plan.monthlyAmount} ${plan.currency} ${_isAnnual ? '/an' : '/mois'}',
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF1E3A8A),
                                      ),
                                    ),
                                    const Divider(height: 18),
                                    Expanded(
                                      child: ListView(
                                        children: [
                                          for (final feat in plan.features)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 6),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const PhosphorIcon(
                                                      PhosphorIconsFill
                                                          .checkCircle,
                                                      color: Color(0xFF0D9488),
                                                      size: 14),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(
                                                      feat,
                                                      style: const TextStyle(
                                                          fontSize: 11,
                                                          color: Color(
                                                              0xFF334155)),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton(
                                        onPressed: () => setState(() =>
                                            _selectedPlanCode = plan.code),
                                        style: OutlinedButton.styleFrom(
                                          backgroundColor:
                                              _selectedPlanCode == plan.code
                                                  ? const Color(0xFF1E3A8A)
                                                  : Colors.white,
                                          foregroundColor:
                                              _selectedPlanCode == plan.code
                                                  ? Colors.white
                                                  : const Color(0xFF1E3A8A),
                                          side: BorderSide(
                                            color:
                                                _selectedPlanCode == plan.code
                                                    ? const Color(0xFF1E3A8A)
                                                    : const Color(0xFFCBD5E1),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                        ),
                                        child: Text(
                                          _selectedPlanCode == plan.code
                                              ? 'Sélectionné'
                                              : 'Choisir',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
              ),

              if (_successMessage == null &&
                  selectedPlan.monthlyAmount > 0) ...[
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Color(0xFFDCFCE7),
                          shape: BoxShape.circle,
                        ),
                        child: const PhosphorIcon(
                          PhosphorIconsBold.chatsCircle,
                          color: Color(0xFF16A34A),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Validation et activation par WhatsApp (+237 6 57 63 56 44)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF166534),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Formule ${selectedPlan.name} ($amount ${selectedPlan.currency}) · Activation manuelle instantanée par l\'équipe d\'administration UniFlow.',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF15803D),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () => _payViaWhatsApp(selectedPlan),
                        icon: const PhosphorIcon(
                          PhosphorIconsBold.chatsCircle,
                          color: Colors.white,
                          size: 18,
                        ),
                        label: const Text(
                          'Activer via WhatsApp',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
