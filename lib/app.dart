import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'screens/dashboard_screen.dart';
import 'screens/transactions_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/reservas_screen.dart';
import 'screens/privacy_policy_screen.dart';
import 'services/database_service.dart';
import 'services/month_selection_service.dart';
import 'theme/app_theme.dart';

const kAppVersion = '1.0.9';

/// Histórico de changelogs por versão (mais recente primeiro).
const kChangelog = <String, List<String>>{
  '1.0.9': [
    'Lançamentos: segure o ícone ≡ ao lado dos 3 pontinhos e arraste para reorganizar.',
    'A ordem é salva automaticamente por aba (Todos, Crédito, Débito, Pix, Dinheiro).',
    'Fecha o app, troca de aba, minimiza — a ordem persiste exatamente como você deixou.',
    'Flag do banco agora usa a cor configurada nas suas configurações.',
  ],
  '1.0.8': [
    'Lançamentos: nova organização por abas — Todos, Cartão, Pix e Dinheiro.',
    'Cartão agora tem sub-abas: Crédito e Débito.',
    'Pix com cartão de crédito: suporte completo, aparece na aba Crédito.',
    'Destaque visual para o mês de entrada na fatura do cartão.',
    'Formulário de lançamento não perde os dados ao minimizar o app ou trocar de aplicativo.',
  ],
  '1.0.7': [
    'Backup e exportacao passaram a incluir vencimentos de cartao.',
    'Importacao e reset ficaram alinhados com os vencimentos de cartao.',
    'A ordem dos bancos no calendario agora permanece estavel.',
    'Lancamentos editados preservam a regra de fechamento original.',
  ],
  '1.0.6': [
    'Entradas marcadas como "Valor Família" — não afetam o saldo pessoal.',
    'Configure o dia de fechamento e pagamento de cada cartão de crédito.',
    'Compras feitas após o fechamento do cartão aparecem no mês correto automaticamente.',
    'Teclado restaurado ao retornar de outro aplicativo durante um lançamento.',
  ],
  '1.0.5': [
    'Novo seletor Cartão / Débito ao criar lançamentos.',
    'Subtipo de pagamento: Pix, Dinheiro, Débito.',
    'Preview do valor da parcela antes de confirmar.',
    'Edição completa de categorias (nome, ícone, cor).',
    'Ordenação de categorias personalizada.',
    'Remoção de categorias duplicadas.',
    'Escolher local para download de relatórios.',
  ],
};

class KontaApp extends StatelessWidget {
  const KontaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) => MaterialApp.router(
        title: 'Konta',
        debugShowCheckedModeBanner: false,
        locale: const Locale('pt', 'BR'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('pt', 'BR'),
        ],
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: mode,
        routerConfig: _router,
      ),
    );
  }
}

final _router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final accepted = DatabaseService.getSettings().privacyAccepted;
    final isPrivacy = state.uri.path == '/privacy-policy';
    if (!accepted && !isPrivacy) return '/privacy-policy';
    return null;
  },
  routes: [
    GoRoute(
      path: '/privacy-policy',
      builder: (_, state) {
        final viewOnly = state.uri.queryParameters['view'] == 'true';
        return PrivacyPolicyScreen(viewOnly: viewOnly);
      },
    ),
    ShellRoute(
      builder: (context, state, child) => _Shell(child: child),
      routes: [
        GoRoute(path: '/', builder: (_, __) => const DashboardScreen()),
        GoRoute(
          path: '/transactions',
          builder: (_, state) =>
              TransactionsScreen(initialMonth: state.extra as DateTime?),
        ),
        GoRoute(path: '/calendar', builder: (_, __) => const CalendarScreen()),
        GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),
        GoRoute(path: '/reservas', builder: (_, __) => const ReservasScreen()),
        GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      ],
    ),
  ],
);

class _Shell extends StatefulWidget {
  final Widget child;
  const _Shell({required this.child});

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  int _currentIndex = 0;

  static const _routes = [
    '/',
    '/transactions',
    '/calendar',
    '/history',
    '/reservas'
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final location = GoRouterState.of(context).uri.path;
    final idx = _routes.indexOf(location);
    if (idx >= 0 && idx != _currentIndex) {
      _currentIndex = idx;
    }
  }

  void _onTap(int index) {
    setState(() => _currentIndex = index);
    final route = _routes[index];
    if (route == '/') {
      MonthSelectionService.setActiveMonth(DateTime.now());
      context.go(route);
    } else if (route == '/transactions') {
      context.go(route, extra: MonthSelectionService.activeMonth.value);
    } else {
      context.go(route);
    }
  }

  void _showChangelogDialog() {
    final items = kChangelog[kAppVersion] ?? [];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Novidades da v$kAppVersion'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final item in items) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(child: Text(item)),
                  ],
                ),
                const SizedBox(height: 6),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              DatabaseService.saveLastSeenVersion(kAppVersion);
              Navigator.of(context).pop();
              setState(() {});
            },
            child: const Text('Fechar'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showChangelog = DatabaseService.getLastSeenVersion() != kAppVersion;
    return Scaffold(
      body: Column(
        children: [
          if (showChangelog)
            Container(
              width: double.infinity,
              color: AppColors.accent.withValues(alpha: 0.06),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                      child: Text('Konta foi atualizado para v$kAppVersion — veja as novidades!',
                          style: const TextStyle(fontWeight: FontWeight.w600))),
                  TextButton(
                    onPressed: _showChangelogDialog,
                    child: const Text('Ver novidades'),
                  ),
                  TextButton(
                    onPressed: () {
                      DatabaseService.saveLastSeenVersion(kAppVersion);
                      setState(() {});
                    },
                    child: const Text('Fechar'),
                  )
                ],
              ),
            ),
          Expanded(child: widget.child),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: context.kCardBorder, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTap,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Início'),
            BottomNavigationBarItem(
                icon: Icon(Icons.list_outlined),
                activeIcon: Icon(Icons.list),
                label: 'Lançamentos'),
            BottomNavigationBarItem(
                icon: Icon(Icons.calendar_month_outlined),
                activeIcon: Icon(Icons.calendar_month),
                label: 'Calendário'),
            BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart_outlined),
                activeIcon: Icon(Icons.bar_chart),
                label: 'Histórico'),
            BottomNavigationBarItem(
                icon: Icon(Icons.savings_outlined),
                activeIcon: Icon(Icons.savings),
                label: 'Reservas'),
          ],
        ),
      ),
      floatingActionButton: null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
    );
  }
}
