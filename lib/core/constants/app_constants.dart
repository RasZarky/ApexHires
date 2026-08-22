class AppConstants {
  // Collection paths
  static const String usersCollection = 'users';
  static const String jobsCollection = 'jobs';
  static const String applicationsCollection = 'applications';
  static const String chatsCollection = 'chats';

  // Roles
  static const String roleJobSeeker = 'job_seeker';
  static const String roleRecruiter = 'recruiter';
  static const String roleAdmin = 'admin';

  // Job Types
  static const List<String> jobTypes = [
    'Full-time',
    'Part-time',
    'Contract',
    'Remote',
    'Hybrid',
  ];

  // Experience Levels
  static const List<String> experienceLevels = [
    'Entry',
    'Mid',
    'Senior',
    'Lead',
  ];

  // Application Statuses
  static const List<String> applicationStatuses = [
    'applied',
    'shortlisted',
    'interviewing',
    'hired',
    'rejected',
  ];

  // Job Statuses
  static const List<String> jobStatuses = [
    'active',
    'paused',
    'closed',
  ];

  // Currencies
  static const List<String> currencies = [
    'USD',
    'EUR',
    'GBP',
    'CAD',
    'AUD',
    'INR',
  ];
}
