# DIY System

Aplicativo Flutter que começa apenas com a criação do administrador. Depois do login, um agente entrevista o usuário e constrói um sistema administrativo enquanto a conversa acontece.

A interface não executa código criado pela IA. O agente produz versões de um manifesto declarativo validado; o renderizador Flutter aplica cada versão imediatamente e preserva os dados locais.

## Plataformas

Um único código-base atende:

- Windows;
- Linux;
- macOS;
- Android;
- iOS e iPadOS.

Cada instalação mantém seus próprios dados. Sincronização entre aparelhos ainda não faz parte desta versão.

## O que funciona

- criação e login do administrador local;
- senha derivada com PBKDF2-HMAC-SHA256;
- conversa contínua com o agente;
- prévia atualizada depois de cada resposta;
- geração de telas e campos de cadastro;
- armazenamento de registros no diretório privado do aplicativo;
- backups automáticos antes de mudanças de manifesto;
- histórico local das últimas 500 ações;
- avaliação de 7 dias;
- licenças Ed25519 MINI e NORMAL por dispositivo;
- gateway Dart que mantém a chave da OpenAI fora dos aplicativos.

## Desenvolvimento

Requer Flutter 3.41 ou superior e Dart 3.11 ou superior.

```bash
flutter pub get
cp .env.example .env
```

Preencha `OPENAI_API_KEY` somente no `.env` da máquina que executará o gateway:

```bash
dart run bin/gateway.dart
```

Em outro terminal, execute o aplicativo:

```bash
flutter run -d macos --dart-define=DIY_GATEWAY_URL=http://127.0.0.1:8787
```

Troque `macos` por `windows`, `linux`, um emulador Android ou um simulador iOS. Em Android Emulator, o host da máquina normalmente é `10.0.2.2`. Builds distribuídos devem usar um gateway HTTPS.

## Builds

```bash
flutter build windows
flutter build linux
flutter build macos
flutter build appbundle
flutter build ipa
```

Windows deve ser compilado no Windows, Linux no Linux e iOS/macOS no macOS. Publicação final requer certificados e assinatura específicos de cada loja.

## Licenças

```bash
dart run tool/generate_licenses.dart
```

O comando cria 1.000 licenças MINI, 1.000 NORMAL e o inventário em `var/licenses/`. A chave privada permanece em `var/issuer/` e não deve ser publicada.

## Verificação

```bash
flutter analyze
flutter test
flutter build macos
```

Leia [ARCHITECTURE.md](./ARCHITECTURE.md) e [SECURITY.md](./SECURITY.md) antes de distribuir.
