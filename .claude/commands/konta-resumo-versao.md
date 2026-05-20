---
description: Cria o resumo de versão para a pasta resumo-versoes após implementar um plano do Konta
---

Você acabou de implementar um plano do Konta. Crie o resumo da versão seguindo estes passos:

## 1. Identificar a versão

- Leia o plano executado para encontrar o campo `Versão alvo:` (ex: `v1.2.0`)
- Verifique os arquivos já existentes em `C:\Users\Jonas\Desktop\Anotacoes\Konta\resumo-versoes\` para não duplicar
- O número do arquivo segue o padrão: `X.Y.Z-resumo.md`

## 2. Identificar o plano

- O nome do plano está no arquivo em `C:\Users\Jonas\Desktop\Anotacoes\Konta\Plano\` (ex: `3-INSIGHTS.md`)
- Use o link relativo: `[N-NOME.md](../Plano/N-NOME.md)`

## 3. Escrever o resumo

Use o template abaixo, preenchendo com base no que foi implementado nesta sessão:

```markdown
# Konta vX.Y.Z — [Título curto e descritivo]

> **Data:** DD/MM/AAAA  
> **Plano:** [N-NOME.md](../Plano/N-NOME.md)

---

## O que chegou nesta versão

### [Funcionalidade Principal]
- [bullet: o que o usuário vê/faz — perspectiva de produto, não técnica]
- [bullet: ...]

### [Funcionalidade Secundária, se houver]
- [bullet: ...]

### Correções incluídas (se houver)
- [bug] → [o que foi corrigido]

---

## Notas técnicas
- [Novos arquivos criados e responsabilidade]
- [Novos modelos Hive com typeId, se houver]
- [Padrões arquiteturais relevantes]
- [Próximo typeId disponível, se houver novos modelos Hive]
```

**Regras:**
- Bullets de funcionalidade: perspectiva do usuário ("O usuário vê X", "Ao tocar Y acontece Z")
- Notas técnicas: perspectiva do desenvolvedor (arquivos, patterns, typeIds)
- Data: hoje no formato DD/MM/AAAA
- Título: curto, descritivo, sem redundância com o número de versão

## 4. Salvar o arquivo

Salve em: `C:\Users\Jonas\Desktop\Anotacoes\Konta\resumo-versoes\X.Y.Z-resumo.md`

## 5. Confirmar

Informe: "Resumo v X.Y.Z criado em `resumo-versoes/X.Y.Z-resumo.md`"
