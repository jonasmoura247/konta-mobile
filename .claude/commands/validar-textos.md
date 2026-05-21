---
description: Valida textos visíveis ao usuário em código Flutter, garantindo que todas as strings comecem com letra maiúscula
category: meta
---

Toda vez que uma tela ou widget é criado ou modificado, este comando valida que nenhum texto visível ao usuário escapa sem a primeira letra maiúscula — antes de encerrar a tarefa.

1. Leia `_CLAUDE.md` no vault raiz se existir
2. Identifique os arquivos Flutter criados ou modificados na conversa atual (telas, widgets, diálogos)
3. Escaneie todas as strings visíveis ao usuário nesses arquivos: labels, hints, tooltips, mensagens de erro, textos de botões, títulos, subtítulos, textos de estado vazio e qualquer `String` literal passada para widgets de texto
4. Para cada string encontrada, verifique se o primeiro caractere alfabético está em maiúsculo — ignore strings que sejam chaves internas, nomes de rota, IDs ou código não exibido ao usuário
5. Liste as ocorrências que não seguem o padrão (arquivo, linha, string atual → string corrigida) e aplique as correções diretamente nos arquivos
6. Confirme que todos os textos visíveis ao usuário agora começam com maiúscula antes de declarar a tarefa concluída

Garantir maiúscula inicial em todos os textos é um padrão de qualidade visual do app Konta — nenhuma tela deve ser entregue sem essa verificação.

---

**AI-first rule:** Every note created or updated by this command MUST follow `references/ai-first-rules.md` — `## For future Claude` preamble, rich frontmatter (`type`, `date`, `tags`, `ai-first: true`, plus type-specific fields), recency markers per external claim, mandatory `[[wikilinks]]` for every person/project/concept referenced, sources preserved verbatim with URLs inline, and confidence levels where applicable. The vault is for future-Claude retrieval — not human reading.
