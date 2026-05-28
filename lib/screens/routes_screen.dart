import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/bus_routes_provider.dart';
import '../providers/auth_provider.dart';

class RoutesScreen extends StatefulWidget {
  const RoutesScreen({super.key});

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _ReloadButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _ReloadButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.refresh, color: Colors.white),
      onPressed: onPressed,
    );
  }
}

class _RoutesScreenState extends State<RoutesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshRoutes();
    });
  }

  void _refreshRoutes() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    Provider.of<BusRoutesProvider>(context, listen: false)
        .fetchRoutes(authProvider.backendUrl);
  }

  @override
  Widget build(BuildContext context) {
    final routesProvider = Provider.of<BusRoutesProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Colombo Bus Routes & ETAs',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          _ReloadButton(onPressed: _refreshRoutes),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF020617),
            ],
          ),
        ),
        child: SafeArea(
          child: Builder(
            builder: (context) {
              if (routesProvider.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF00F2FE)),
                );
              }

              if (routesProvider.errorMessage != null && routesProvider.routes.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_off, color: Colors.redAccent, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'ETA Tracker Offline',
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Could not connect to Flask API server. Tap refresh to retry connection.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final routes = routesProvider.routes;

              return ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: routes.length,
                itemBuilder: (context, index) {
                  final route = routes[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withAlpha(10)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00F2FE).withAlpha(20),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.navigation_outlined, color: Color(0xFF00F2FE), size: 18),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  route.name,
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        Text(
                          'INCOMING BUS ETAs',
                          style: GoogleFonts.inter(
                            color: Colors.white30,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        
                        const SizedBox(height: 12),

                        // List of incoming bus ETAs
                        Row(
                          children: route.eta.map((time) {
                            return Container(
                              margin: const EdgeInsets.only(right: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.black.withAlpha(50),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFFFB300).withAlpha(40)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time_filled, color: Color(0xFFFFB300), size: 12),
                                  const SizedBox(width: 6),
                                  Text(
                                    time,
                                    style: GoogleFonts.shareTechMono(
                                      color: const Color(0xFFFFB300),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
