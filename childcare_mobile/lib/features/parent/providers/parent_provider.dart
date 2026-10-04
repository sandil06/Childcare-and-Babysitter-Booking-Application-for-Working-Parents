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
  bool _isLoading = false;
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
  bool get isLoading => _isLoading;
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

  Future<void> searchBabysitters({String? search}) async {
    if (search != null) _search = search;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _babysitters = await _service.searchBabysitters(
        search: _search,
        minHourlyRate: _minHourlyRate,
        maxHourlyRate: _maxHourlyRate,
        minExperience: _minExperience,
        minRating: _minRating,
        isAvailable: _isAvailable,
        skill: _skill,
        language: _language,
      );
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
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
    _isLoading = false;
    _errorMessage = null;
    _search = '';
    clearFilters();
  }
}
