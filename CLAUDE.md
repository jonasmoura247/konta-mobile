# Konta — Controle Financeiro Mobile

## Documentação do projeto (vault)

Toda a documentação fica em:
```
C:\Users\Jonas\Desktop\Anotacoes\Konta\
```

Antes de implementar qualquer funcionalidade, leia os arquivos relevantes do vault para respeitar as decisões já tomadas sobre modelos, serviços e padrões visuais.

| Se envolve... | Leia |
|---|---|
| Qualquer coisa | `README.md` · `Tecnico/modelos.md` · `Tecnico/database-service.md` |
| Visão geral e decisões | `Plano/visao-produto.md` · `Plano/decisoes.md` |
| Dashboard, saldo | `Usabilidade/dashboard.md` · `Tecnico/finance-calculator.md` |
| Lançamentos, transações | `Usabilidade/lancamentos.md` |
| Calendário | `Usabilidade/calendario.md` |
| Histórico anual | `Usabilidade/historico.md` |
| Reservas, metas | `Usabilidade/reservas-e-metas.md` |
| Configurações | `Usabilidade/configuracoes.md` |
| Fluxos do usuário | `Usabilidade/fluxos.md` |
| Serviços (notificações, PDF, import) | `Tecnico/servicos.md` |
| Cálculos financeiros | `Tecnico/finance-calculator.md` |
| Widgets, componentes | `Tecnico/widgets.md` |
| Utilitários, formatadores | `Tecnico/utils.md` |
| Arquitetura, Hive | `Tecnico/arquitetura.md` |
| Rotas, navegação | `Tecnico/rotas-e-navegacao.md` |
| Tema, cores | `Tecnico/tema-e-estilos.md` |
| Roadmap e status | `Plano/roadmap.md` |
| Plano atual | `Plano/plano-ajustes-mai-2026.md` |

## Stack

- Flutter (Android, Dart)
- Hive (banco local, 100% offline)
- Riverpod parcial + ValueNotifier (estado)
- fl_chart (gráficos)
- go_router 14.x (navegação)

## Planos e documentação

Sempre que solicitado para criar um plano, salve em: `C:\Users\Jonas\Desktop\Anotacoes\Konta\Plano\`

## Padrões obrigatórios

- Dados calculados **nunca** são persistidos no Hive — sempre recalculados a partir das transações e entradas reais
- Toda lógica financeira fica em `FinanceCalculator` (`lib/services/finance_calculator.dart`)
- Acesso ao banco sempre via `DatabaseService` (`lib/services/database_service.dart`)
- Widgets recebem dados por parâmetro — nunca acessam Hive diretamente
- Cores do projeto em `AppColors` (`lib/theme/app_theme.dart`)
- Formatação de moeda e datas via `lib/utils/formatters.dart`
- Reatividade via `DatabaseService.dataVersion` (ValueNotifier) — não criar novos Providers Riverpod sem discussão
- Novos modelos Hive precisam de `typeId` único e `build_runner` para gerar o adapter `.g.dart`
