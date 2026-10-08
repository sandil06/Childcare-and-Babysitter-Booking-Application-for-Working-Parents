import 'package:flutter/foundation.dart';

import '../../babysitter/models/babysitter_model.dart';
import '../models/parent_model.dart';
import '../services/parent_service.dart';

class ParentProvider extends ChangeNotifier {
  ParentProvider({ParentService? service})
    : _service = service ?? ParentService();

  static ParentProvider? _instance;
  static ParentProvider get instance => _instance ??= ParentProvider();

  final ParentService _service;
  ParentModel? _profile;
  List<BabysitterModel> _babysitters = [];
  BabysitterModel? _selectedBabysitter;
  bool _isInitialLoading = false;
  bool _isRefreshing = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  static const int _limit = 10;
  String? _errorMessage;
  String _search = '';
  double? _minHourlyRate;
  double? _maxHourlyRate;
  int? _minExperience;
  double? _minRating;
  bool? _isAvailable;
  String? _skill;
  String? _language;

  ParentModel? get profile => _profile;
  List<BabysitterModel> get babysitters => List.unmodifiable(_babysitters);
  BabysitterModel? get selectedBabysitter => _selectedBabysitter;
  bool get isLoading => _isInitialLoading || _isRefreshing;
  bool get isInitialLoading => _isInitialLoading;
  bool get isRefreshing => _isRefreshing;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;
  String get search => _search;
  bool get hasFilters =>
      _minHourlyRate != null ||
      _maxHourlyRate != null ||
      _minExperience != null ||
      _minRating != null ||
      _isAvailable != null ||
      _skill != null ||
      _language != null;

  Future<void> fetchProfile() async {
    try {
      _profile = await _service.getProfile();
      _errorMessage = null;
      notifyListeners();
    } catch (error) {
      _errorMessage = error.toString();
      notifyListeners();
    }
  }

  Future<void> searchBabysitters({String? search, bool isRefresh = false}) async {
    if (search != null) _search = search;
    if (isRefresh) {
      _isRefreshing = true;
    } else if (_babysitters.isEmpty) {
      _isInitialLoading = true;
    }
    _errorMessage = null;
    notifyListeners();

    try {
      _currentPage = 1;
      final results = await _service.searchBabysitters(
        search: _search,
        minHourlyRate: _minHourlyRate,
        maxHourlyRate: _maxHourlyRate,
        minExperience: _minExperience,
        minRating: _minRating,
        isAvailable: _isAvailable,
        skill: _skill,
        language: _language,
        page: _currentPage,
        limit: _limit,
      );
      _babysitters = results;
      _hasMore = results.length >= _limit;
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isInitialLoading = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore || _isInitialLoading || _isRefreshing) {
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final results = await _service.searchBabysitters(
        search: _search,
        minHourlyRate: _minHourlyRate,
        maxHourlyRate: _maxHourlyRate,
        minExperience: _minExperience,
        minRating: _minRating,
        isAvailable: _isAvailable,
        skill: _skill,
        language: _language,
        page: nextPage,
        limit: _limit,
      );
      if (results.isNotEmpty) {
        _currentPage = nextPage;
        _babysitters = [..._babysitters, ...results];
        _hasMore = results.length >= _limit;
      } else {
        _hasMore = false;
      }
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<BabysitterModel?> selectBabysitter(BabysitterModel sitter) async {
    _selectedBabysitter = sitter;
    notifyListeners();
    try {
      _selectedBabysitter = await _service.getBabysitter(sitter.id);
      _errorMessage = null;
    } catch (error) {
      _errorMessage = error.toString();
    }
    notifyListeners();
    return _selectedBabysitter;
  }

  void setFilters({
    double? minHourlyRate,
    double? maxHourlyRate,
    int? minExperience,
    double? minRating,
    bool? isAvailable,
    String? skill,
    String? language,
  }) {
    _minHourlyRate = minHourlyRate;
    _maxHourlyRate = maxHourlyRate;
    _minExperience = minExperience;
    _minRating = minRating;
    _isAvailable = isAvailable;
    _skill = skill;
    _language = language;
    notifyListeners();
  }

  void clearFilters() {
    _minHourlyRate = null;
    _maxHourlyRate = null;
    _minExperience = null;
    _minRating = null;
    _isAvailable = null;
    _skill = null;
    _language = null;
    notifyListeners();
  }

  void reset() {
    _profile = null;
    _babysitters = [];
    _selectedBabysitter = null;
    _isInitialLoading = false;
    _isRefreshing = false;
    _isLoadingMore = false;
    _hasMore = true;
    _currentPage = 1;
    _errorMessage = null;
    _search = '';
    clearFilters();
  }
}
