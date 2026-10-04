import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';

class BookingProvider extends ChangeNotifier {
  static BookingProvider? _instance;
  static BookingProvider get instance => _instance ??= BookingProvider();

  DateTime? _selectedDate;
  DateTime? get selectedDate => _selectedDate;

  TimeOfDayValue? _startTime;
  TimeOfDayValue? get startTime => _startTime;

  TimeOfDayValue? _endTime;
  TimeOfDayValue? get endTime => _endTime;

  bool _liveLocationEnabled = false;
  bool get liveLocationEnabled => _liveLocationEnabled;
  bool _isUpdatingLiveLocation = false;
  bool get isUpdatingLiveLocation => _isUpdatingLiveLocation;
  String? _liveLocationError;
  String? get liveLocationError => _liveLocationError;

  bool get isComplete =>
      _selectedDate != null && _startTime != null && _endTime != null;

  Future<void> loadLiveLocationStatus() async {
    try {
      final response = await ApiClient().get('tracking/live-location');
      if (response is Map) {
        _liveLocationEnabled = response['sharingEnabled'] == true;
        _liveLocationError = null;
        notifyListeners();
      }
    } catch (error) {
      _liveLocationError = error.toString();
      notifyListeners();
    }
  }

  Future<bool> setLiveLocationEnabled(bool enabled) async {
    final previous = _liveLocationEnabled;
    _isUpdatingLiveLocation = true;
    _liveLocationError = null;
    notifyListeners();
    try {
      final response = await ApiClient().patch(
        'tracking/live-location',
        body: {'sharingEnabled': enabled},
      );
      if (response is! Map) throw Exception('Invalid live location response');
      _liveLocationEnabled = response['sharingEnabled'] == true;
      return true;
    } catch (error) {
      _liveLocationEnabled = previous;
      _liveLocationError = error.toString();
      return false;
    } finally {
      _isUpdatingLiveLocation = false;
      notifyListeners();
    }
  }

  void selectDate(DateTime date) {
    _selectedDate = DateTime(date.year, date.month, date.day);
    _startTime = null;
    _endTime = null;
    _liveLocationEnabled = false;
    _isUpdatingLiveLocation = false;
    _liveLocationError = null;
    notifyListeners();
  }

  void selectStartTime(TimeOfDayValue time) {
    _startTime = time;
    if (_endTime != null && time.toMinutes >= _endTime!.toMinutes) {
      _endTime = null;
    }
    notifyListeners();
  }

  void selectEndTime(TimeOfDayValue time) {
    if (_startTime == null || time.toMinutes <= _startTime!.toMinutes) return;
    _endTime = time;
    notifyListeners();
  }

  void reset() {
    _selectedDate = null;
    _startTime = null;
    _endTime = null;
    notifyListeners();
  }
}

class TimeOfDayValue {
  const TimeOfDayValue({required this.hour, required this.minute});

  final int hour;
  final int minute;

  int get toMinutes => hour * 60 + minute;

  String get formatted {
    final hourLabel = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final period = hour >= 12 ? 'PM' : 'AM';
    return '${hourLabel.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }
}
