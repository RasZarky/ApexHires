import 'package:flutter/material.dart';
import 'package:apex_hires/models/job_model.dart';
import 'package:apex_hires/services/firestore_service.dart';

class JobProvider extends ChangeNotifier {
  FirestoreService? _firestoreServiceRef;
  FirestoreService get _firestoreService =>
      _firestoreServiceRef ??= FirestoreService();

  bool _isLoading = false;
  String? _error;

  // Search/filter state
  String _searchQuery = '';
  String _locationFilter = '';
  String _jobTypeFilter = '';
  String _experienceFilter = '';

  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String get locationFilter => _locationFilter;
  String get jobTypeFilter => _jobTypeFilter;
  String get experienceFilter => _experienceFilter;

  // Stream active jobs
  Stream<List<JobModel>> getActiveJobs() {
    return _firestoreService.getActiveJobs();
  }

  // Search and filter jobs
  Stream<List<JobModel>> searchJobs() {
    return _firestoreService.searchJobs(
      query: _searchQuery,
      location: _locationFilter,
      jobType: _jobTypeFilter,
      experienceLevel: _experienceFilter,
    );
  }

  void setSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  void setLocationFilter(String value) {
    _locationFilter = value;
    notifyListeners();
  }

  void setJobTypeFilter(String value) {
    _jobTypeFilter = value;
    notifyListeners();
  }

  void setExperienceFilter(String value) {
    _experienceFilter = value;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _locationFilter = '';
    _jobTypeFilter = '';
    _experienceFilter = '';
    notifyListeners();
  }

  // Get jobs by recruiter
  Stream<List<JobModel>> getJobsByRecruiter(String recruiterId) {
    return _firestoreService.getJobsByRecruiter(recruiterId);
  }

  // Create a job
  Future<String?> createJob(JobModel job) async {
    _setLoading(true);
    try {
      final jobId = await _firestoreService.createJob(job);
      _setLoading(false);
      return jobId;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return null;
    }
  }

  // Update job
  Future<bool> updateJob(JobModel job) async {
    _setLoading(true);
    try {
      await _firestoreService.updateJob(job);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Update job status
  Future<bool> updateJobStatus(String jobId, String status) async {
    try {
      await _firestoreService.updateJobStatus(jobId, status);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }
}
