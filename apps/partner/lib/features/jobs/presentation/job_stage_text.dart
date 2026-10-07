import '../../../l10n/generated/app_localizations.dart';
import '../domain/job.dart';

extension JobStageText on JobStage {
  String text(AppLocalizations l10n) => switch (this) {
        JobStage.requested => l10n.stageRequested,
        JobStage.accepted => l10n.stageAccepted,
        JobStage.onTheWay => l10n.stageOnTheWay,
        JobStage.arrived => l10n.stageArrived,
        JobStage.inProgress => l10n.stageInProgress,
        JobStage.completed => l10n.stageCompleted,
        JobStage.cancelled => l10n.stageCancelled,
      };

  String actionText(AppLocalizations l10n) => switch (this) {
        JobStage.requested => l10n.actionAccept,
        JobStage.accepted => l10n.actionStartTravel,
        JobStage.onTheWay => l10n.actionArrived,
        JobStage.arrived => l10n.actionStartJob,
        JobStage.inProgress => l10n.actionCompleteJob,
        JobStage.completed => l10n.stageCompleted,
        JobStage.cancelled => l10n.stageCancelled,
      };
}
