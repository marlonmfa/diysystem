# Arquitetura do DIY System

## Princípio central

O produto é uma oficina de sistemas orientada por conversa. Ele separa quatro responsabilidades:

1. **shell Flutter confiável** — autenticação, persistência, backups, auditoria e renderização;
2. **manifesto evolutivo** — nome, propósito, telas e campos gerados pelo agente;
3. **armazenamento local** — estado e registros no contêiner privado de cada instalação;
4. **gateway Dart** — trial, licenças, escolha do modelo e chamadas à OpenAI.

```text
Windows / Linux / macOS / Android / iOS
┌─────────────────────────────────────────────┐
│ administrador → conversa → prévia ao vivo   │
│                 │                           │
│                 ▼                           │
│        manifesto validado + registros       │
│                 │                           │
│          arquivos privados locais           │
└─────────────────┬───────────────────────────┘
                  │ HTTPS
                  ▼
┌─────────────────────────────────────────────┐
│ gateway Dart → trial/licença → OpenAI       │
└─────────────────────────────────────────────┘
```

## Construção em tempo real

Depois de cada resposta, o gateway envia ao modelo a conversa e o manifesto corrente. A saída estruturada contém:

- a próxima pergunta do agente;
- o estado de prontidão da entrevista;
- uma nova revisão completa do manifesto.

O aplicativo valida a revisão, salva um backup, persiste a nova versão e reconstrói a prévia com Flutter. Isso produz a experiência de hot reload sem executar código baixado.

## Dados locais

O estado é gravado atomicamente como JSON no diretório de suporte privado fornecido por cada sistema operacional. Ele contém:

- identificador e datas da instalação;
- credencial derivada do administrador;
- conversa e manifesto corrente;
- registros criados nas telas;
- licença e histórico administrativo.

Os manifestos anteriores ficam em `backups/` dentro do mesmo contêiner. Os dados não são sincronizados entre instalações nesta versão.

## Evolução prevista

1. SQLite com migrações e criptografia seletiva;
2. edição, exclusão, filtros, relações e relatórios;
3. sincronização opcional entre aparelhos;
4. recuperação segura da conta administrativa;
5. serviço transacional de licenças e revogação;
6. testes de integração em todas as plataformas;
7. assinatura e publicação nas lojas.
