<div align="center">

# 💰 Konta

**Controle financeiro pessoal e familiar — 100% offline, direto no celular.**

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)
![Hive](https://img.shields.io/badge/Banco-Hive-yellow)
![Plataforma](https://img.shields.io/badge/Plataforma-Android%20%7C%20iOS-lightgrey)

</div>

---

## 📖 Sobre o projeto

O **Konta** é um aplicativo mobile de controle financeiro pessoal e familiar, desenvolvido em Flutter. Todo o dado fica armazenado localmente no dispositivo (sem servidor, sem nuvem), usando o banco Hive.

O app nasceu da necessidade de ter uma visão clara das finanças do dia a dia — com suporte a gastos parcelados, assinaturas recorrentes, múltiplas fontes de renda, modo família e geração de relatórios em PDF.

---

## ✅ O que já está funcionando

| Funcionalidade | Status |
|---|---|
| Dashboard com resumo mensal (gastos, entradas, saldo) | ✅ |
| Navegação por mês (anterior / próximo) | ✅ |
| Lançamento de transações (à vista, parcelado, assinatura) | ✅ |
| Lançamento e gerenciamento de entradas (salário, freelance etc.) | ✅ |
| Gráfico de pizza por categoria (carrossel) | ✅ |
| Gráfico de barras — histórico dos últimos 6 meses | ✅ |
| Histórico completo de transações com filtros | ✅ |
| Calendário de lançamentos por dia | ✅ |
| Modo Família — divisão de gastos compartilhados por pessoa | ✅ |
| Geração de relatório PDF familiar | ✅ |
| Exportar / importar dados em JSON | ✅ |
| Categorias customizáveis (nome + cor + ícone) | ✅ |
| Bancos/carteiras customizáveis (nome + cor) | ✅ |
| Temas claro e escuro | ✅ |
| Suporte a múltiplas moedas (BRL, USD, EUR etc.) | ✅ |
| Dados de exemplo na primeira abertura (seed automático) | ✅ |
| Ícone do app personalizado | ✅ |

---

## 🗂️ Estrutura do projeto

```
lib/
├── main.dart              # Inicialização: Hive, locale pt-BR, tema
├── app.dart               # Rotas (go_router) e MaterialApp
├── models/                # Entidades Hive (Transaction, Income, AppSettings)
├── screens/               # Telas principais
│   ├── dashboard_screen.dart
│   ├── transactions_screen.dart
│   ├── history_screen.dart
│   ├── calendar_screen.dart
│   └── settings_screen.dart
├── services/              # Lógica de negócio e acesso a dados
│   ├── database_service.dart   # CRUD Hive
│   ├── finance_calculator.dart # Cálculos financeiros e resumos
│   ├── pdf_service.dart        # Geração de PDF familiar
│   ├── import_service.dart     # Export / Import JSON
│   └── seed_service.dart       # Dados iniciais na 1ª abertura
├── widgets/               # Componentes reutilizáveis (cards, gráficos, forms)
├── theme/                 # Cores, tipografia e extensões de tema
└── utils/                 # Formatadores de moeda e data
```

---

## 🔧 Pré-requisitos

Antes de rodar o projeto, você precisa ter instalado:

- [Flutter SDK](https://docs.flutter.dev/get-started/install) **≥ 3.0.0**
- [Dart SDK](https://dart.dev/get-dart) **≥ 3.0.0** (já vem com o Flutter)
- [Android Studio](https://developer.android.com/studio) ou [VS Code](https://code.visualstudio.com/) com extensão Flutter
- Um emulador Android / iOS **ou** um dispositivo físico conectado

Verifique sua instalação:
```bash
flutter doctor
```

---

## 🚀 Como rodar o projeto

### 1. Clone o repositório
```bash
git clone https://github.com/jonasmoura247/konta-mobile.git
cd konta-mobile
```

### 2. Instale as dependências
```bash
flutter pub get
```

### 3. Gere os adaptadores Hive (code generation)
> Necessário apenas se você alterar os modelos (`Transaction`, `Income`, `AppSettings`).
```bash
dart run build_runner build --delete-conflicting-outputs
```

### 4. Rode o app
```bash
flutter run
```

---

## 📦 Principais dependências

| Pacote | Uso |
|---|---|
| `hive` + `hive_flutter` | Banco de dados local (NoSQL, sem servidor) |
| `flutter_riverpod` | Gerenciamento de estado |
| `go_router` | Navegação declarativa entre telas |
| `fl_chart` | Gráficos de pizza e barras |
| `pdf` + `printing` | Geração e compartilhamento de relatório PDF |
| `file_picker` | Seleção de arquivo JSON para importação |
| `share_plus` | Compartilhar PDF / JSON via sistema |
| `flutter_local_notifications` | Notificações locais |
| `intl` | Formatação de datas e moeda (pt-BR) |
| `path_provider` | Acesso a pastas do sistema (Downloads etc.) |
| `uuid` | Geração de IDs únicos para cada transação |

---

## 🏗️ Gerar APK / build de produção

```bash
# APK Android (release)
flutter build apk --release

# App Bundle (recomendado para Play Store)
flutter build appbundle --release
```

O APK ficará em: `build/app/outputs/flutter-apk/app-release.apk`

### Ícone do app
O ícone é gerado automaticamente via `flutter_launcher_icons`.  
Para reger após trocar a imagem em `assets/icons/icon_konta.png`:
```bash
dart run flutter_launcher_icons
```

---

## 🗃️ Modelo de dados

### Transaction
- **groupId**: `avista` | `parcelamento` | `assinatura`
- **categoryId**: referência à categoria (customizável)
- **bankId**: referência ao banco/carteira (customizável)
- **installments**: número de parcelas (1 = à vista)
- **familyMode**: indica se é um gasto compartilhado na visão família
- **cancelledFrom**: data de cancelamento de assinaturas

### Income
- Entradas financeiras com tipo, valor e mês de referência

### AppSettings
- **currency**: moeda padrão (`BRL`, `USD`, `EUR` etc.)
- **theme**: `dark` | `light`
- **familyMode**: ativa a visão família
- **familyCount**: número de pessoas na família
- **familyNames**: lista com o nome de cada membro

---

## 🛣️ Roadmap (ideias futuras)

- [ ] Metas de economia mensais
- [ ] Notificações de vencimento de parcelas
- [ ] Sincronização em nuvem (Firebase / Supabase)
- [ ] Widget de saldo na tela inicial do celular
- [ ] Exportação para planilha (CSV/Excel)
- [ ] Suporte a múltiplas carteiras com saldo real

---

## 🤝 Contribuindo

1. Faça um fork do repositório
2. Crie uma branch: `git checkout -b feature/minha-feature`
3. Commit suas alterações: `git commit -m 'feat: minha feature'`
4. Push: `git push origin feature/minha-feature`
5. Abra um Pull Request

---

<div align="center">
Feito com ❤️ em Flutter
</div>

