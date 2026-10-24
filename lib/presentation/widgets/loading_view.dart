import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Indikator loading terpusat dengan pesan opsional.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message = 'Memproses...'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.lime),
          const SizedBox(height: 16),
          Text(message, style: AppTypography.bodyMd(color: AppColors.sage)),
        ],
      ),
    );
  }
}
