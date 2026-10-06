import '../../features/jobs/domain/job.dart';

class PartnerWorkerProfile {
  final String id;
  final String name;
  final String phone;
  final String email;
  final double rating;
  final int reviewsCount;
  final int acceptanceRate;
  final int completionRate;
  final int totalJobs;
  final String upiId;
  final String bankAccount;
  final bool aadhaarVerified;
  final bool policeVerified;
  final List<String> services;
  final String district;
  final String workingHours;

  const PartnerWorkerProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.rating,
    required this.reviewsCount,
    required this.acceptanceRate,
    required this.completionRate,
    required this.totalJobs,
    required this.upiId,
    required this.bankAccount,
    required this.aadhaarVerified,
    required this.policeVerified,
    required this.services,
    required this.district,
    required this.workingHours,
  });
}

class PartnerSeed {
  static const worker = PartnerWorkerProfile(
    id: 'worker-sunil-01',
    name: 'Sunil Kumar',
    phone: '+91 98470 12345',
    email: 'sunil.kaylopartner@gmail.com',
    rating: 4.88,
    reviewsCount: 142,
    acceptanceRate: 97,
    completionRate: 99,
    totalJobs: 142,
    upiId: 'sunilkumar@oksbi',
    bankAccount: 'State Bank of India •••• 5678',
    aadhaarVerified: true,
    policeVerified: true,
    services: [
      'Plumbing Repair',
      'Electrical Services',
      'Appliance Repair',
      'Carpentry & Fitting',
    ],
    district: 'Kannur District (15 km radius)',
    workingHours: 'Mon – Sat: 8:00 AM – 7:00 PM',
  );

  static List<Job> initialJobs() {
    final now = DateTime.now();

    return [
      // 1 active job (on the way)
      Job(
        id: 'job-active-1',
        serviceName: 'Plumbing Repair',
        serviceIcon: 'plumbing',
        customerName: 'Anjali Menon',
        customerPhone: '+91 94471 23456',
        addressLine: 'Kadavil House, Thottada Beach Rd, Kannur',
        distanceKm: 2.4,
        scheduledAt: now.subtract(const Duration(minutes: 25)),
        payout: 450.0,
        notes: 'Water leaking under kitchen sink. Main valve is shut off.',
        stage: JobStage.onTheWay,
      ),

      // 2 incoming requests
      Job(
        id: 'job-req-1',
        serviceName: 'Electrical Wiring',
        serviceIcon: 'electrical',
        customerName: 'Dr. Vivek Nair',
        customerPhone: '+91 94472 88990',
        addressLine: 'Green Valley Villa 4B, Mele Chovva, Kannur',
        distanceKm: 4.1,
        scheduledAt: now.add(const Duration(hours: 1)),
        payout: 650.0,
        notes: 'Ceiling fan regulator sparking and needs replacement.',
        stage: JobStage.requested,
      ),
      Job(
        id: 'job-req-2',
        serviceName: 'Bathroom Mixer Fitting',
        serviceIcon: 'plumbing',
        customerName: 'Fathima Rafeeq',
        customerPhone: '+91 98950 44321',
        addressLine: 'Al-Huda, South Bazaar, Kannur',
        distanceKm: 1.8,
        scheduledAt: now.add(const Duration(hours: 2)),
        payout: 380.0,
        notes: 'Two bathroom mixer taps need installation. Parts purchased.',
        stage: JobStage.requested,
      ),

      // Completed jobs over the last 6 days for rich earnings breakdown
      Job(
        id: 'job-comp-today',
        serviceName: 'Washing Machine Drainage',
        serviceIcon: 'appliances',
        customerName: 'K. P. Ramachandran',
        customerPhone: '+91 94460 11223',
        addressLine: 'Hill View, Pallikunnu, Kannur',
        distanceKm: 3.2,
        scheduledAt: DateTime(now.year, now.month, now.day, 9, 30),
        payout: 520.0,
        notes: 'Drain hose clogged and fixed.',
        stage: JobStage.completed,
      ),
      Job(
        id: 'job-comp-yest-1',
        serviceName: 'Main Switchboard Repair',
        serviceIcon: 'electrical',
        customerName: 'Sneha George',
        customerPhone: '+91 94473 33445',
        addressLine: 'Rose Villa, Kaloor, Kannur',
        distanceKm: 2.1,
        scheduledAt: now.subtract(const Duration(days: 1)),
        payout: 750.0,
        notes: 'Replaced MCB and rewiring checked.',
        stage: JobStage.completed,
      ),
      Job(
        id: 'job-comp-yest-2',
        serviceName: 'Kitchen Tap Leak',
        serviceIcon: 'plumbing',
        customerName: 'Rajeev V.',
        customerPhone: '+91 98951 55667',
        addressLine: 'Thalap, Kannur',
        distanceKm: 1.5,
        scheduledAt: now.subtract(const Duration(days: 1, hours: 4)),
        payout: 400.0,
        notes: 'Washer replaced.',
        stage: JobStage.completed,
      ),
      Job(
        id: 'job-comp-d2',
        serviceName: 'Sink Trap Replacement',
        serviceIcon: 'plumbing',
        customerName: 'Devika Nambiar',
        customerPhone: '+91 94477 77889',
        addressLine: 'Payyambalam Rd, Kannur',
        distanceKm: 2.8,
        scheduledAt: now.subtract(const Duration(days: 2)),
        payout: 450.0,
        notes: 'New PVC bottle trap installed.',
        stage: JobStage.completed,
      ),
      Job(
        id: 'job-comp-d3-1',
        serviceName: 'Geyser Element Replacement',
        serviceIcon: 'appliances',
        customerName: 'Muhammed Shafi',
        customerPhone: '+91 98952 99001',
        addressLine: 'City Centre, Kannur',
        distanceKm: 2.0,
        scheduledAt: now.subtract(const Duration(days: 3)),
        payout: 850.0,
        notes: 'Thermostat and heating element replaced.',
        stage: JobStage.completed,
      ),
      Job(
        id: 'job-comp-d3-2',
        serviceName: 'Water Meter Valve Fitting',
        serviceIcon: 'plumbing',
        customerName: 'Anoop Kurian',
        customerPhone: '+91 94461 44556',
        addressLine: 'Puzhathi, Kannur',
        distanceKm: 3.5,
        scheduledAt: now.subtract(const Duration(days: 3, hours: 5)),
        payout: 380.0,
        notes: 'Gate valve replaced.',
        stage: JobStage.completed,
      ),
      Job(
        id: 'job-comp-d4',
        serviceName: 'Ceiling Fan Installation',
        serviceIcon: 'electrical',
        customerName: 'Priya Mohan',
        customerPhone: '+91 94470 66778',
        addressLine: 'Chovva, Kannur',
        distanceKm: 4.0,
        scheduledAt: now.subtract(const Duration(days: 4)),
        payout: 600.0,
        notes: 'Two fans assembled and mounted.',
        stage: JobStage.completed,
      ),
      Job(
        id: 'job-comp-d5',
        serviceName: 'Submersible Pump Wiring',
        serviceIcon: 'electrical',
        customerName: 'Balan Master',
        customerPhone: '+91 98953 22334',
        addressLine: 'Edakkad, Kannur',
        distanceKm: 6.2,
        scheduledAt: now.subtract(const Duration(days: 5)),
        payout: 900.0,
        notes: 'Starter panel rewiring and testing.',
        stage: JobStage.completed,
      ),
    ];
  }

