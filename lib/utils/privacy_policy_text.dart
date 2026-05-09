const String kPrivacyPolicyVersion = '1.0';
const String kPrivacyPolicyDate = 'Maio de 2026';

const String kPrivacyPolicyText = '''
POLÍTICA DE PRIVACIDADE DO KONTA
Versão $kPrivacyPolicyVersion — $kPrivacyPolicyDate

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. O QUE É O KONTA

O Konta é um aplicativo mobile de controle financeiro pessoal e familiar, disponível para Android. Ele permite registrar gastos, receitas, assinaturas, parcelamentos, reservas, metas e lembretes, além de oferecer recursos de controle financeiro em família.

O Konta funciona 100% offline. Todos os dados ficam armazenados localmente no próprio dispositivo do usuário. O aplicativo não depende de internet para funcionar.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

2. QUAIS DADOS SÃO ARMAZENADOS

O Konta pode armazenar apenas dados inseridos manualmente pelo usuário. Nenhum dado é coletado automaticamente pelo aplicativo.

Dados financeiros:
• Gastos e lançamentos (valores, datas, descrições, categorias e cartões/bancos associados)
• Entradas e receitas
• Assinaturas, parcelamentos e débitos
• Reservas financeiras e seu histórico de valores
• Metas financeiras

Dados de organização:
• Categorias personalizadas e bancos/cartões personalizados
• Preferências de moeda, tema e exibição
• Configuração de saldo acumulado entre meses

Dados do Modo Família:
• Ativação do modo família e número de membros
• Nomes dos membros informados pelo usuário
• Marcação de gastos familiares e nome do membro associado

Dados de lembretes:
• Data, horário e descrição dos lembretes
• Categoria ou banco associado ao lembrete, quando informado

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

3. ONDE OS DADOS FICAM

Todos os dados do Konta ficam armazenados localmente no dispositivo do usuário, usando o banco de dados Hive. Os dados não são enviados para nenhum servidor externo, nem sincronizados automaticamente com serviços de nuvem.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

4. COMO OS DADOS SÃO USADOS

Os dados armazenados no Konta são usados exclusivamente para:
• Exibir resumos financeiros mensais e anuais
• Calcular saldos, totais por categoria e evolução de reservas
• Gerar gráficos e relatórios dentro do aplicativo
• Agendar lembretes no sistema operacional do dispositivo

O Konta não usa os dados para fins publicitários, análises de comportamento ou qualquer outra finalidade além do controle financeiro do próprio usuário.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

5. O KONTA NÃO ENVIA SEUS DADOS

• O Konta não possui sincronização automática em nuvem.
• O Konta não envia dados financeiros para servidores próprios ou de terceiros.
• O Konta não vende dados pessoais.
• O Konta não compartilha dados automaticamente com nenhum serviço externo.
• O aplicativo funciona completamente offline, sem necessidade de conexão com a internet.

Quando o usuário exporta arquivos, gera PDFs ou compartilha informações por outros aplicativos, esse compartilhamento acontece por escolha exclusiva do próprio usuário.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

6. BACKUP, IMPORTAÇÃO E EXPORTAÇÃO

Exportação:
O usuário pode exportar um arquivo .json com seus dados financeiros. O arquivo é salvo localmente no dispositivo, na pasta Downloads ou em local escolhido pelo usuário. O arquivo exportado pode conter transações e entradas no formato konta_backup_AAAAMMDD.json.

Importação:
O usuário pode importar arquivos .json gerados pelo Konta. Os dados importados são somados aos dados já existentes no dispositivo. Importar o mesmo arquivo mais de uma vez pode gerar dados duplicados.

Limitações atuais:
• Reservas, metas e lembretes não são incluídos no arquivo de exportação JSON.
• Não existe backup automático em nuvem.
• A troca de dispositivo depende de exportação e importação manual pelo usuário.

Responsabilidade do usuário:
Se o usuário salvar o backup em Google Drive, e-mail, WhatsApp ou outro serviço externo, o tratamento desses dados passa a depender também das políticas de privacidade desses serviços.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

7. MODO FAMÍLIA E PDFs

O Modo Família permite dividir gastos entre membros da família. Os nomes dos membros ficam salvos apenas localmente no dispositivo.

O aplicativo pode gerar um PDF com resumo financeiro familiar contendo: mês de referência, nomes dos membros, totais, categorias, bancos, descrições das transações, responsável pelo gasto, valor total e valor por pessoa.

O PDF é gerado por ação direta do usuário. O compartilhamento do PDF é manual e feito pelos aplicativos escolhidos pelo próprio usuário.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

8. NOTIFICAÇÕES E PERMISSÕES

Permissões de notificação:
O Konta usa notificações locais para lembretes agendados pelo usuário no calendário. As notificações são processadas diretamente no sistema operacional do dispositivo, sem envio de dados por servidor.

• No Android: podem ser usadas permissões para alarmes exatos e reagendamento após reinicialização do dispositivo.

Permissões de arquivos:
• O app pode abrir o seletor de arquivos para que o usuário escolha um arquivo JSON para importação.
• O app pode salvar arquivos JSON exportados na pasta Downloads do dispositivo.
• O usuário decide manualmente quando importar ou exportar dados.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

9. COMPARTILHAMENTO DE DADOS

O Konta não compartilha dados com terceiros de forma automática. O único compartilhamento possível ocorre quando o usuário, voluntariamente:
• Exporta um arquivo JSON e o envia para outros serviços ou pessoas.
• Gera e compartilha um PDF do Modo Família.
• Salva arquivos em serviços de armazenamento externo de sua escolha.

Nesses casos, a responsabilidade pelo tratamento dos dados passa a ser compartilhada com os serviços externos utilizados pelo usuário.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

10. EXCLUSÃO DOS DADOS

O usuário pode apagar seus dados diretamente pelo aplicativo, na tela de Configurações > "Limpar todos os dados". Esta ação é irreversível e remove todas as transações, entradas, reservas, metas, lembretes e configurações do dispositivo.

Importante:
• Se o usuário desinstalar o Konta sem fazer backup, os dados locais serão perdidos permanentemente.
• Recomendamos exportar os dados antes de limpar ou trocar de aparelho.
• A exclusão completa dos dados também revoga o registro de aceite desta Política, e o aceite será solicitado novamente na próxima instalação.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

11. SEGURANÇA

Os dados do Konta ficam no armazenamento interno do dispositivo, protegidos pelos mecanismos de segurança do próprio sistema operacional. O aplicativo não implementa criptografia adicional nos dados locais.

Recomendamos manter o dispositivo com senha, PIN ou biometria ativados para proteger o acesso ao aplicativo e aos dados armazenados.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

12. DIREITOS DO USUÁRIO

Em conformidade com a Lei Geral de Proteção de Dados (LGPD — Lei nº 13.709/2018), o usuário tem direito a:

• Saber quais dados são tratados pelo aplicativo (descrito nesta Política).
• Corrigir dados inseridos, editando ou excluindo registros diretamente no app.
• Excluir todos os dados usando a opção "Limpar todos os dados" nas Configurações.
• Exportar seus dados quando a funcionalidade estiver disponível.
• Revogar permissões do sistema operacional (notificações, acesso a arquivos) nas configurações do dispositivo.

Como os dados ficam no próprio dispositivo do usuário, a maioria desses direitos pode ser exercida diretamente dentro do aplicativo, sem necessidade de contato com o desenvolvedor.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

13. ALTERAÇÕES NESTA POLÍTICA

Esta Política de Privacidade pode ser atualizada para refletir mudanças no aplicativo ou em requisitos legais. Quando houver mudanças relevantes, o Konta solicitará um novo aceite do usuário ao abrir o aplicativo.

O usuário pode consultar a versão atual desta Política a qualquer momento em Configurações > Política de Privacidade.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

14. CONTATO

Em caso de dúvidas sobre esta Política de Privacidade ou sobre o tratamento dos seus dados no Konta, entre em contato:

E-mail: jonas.emanuel.moura@gmail.com

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Versão $kPrivacyPolicyVersion — $kPrivacyPolicyDate
''';
