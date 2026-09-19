# Preparação AWS — diysystem

Data: 2026-09-12. Estado: configuração local preparada; migração não executada.

Conta de destino indicada: `541259832355`. Critério: web/README.md: diy.hirableaiagents.com

Credenciais: `.env` local, permissão 0600, fora do Git. Incluídos os nomes fornecidos e o alias `AWS_ACCESS_KEY_ID` usado por SDKs. Identidades não consultadas na AWS. Nenhuma região foi escolhida. Variáveis AWS de identidade foram atualizadas; demais variáveis existentes foram preservadas. Arquivos `.env.local`, `.env.production` e ambientes de serviços não foram alterados; precedência e credenciais desses ambientes precisam ser conferidas antes de qualquer execução.

## Evidências locais

- web/README.md: diy.hirableaiagents.com

## Pendências antes de uma proposta de migração

- Confirmar vínculo e conta, sobretudo quando a classificação é residual ou baseada em referência compartilhada.
- Identificar implantação ativa, componentes, bancos, volumes, uploads, tarefas, integrações, domínios e dependências.
- Conferir configurações e planos anteriores; não representam decisões novas nesta preparação.
- Levantar requisitos de disponibilidade, região, orçamento, backup, restauração e interrupção tolerada.
- Elaborar proposta de serviços, infraestrutura como código, sequência, validação e rollback somente após as decisões do usuário.
- Executar migração apenas com autorização posterior. Não executar scripts de deploy ou CI/CD como parte desta preparação.

Planejamento consolidado: `/Users/marlonalcantara/Repos/aws-migration-dkm/README.md`.
