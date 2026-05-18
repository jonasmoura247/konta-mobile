import 'package:flutter/material.dart';
import '../app.dart';
import '../theme/app_theme.dart';

class ChangelogScreen extends StatelessWidget {
  const ChangelogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final versions = kChangelog.keys.toList();

    return Scaffold(
      backgroundColor: context.kBg,
      appBar: AppBar(
        title: const Text('Últimas Atualizações'),
        backgroundColor: context.kCard,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: versions.length,
        itemBuilder: (context, i) {
          final version = versions[i];
          final items = kChangelog[version]!;
          final isCurrent = version == kAppVersion;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: context.kCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isCurrent
                    ? AppColors.accent.withValues(alpha: 0.4)
                    : context.kCardBorder,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  child: Row(
                    children: [
                      Text(
                        'v$version',
                        style: TextStyle(
                          color: isCurrent
                              ? AppColors.accent
                              : context.kTextPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'JetBrainsMono',
                        ),
                      ),
                      if (isCurrent) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'atual',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final item in items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 16,
                                color: isCurrent
                                    ? AppColors.accent
                                    : context.kTextSecondary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item,
                                  style: TextStyle(
                                    color: context.kTextPrimary,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
