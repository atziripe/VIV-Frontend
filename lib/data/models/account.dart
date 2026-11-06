import 'json.dart';

/// `DELETE /me` — deletion is scheduled, not immediate.
class DeletionSchedule {
  const DeletionSchedule({required this.pendingDeletionAt, this.gracePeriodDays = 30});

  final DateTime pendingDeletionAt;
  final int gracePeriodDays;

  factory DeletionSchedule.fromJson(Json j) => DeletionSchedule(
    pendingDeletionAt:
        DateTime.tryParse(j.strOr('pending_deletion_at'))?.toLocal() ??
        DateTime.now().add(const Duration(days: 30)),
    gracePeriodDays: j.integer('grace_period_days') ?? 30,
  );
}

/// The fixed set of consent purposes (`/me/consents`).
enum ConsentPurpose {
  /// Required to use VIV at all; revoking it deletes the account immediately.
  healthDataProcessing('health_data_processing'),
  aiProcessing('ai_processing'),
  researchProductImprovement('research_product_improvement');

  const ConsentPurpose(this.id);
  final String id;

  static ConsentPurpose? fromId(String? id) {
    for (final p in values) {
      if (p.id == id) return p;
    }
    return null;
  }
}

/// Current state of one purpose (`GET /me/consents`).
class ConsentItem {
  const ConsentItem({required this.purpose, required this.granted, this.policyVersion});

  final ConsentPurpose purpose;
  final bool granted;
  final String? policyVersion;

  static ConsentItem? fromJson(Json j) {
    final purpose = ConsentPurpose.fromId(j.str('purpose'));
    if (purpose == null) return null;
    return ConsentItem(
      purpose: purpose,
      granted: j.flag('granted'),
      policyVersion: j.str('policy_version'),
    );
  }
}

/// `POST /onboarding/ineligibility` reasons — one per "not a fit yet" answer.
enum IneligibilityReason {
  pregnantOrPostpartum('pregnant_or_postpartum'),
  perimenopauseOrMenopause('perimenopause_or_menopause'),
  hormonalContraception('hormonal_contraception'),
  notSure('not_sure');

  const IneligibilityReason(this.id);
  final String id;
}
