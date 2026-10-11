enum PartnerNotificationType { request, job, payout, system }

class PartnerNotification {
  final String id, title, body;
  final PartnerNotificationType type;
  final bool isRead;
  final DateTime createdAt;
  final String? jobId, event;
  final Map<String, String> details;
  const PartnerNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.jobId,
    this.event,
    this.details = const {},
  });
  PartnerNotification copyWith({bool? isRead}) => PartnerNotification(
    id: id,
    title: title,
    body: body,
    type: type,
    createdAt: createdAt,
    isRead: isRead ?? this.isRead,
    jobId: jobId,
    event: event,
    details: details,
  );
  factory PartnerNotification.fromJson(Map<String, dynamic> row) =>
      PartnerNotification(
        id: row['notification_id'] as String,
        title: row['title'] as String? ?? '',
        body: row['message'] as String? ?? '',
        type: switch (row['type']) {
          'request' ||
          'booking_request' ||
          'new_job_request' => PartnerNotificationType.request,
          'booking' || 'job' => PartnerNotificationType.job,
          'payout' || 'payment' => PartnerNotificationType.payout,
          _ => PartnerNotificationType.system,
        },
        createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
        isRead: row['is_read'] == true,
        jobId: row['booking_id'] as String?,
      );
}
