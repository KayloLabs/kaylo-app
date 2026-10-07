/// The customer's rating of one finished booking. One per booking, and the
/// customer may change their mind (`submit_review` upserts).
class BookingReview {
  final String bookingId;
  final String workerId;
  final int rating;
  final String? text;
  final DateTime createdAt;

  const BookingReview({
    required this.bookingId,
    required this.workerId,
    required this.rating,
    this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'bookingId': bookingId,
    'workerId': workerId,
    'rating': rating,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
  };

  factory BookingReview.fromJson(Map<String, dynamic> json) => BookingReview(
    bookingId: json['bookingId'] as String,
    workerId: json['workerId'] as String,
    rating: json['rating'] as int,
    text: json['text'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
