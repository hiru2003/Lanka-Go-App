import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/bus_route_model.dart';

class BusRoutesProvider with ChangeNotifier {
  List<BusRouteModel> _routes = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<BusRouteModel> get routes => _routes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Fetches Colombo bus route schedules from the backend, falling back to local mocks if offline.
  Future<void> fetchRoutes(String backendUrl) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse('$backendUrl/api/routes'))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<BusRouteModel> loaded = [];
        data.forEach((id, val) {
          loaded.add(BusRouteModel.fromJson(id, Map<String, dynamic>.from(val)));
        });
        _routes = loaded;
      } else {
        _errorMessage = 'Server returned code: ${response.statusCode}';
      }
    } catch (e) {
      print('Network ETA fetch failed. Loading local schedule catalog.');
      // Load local offline mock catalog
      _routes = [
        BusRouteModel(
          routeId: 'route_138',
          name: '138 Pettah-Borella',
          eta: ['2 min', '8 min', '16 min'],
        ),
        BusRouteModel(
          routeId: 'route_120',
          name: '120 Colombo-Horana',
          eta: ['4 min', '11 min'],
        ),
        BusRouteModel(
          routeId: 'route_177',
          name: '177 Kollupitiya-Kaduwela',
          eta: ['7 min', '21 min'],
        ),
      ];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
