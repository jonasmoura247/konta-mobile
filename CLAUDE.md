# Konta — Controle Financeiro Mobile

## Regra principal

**Antes de criar ou modificar qualquer funcionalidade, execute `/wiki <descrição do que será criado>`.**

A wiki do projeto fica em:
```
C:\Users\Jonas\Desktop\Anotacoes\Farmas-Mobile\Wiki-Funcionalidades\
```

O comando `/wiki` lê os documentos relevantes e garante que a implementação respeite as decisões já tomadas sobre modelos, serviços e padrões visuais do projeto.

## Stack

- Flutter (Android)
- Hive (banco local, 100% offline)
- Riverpod (gerência de estado)
- fl_chart (gráficos)
- go_router (navegação)

## Padrões do projeto

- Dados calculados nunca são persistidos no Hive — sempre recalculados a partir das transações e entradas reais
- Toda lógica financeira fica em `FinanceCalculator` (`lib/services/finance_calculator.dart`)
- Acesso ao banco sempre via `DatabaseService` (`lib/services/database_service.dart`)
- Widgets recebem dados por parâmetro — nunca acessam Hive diretamente
- Cores do projeto em `AppColors` (`lib/theme/app_theme.dart`)
- Formatação de moeda e datas via `lib/utils/formatters.dart`
- O Dashboard recalcula tudo quando `DatabaseService.dataVersion` muda
