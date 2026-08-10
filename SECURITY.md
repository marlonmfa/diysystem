# Segurança

## Fronteira da IA

O agente altera apenas manifestos declarativos validados. Ele não recebe shell, não escreve código executável, não instala dependências e não acessa diretamente os arquivos do aparelho.

O aplicativo aplica uma mudança somente quando:

1. a resposta segue o esquema esperado;
2. a revisão é exatamente a revisão atual mais um;
3. todos os identificadores e limites são válidos;
4. um backup da versão anterior foi concluído.

## Chave da OpenAI

A chave fica exclusivamente no gateway Dart e é carregada de `OPENAI_API_KEY`. Os aplicativos recebem apenas o endereço público HTTPS do gateway durante o build.

Em produção, use uma chave de projeto dedicada, limites de consumo, alertas e logs sem conteúdo pessoal desnecessário.

## Administração e dados locais

- A senha administrativa é derivada com PBKDF2-HMAC-SHA256, salt aleatório e 120.000 iterações.
- O estado é gravado atomicamente no diretório privado do aplicativo.
- Licenças são verificadas com assinaturas Ed25519.
- O gateway associa cada licença ao número permitido de instalações.
- Segredos do emissor e inventários de licença são ignorados pelo Git.

## Limites conhecidos

- Os registros locais ainda não são criptografados em repouso.
- Um administrador completo do aparelho pode adulterar ou apagar os arquivos locais.
- O gateway usa um arquivo JSON e não deve ser escalado para múltiplas instâncias.
- Não existe recuperação de senha nem sincronização entre aparelhos.
- A distribuição ainda precisa de assinatura, notarização e configuração nas lojas.
