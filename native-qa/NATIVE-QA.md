# DIY System — validação nativa em 10/09/2026

Aplicativo Flutter existente, `com.diysystem.app`, versão `0.1.0+1`, corrigido e compilado para Android e iOS. Código testado: `6e4896b`.

**PASS:** oito testes unitários, análise Flutter sem ocorrências, APK Release e aplicativo iOS Debug para Simulator. Integrações finais: Android 1,6 minuto; iOS 1,1 minuto. O fluxo cria administrador fictício, conversa com o gateway local determinístico, confere a prévia, abre o sistema, salva um cliente, consulta o histórico, sai, reinicia e entra novamente, recuperando o registro.

A integração encontrou uma falha real: abrir o sistema ou a área administrativa alterava a fase sem notificar a interface quando não havia erro anterior. A notificação foi corrigida e incluída no teste de regressão. O celular também recebeu botão Sair, cabeçalho com espaço para os nomes e prévia com campos legíveis em uma coluna. A política Android permite HTTP somente em localhost, 127.0.0.1 e 10.0.2.2, preservando HTTPS para servidores externos. O lockfile atualizou duas dependências de teste exigidas pelo SDK instalado.

16 capturas commitadas e examinadas após os commits: **PASS** — início, administrador, conversa, prévia, formulário, registro, histórico e persistência legíveis nos dois sistemas. iOS `83d2c6f`; Android `9892be1`. O roteiro considera os rótulos de acessibilidade completos das abas e o teclado do simulador iOS. O formulário iOS também demonstra o botão Salvar acessível com o teclado aberto.

A leitura do contêiner privado iOS confirmou um cliente fictício, revisão 1 do manifesto, senha derivada e eventos de criação, saída e login. O Android comprovou a persistência pela interface após reiniciar. O gateway de teste escutou apenas em loopback; nenhuma IA, serviço de licenças ou comunicação externa foi chamada.

Pacotes e hashes em `output/mobile-qa-2026-09-10/manifest.json`: `diysystem-android-qa.apk` e `diysystem-ios-simulator.zip`. Seis binários iOS verificados como IOSSIMULATOR. Android usa a assinatura de desenvolvimento existente. O gateway mantém o padrão configurável em compilação `http://127.0.0.1:8787`; para uso externo, recompilar com o endereço HTTPS do gateway real. Não são pacotes publicados em loja nem IPA para aparelho físico.

Dos 151 arquivos originais, cinco foram alterados conforme descrito; os outros 146 e os arquivos privados conservaram os hashes. Licença assinada real, chamada à OpenAI, evolução sucessiva de manifestos, sincronização entre aparelhos e distribuição em lojas não foram exercitadas nesta integração. A aplicação continua com dados independentes por aparelho, como previsto em sua arquitetura.
