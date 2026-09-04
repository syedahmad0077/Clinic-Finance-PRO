import 'package:flutter/material.dart';

class ClinicHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const ClinicHeader({
    super.key,
    this.title = 'SYED SADIQ POLY CLINIC & LAB',
    this.subtitle = 'Advanced Patient Care & Diagnostic Services',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF0D9488), Color(0xFF115E59)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F766E).withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Clinic Medical Cross Logo Badge
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
            ),
            child: const Icon(
              Icons.local_hospital_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),

          // Clinic Title & Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.phone_rounded, color: Colors.white70, size: 13),
                    const SizedBox(width: 4),
                    const Text(
                      'Ph: +92 300 4915255',
                      style: TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                    const SizedBox(width: 14),
                    const Icon(Icons.location_on_rounded, color: Colors.white70, size: 13),
                    const SizedBox(width: 4),
                    const Expanded(
                      child: Text(
                        'Muhallah Doake, G.T. Road, Muridke',
                        style: TextStyle(fontSize: 11, color: Colors.white70),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
