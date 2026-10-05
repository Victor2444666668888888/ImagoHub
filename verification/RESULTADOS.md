# Ajustes de perfil, cadastro e busca — 01/10/2026

## Alterações

- Configurações seguidas pelo perfil, sem botões Perfil/Preferências e sem repetir as configurações.
- Nome de usuário no cadastro e no perfil, sem exigir @ ou um padrão de letras. Persistência no servidor e migração do banco anterior preservando as contas.
- Senha e confirmação sempre editáveis, botões para limpar, regra de oito caracteres visível antes do envio e bloqueio de envios duplicados.
- Busca inicialmente vazia: natureza, verde, 1200 e 1600 são exemplos dos campos. Limpar filtros também limpa os valores guardados no estado.
- Seletor de cor na bolinha; cor da bolinha acompanha a escolha ou o nome digitado. Seleção Qualquer cor remove o filtro.
- Oito categorias clicáveis na página inicial. As categorias utilizam termos em inglês para a consulta à API e mantêm os rótulos em português.

## Verificação atual

- **12 testes da API aprovados**, incluindo nomes de usuário com espaços/acentos/símbolos, persistência, correção de senha rejeitada e migração de um banco de contas anterior. Log: `server-tests.log`.
- **47 verificações do código Dart de estado/API/modelos aprovadas** contra o serviço Python real em banco temporário. Log: `ajustes-flow-smoke.log`. As respostas de fotos são controladas nesse teste; não é uma nova verificação de resultados ao vivo da Unsplash.
- Os adaptadores desse teste substituem apenas pacotes de plataforma indisponíveis (notificações/assets, preferências, armazenamento e transporte HTTP). A lógica do estado, modelos, cliente API e autenticação vem dos arquivos reais do projeto.
- Parser/formatador Dart executado nos arquivos alterados; servidor Python compilado e JSON/configuração do projeto validados.
- Testes Flutter atualizados para apagar/corrigir uma senha curta, preencher o nome de usuário, escolher/digitar cor, limpar campos e navegar por categorias.
- A execução da suíte Flutter foi tentada, mas falhou na resolução das dependências ausentes. **Os novos testes de widgets e um novo build completo ainda não foram executados com sucesso neste ambiente.** As capturas históricas não mostram estes ajustes.

