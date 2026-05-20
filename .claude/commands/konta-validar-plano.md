---
description: Valida o resultado de um plano executado no Konta — verifica warnings/erros e compatibilidade Android 14
---

Você acabou de executar um plano no projeto Konta (Flutter/Android). Execute os seguintes passos de validação:

## 1. Análise estática completa

```bash
flutter analyze --no-pub 2>&1
```

- Se houver **errors** → corrija imediatamente (impedem build)
- Se houver **warnings** → corrija se forem do código que você escreveu (warnings pré-existentes em arquivos que não foram tocados podem ser ignorados)
- **infos** → corrija apenas se forem nos arquivos novos/modificados

## 2. Build de validação

```bash
flutter build apk --debug 2>&1 | tail -10
```

Confirme que o APK foi gerado sem erros.

## 3. Checklist Android 14 (API 34)

Para cada arquivo novo ou modificado, verifique:

**Permissões:**
- `READ_EXTERNAL_STORAGE` deve ter `android:maxSdkVersion="32"` (já não existe no API 33+)
- `POST_NOTIFICATIONS` deve estar no manifest (obrigatório a partir do API 33)
- `SCHEDULE_EXACT_ALARM` ou `USE_EXACT_ALARM` se usar alarmes exatos
- `WRITE_EXTERNAL_STORAGE` deve ter `android:maxSdkVersion="29"`

**Código Flutter:**
- Notificações: usar `AndroidScheduleMode.exactAllowWhileIdle` (não `exact`)
- Permissão de notificação: solicitar via `requestNotificationsPermission()` após o primeiro frame (não em `main()` direto)
- Storage: usar SAF (`ACTION_OPEN_DOCUMENT` / `ACTION_OPEN_DOCUMENT_TREE`) — não `File` direto em paths externos
- Foreground services: se usar, declarar `android:foregroundServiceType` no manifest

**SDKs (confirmar via `FlutterExtension.kt`):**
- Flutter SDK padrão: minSdk=24, targetSdk=36, compileSdk=36
- Android 14 (API 34) está dentro do range suportado ✓

**Código novo (Pure Dart/Flutter):**
- Se o código novo é 100% Dart sem chamadas nativas → sem riscos Android 14
- Widgets, services, models: nenhuma restrição adicional

## 4. Relatório final

Apresente um resumo no formato:

```
✅ analyze: N issues (0 errors, 0 warnings nos arquivos novos)
✅ build: APK gerado com sucesso
✅ Android 14: sem problemas encontrados

Arquivos criados/modificados:
- lib/... (NOVO)
- lib/... (MODIFICADO)
```

Se houver problemas, corrija e rode novamente antes de reportar sucesso.
