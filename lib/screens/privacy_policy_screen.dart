import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../utils/privacy_policy_text.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  final bool viewOnly;
  const PrivacyPolicyScreen({super.key, this.viewOnly = false});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  bool _scrolledToBottom = false;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (!widget.viewOnly) {
      _scrollController.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      if (!_scrolledToBottom) setState(() => _scrolledToBottom = true);
    }
  }

  Future<void> _accept() async {
    final settings = DatabaseService.getSettings();
    settings.privacyAccepted = true;
    await DatabaseService.saveSettings(settings);
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.kBg,
      appBar: widget.viewOnly
          ? AppBar(title: const Text('Política de Privacidade'))
          : null,
      body: SafeArea(
        child: Column(
          children: [
            if (!widget.viewOnly) ...[
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shield_outlined,
                          color: AppColors.accent, size: 28),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Política de Privacidade',
                      style: TextStyle(
                        color: context.kTextPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Antes de usar o Konta, leia e aceite nossa Política de Privacidade.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.kTextSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: context.kCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.kCardBorder),
                ),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    kPrivacyPolicyText,
                    style: TextStyle(
                      color: context.kTextPrimary,
                      fontSize: 13,
                      height: 1.6,
                      fontFamily: 'SpaceGrotesk',
                    ),
                  ),
                ),
              ),
            ),
            if (!widget.viewOnly) ...[
              const SizedBox(height: 16),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    if (!_scrolledToBottom)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Role até o final para aceitar',
                          style: TextStyle(
                            color: context.kTextSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _scrolledToBottom ? _accept : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          disabledBackgroundColor:
                              AppColors.accent.withValues(alpha: 0.3),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          'Li e aceito a Política de Privacidade',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
