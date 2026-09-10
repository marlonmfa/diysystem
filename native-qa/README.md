# DIY System — Android e iOS

O projeto já possui aplicativo Flutter para ambas as plataformas, identificador `com.diysystem.app`, versão `0.1.0+1`. Esta validação cobre o armazenamento local e a aplicação de manifestos recebidos pelo gateway.

## Compilar

Na raiz, execute `flutter pub get`, `flutter test` e `flutter analyze`. Use `flutter build apk --release --target-platform android-arm64` para Android e `flutter build ios --simulator --debug` para iOS Simulator. O APK usa a assinatura de desenvolvimento já configurada no projeto. O ZIP de Simulator não é IPA para aparelho físico.

O gateway é definido em tempo de compilação por `--dart-define=DIY_GATEWAY_URL=https://seu-gateway`. O padrão existente é `http://127.0.0.1:8787`; para Android Emulator também é possível usar `10.0.2.2`. A política Android permite HTTP apenas nesses endereços locais e em localhost. Servidores externos devem usar HTTPS. A chave da IA permanece no gateway.

## Teste nativo

1. Instale os dois aplicativos nos respectivos emuladores/simuladores.
2. Na raiz, execute `node native-qa/gateway.mjs`. Esse servidor escuta exclusivamente em 127.0.0.1:8787 e responde com um manifesto fictício; não chama a IA nem acessa arquivos ou serviços externos.
3. Execute `adb reverse tcp:8787 tcp:8787` para o emulador Android.
4. Em `native-qa`, execute `npm ci`. Configure `DIY_NATIVE_ANDROID_DEVICE`, `DIY_NATIVE_IOS_DEVICE` e `DIY_MAESTRO_BIN`.
5. Execute `npx playwright test --project android` e `npx playwright test --project ios --output output/native-ios`. Use uma execução por plataforma; o fluxo iOS considera o teclado de hardware do simulador.
6. Interrompa o servidor local e remova o encaminhamento com `adb reverse --remove tcp:8787`.

Os testes criam somente administrador e cliente fictícios dentro do contêiner privado de cada aplicativo. Conferem criação do administrador, conversa, prévia, abertura do sistema, cadastro de cliente, histórico, saída e login após reiniciar. As capturas são copiadas para `../test-screenshots`; os registros não são sincronizados entre aparelhos. O teste unitário adicional também valida a remoção de campos não previstos no manifesto e a notificação da mudança de tela.

Licenças reais, chamadas à OpenAI e distribuição nas lojas não são exercitadas. Resultados e pacotes estão descritos em `NATIVE-QA.md`.