As referências técnicas para o filtro de cor e edição de campos são a documentação oficial da Unsplash (https://unsplash.com/documentation#search-photos) e do Flutter (https://api.flutter.dev/flutter/material/TextField/enabled.html).

Para conferir no computador com as dependências instaladas:

```bash
flutter pub get
flutter analyze
flutter test --dart-define=REFERENCE_MODE=true
python -m unittest discover -s server/tests -v
```

Encerre o aplicativo e a API antes de copiar a atualização. Preserve `server/data` para manter as contas, e reinicie a API para aplicar a migração.

## Histórico anterior

# Atualização do fluxo de conta — 01/10/2026

O aplicativo inicia no login. Cadastro concluído faz login automaticamente e abre a galeria. Perfil/configurações, imagens, favoritos e pastas só ficam disponíveis com uma conta autenticada. Logout volta ao login e limpa os dados da conta exibidos. Sessões lembradas são verificadas antes de mostrar a galeria.

## Verificação desta mudança

- **26 verificações aprovadas** executando o código Dart real de `AppState`, `ApiClient` e modelos contra o serviço Python real, em banco temporário. Log: `auth-flow-smoke.log`.
- Cobertura: início no login, bloqueio das oito rotas privadas, cadastro acessível, bloqueio de busca/foto/perfil antes de entrar, ausência de perfil visitante, cadastro e entrada automática, perfil da conta criada, logout, senha incorreta, login válido, biblioteca separada, sessão lembrada válida/inválida e resposta de perfil atrasada após logout.
- Nessa execução, os pacotes de plataforma ausentes foram substituídos por adaptadores de teste: notificações/assets, armazenamento em memória e transporte HTTP baseado em `dart:io`. A lógica do aplicativo e os endpoints usados foram os arquivos reais, sem copiar ou reimplementar as decisões de autenticação.
- Os arquivos Dart alterados passaram pelo formatador/parser do SDK. Os testes normais Flutter foram atualizados com o novo fluxo e um teste de interface para o bloqueio do perfil.
- Não foi possível executar a suíte de widgets, a análise completa ou um novo build web nesta atualização: as dependências Flutter continuam ausentes no cache, e a tentativa de execução ficou bloqueada na resolução de pacotes. Este ZIP contém o código atualizado, não um build novo validado.
- Capturas em `rendered-versao-anterior/` e `ImagoHub-previa-anterior.png` são anteriores à alteração. A suíte Flutter gera novas capturas em `rendered/` quando executada com as dependências disponíveis.

Para validar no computador:

```bash
flutter pub get
flutter analyze
flutter test --dart-define=REFERENCE_MODE=true
flutter build web --release --dart-define=API_BASE_URL=http://127.0.0.1:8787
```

## Histórico da versão anterior

### Verificação anterior

## Executado

| Verificação | Resultado |
|---|---|
| Projeto Flutter | Criado com Flutter 3.47.5 e Dart 3.13.4. |
| Dependências | `flutter pub get` executado com sucesso antes da indisponibilidade do cache. `pubspec.lock` incluído. |
| Web release | Compilação concluída com sucesso (`build/web`). Esse build antecede os últimos ajustes pequenos de filtros e avisos. O ZIP contém o código-fonte atualizado. |
| API Unsplash real | Busca por nature/green/portrait retornou 2.120 resultados, com quatro fotos na página solicitada. |
| API e autenticação | 9 testes HTTP aprovados na execução final: cadastro, hash de senha, duplicidade, login, sessão, perfil, recuperação, CORS, filtros e cache. Log em `server-tests.log`. |
| Estado Flutter | 6 testes aprovados: filtros/paginação, dimensões/ixid, respostas atrasadas, pastas/persistência, favoritos offline, contas separadas e perfil/preferências. |
| Widgets Flutter | Busca → resultados → detalhes → voltar, cadastro/login, layouts 320/390/1440 px e captura das telas aprovados na última execução completa. |
| Verificação visual | 11 capturas de telas mobile e uma captura desktop de widgets Flutter reais, em `rendered/`. Montagem em `ImagoHub-previa.png`. Sem as anotações laterais do wireframe. |
| Python e configuração | Scripts Python compilados; JSON de assets, VS Code e manifesto validado. |
| Access Key | Configurada somente na API. Verificado que não aparece no código/asset cliente nem no build web. |

## Limites da última verificação

A última execução completa do Flutter terminou com **12 de 13 testes aprovados**. O teste de criar/adicionar/remover em uma pasta tentou clicar enquanto o aviso temporário estava sobre o cartão. O teste foi ajustado para aguardar o aviso desaparecer. Não foi possível repetir a suíte final nem a análise final: os pacotes do cache local deixaram de estar disponíveis, e o acesso ao registro de pacotes não respondeu neste ambiente. Essa correção do teste está incluída, mas não é marcada como aprovada.

A análise inicial de Dart não encontrou erros de compilação; os avisos de estilo observados foram corrigidos. Não se afirma uma nova análise completa após a indisponibilidade das dependências.

Windows, Android e iOS têm os projetos e configurações preparados, mas não foram compilados aqui: faltam as ferramentas nativas dessas plataformas. Não há EXE/APK/IPA neste pacote.

## Reproduzir no computador com o Flutter instalado

```bash
flutter pub get
flutter analyze
flutter test --dart-define=REFERENCE_MODE=true
python -m unittest discover -s server/tests -v
flutter build web --release --dart-define=API_BASE_URL=http://127.0.0.1:8787
```

Use `LEIA-ME.md` para iniciar a API, abrir no VS Code e configurar celular/Windows ou uma API HTTPS em produção.
