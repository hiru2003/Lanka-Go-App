class BusRouteModel {
  final String routeId;
  final String name;
  final List<String> eta;

  BusRouteModel({
    required this.routeId,
    required this.name,
    required this.eta,
  });

  factory BusRouteModel.fromJson(String id, Map<String, dynamic> json) {
    return BusRouteModel(
      routeId: id,
      name: json['name'] ?? '',
      eta: List<String>.from(json['eta'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'eta': eta,
    };
  }
}