  /// Live pool for releasing periodic simulated requests when online
  static const liveQueuePool = [
    {
      'serviceName': 'Overhead Tank Float Valve',
      'serviceIcon': 'plumbing',
      'customerName': 'Haridasan K.',
      'customerPhone': '+91 94474 11229',
      'addressLine': 'Near AKG Hospital, Talap, Kannur',
      'distanceKm': 2.2,
      'payout': 420.0,
      'notes': 'Water overflowing from roof tank. Need ball valve check.',
    },
    {
      'serviceName': 'Inverter Battery Terminal Fix',
      'serviceIcon': 'electrical',
      'customerName': 'Meera Krishnan',
      'customerPhone': '+91 98955 77881',
      'addressLine': 'Govt Hospital Rd, Kannur',
      'distanceKm': 1.9,
      'payout': 550.0,
      'notes': 'Inverter beeping continuously on power cut.',
    },
    {
      'serviceName': 'Kitchen Sink Drain Clog',
      'serviceIcon': 'plumbing',
      'customerName': 'Abdul Rasheed',
      'customerPhone': '+91 94462 88992',
      'addressLine': 'Fort Road, Kannur',
      'distanceKm': 2.7,
      'payout': 480.0,
      'notes': 'Water draining very slowly. Snaking required.',
    },
    {
      'serviceName': 'LED Tube Light & Fan Fitting',
      'serviceIcon': 'electrical',
      'customerName': 'Sindhu Manoj',
      'customerPhone': '+91 98956 33441',
      'addressLine': 'Chalad, Kannur',
      'distanceKm': 3.1,
      'payout': 500.0,
      'notes': 'Fit two batten lights and one wall bracket.',
    },
  ];
}
