# ImagoHub em Flutter

Projeto com as **11 telas do seu SVG**, feitas com widgets do Flutter e conectadas entre si. A barra preta, o roxo, a fonte Inter, a logo IH e as fotografias da referência foram preservados. As explicações de endpoints não aparecem no aplicativo.

## Atualizar uma instalação existente

Encerre o aplicativo e a API. Extraia os arquivos deste ZIP sobre a pasta anterior. Mantenha `server/data` para preservar contas já criadas; a pasta de dados não é incluída no ZIP. Depois abra o workspace e execute novamente. Favoritos e perfil existentes continuam associados à conta no dispositivo.

## Executar no VS Code

1. Extraia o ZIP inteiro.
2. Abra **ImagoHub.code-workspace** no VS Code, ou abra a pasta que contém `pubspec.yaml`.
3. Instale as extensões recomendadas **Flutter**, **Dart** e **Python**.
4. Em **Executar e depurar**, escolha **ImagoHub · Chrome** e pressione **F5**. A tarefa prepara as dependências e inicia a API automaticamente.

Outra opção é abrir **Iniciar-Chrome.bat**, ou executar no terminal:

```bash
python scripts/run.py --device chrome
```

É preciso ter **Flutter estável 3.47.5 ou mais recente**, **Python 3.11+** e Chrome instalados. Instalação do Flutter: https://docs.flutter.dev/install. Confira o ambiente com `flutter doctor`. A API Python usa apenas a biblioteca padrão: não precisa de pip.

## Telas e funcionalidades

| Tela | O que funciona |
|---|---|
| 01 · Descubra | Categorias clicáveis (Natureza, Paisagens, Animais, Carros, Praias, Arquitetura, Tecnologia e Pessoas), fotos da referência, populares/recentes, rolagem, carregar mais, atualizar, abrir foto e favoritar. |
| 02 · Busca | Campos inicialmente vazios, exemplos, Livre/3:4/4:3/1:1, pixels opcionais, cor digitada ou escolhida na bolinha, limpar filtros e buscas recentes. |
| 03 · Resultados | Busca real, paginação com filtros preservados, relevância/recentes, detalhes e favoritos. |
| 04 · Detalhes | Foto, descrição, fotógrafo, créditos clicáveis, dimensões, tamanho para baixar, JPG e adicionar à pasta. |
| 05 · Favoritos | Salvar/remover favorito, seleção múltipla, selecionar todas, cancelar e adicionar à pasta. |
| 06 · Minhas pastas | Criar, listar, prévias, contagem e abrir pasta. |
| 07 · Pasta aberta | Adicionar imagens, selecionar, remover, renomear e excluir pasta. |
| 08 · Nova pasta | Painel inferior, formulário, nomes únicos, criar e cancelar. |
| 09 · Configurações/Perfil | Tema claro/escuro, economia de dados, busca segura, biblioteca, avatar, nome, usuário, e-mail, biografia, salvar e cancelar. |
| 10 · Login | E-mail/senha, mostrar senha, lembrar sessão, recuperação, erros e link para cadastro. |
| 11 · Cadastro | Nome, nome de usuário livre, e-mail, senha editável com opção de limpar, confirmação, validação, conta persistente e entrada automática na galeria. |

Ao abrir, o aplicativo mostra **Entrar na sua conta**, com acesso a **Criar conta**. Cadastro concluído ou login válido abre a galeria. Perfil e configurações ficam disponíveis depois da autenticação. Contas novas começam com sua biblioteca vazia; favoritos, pastas e perfil ficam separados por conta neste dispositivo. As estrelas e contagens refletem o estado real dos dados.

Uma sessão lembrada é validada antes de mostrar a galeria. Se não for válida, o aplicativo abre o login. **Sair da conta** volta ao login e retira os dados do perfil da tela.

No celular, o desenho segue a referência de 390 px e a barra de 54 px. Telas longas têm rolagem. No desktop, a galeria usa várias colunas. **Ctrl+F** abre a busca; **Esc** volta da foto/pasta. Depois de entrar, toque na logo para abrir seu perfil. Login/cadastro não têm botão para acessar a galeria ou as configurações sem autenticação.

## API da Unsplash

`server/.env` já contém a **Access Key fornecida para este projeto**. Ela fica na API local, fora do código compilado do Flutter. A Secret Key não é utilizada. Para mudar a chave, edite `UNSPLASH_ACCESS_KEY` e reinicie a API. Há um modelo em `server/.env.example`.

| Recurso | Endpoint |
|---|---|
| Populares/recentes e paginação | GET /photos |
| Buscar com filtros | GET /search/photos |
| Dados completos da foto | GET /photos/:id |
| Registrar download/uso ao salvar | GET /photos/:id/download |

As imagens usam diretamente as URLs da Unsplash. Créditos levam ao fotógrafo e à Unsplash. Favoritos/pastas são locais, sem endpoints de coleções.

O formato filtra a **orientação**. Dimensões exatas são aplicadas à URL com `w`, `h` e `fit=crop`, preservando `ixid`. Isso permite baixar um JPG de **1200 × 1600 px**, por exemplo. Preencha as duas dimensões juntas, entre 1 e 8192 px.

Cores: preto e branco, preto, branco, amarelo, laranja, vermelho, roxo, magenta, verde, verde-azulado e azul. Equivalentes em inglês também funcionam. Toque na bolinha para abrir a paleta. A escolha preenche o nome e atualiza a bolinha; digitar uma cor também atualiza seu aspecto. **Qualquer cor** remove o filtro. Os exemplos dos campos não são enviados como valores.

As categorias usam `/search/photos`; os nomes comuns em português são convertidos em termos equivalentes em inglês na consulta. A interface mantém o texto em português, e frases livres permanecem como foram digitadas.

Erros de conexão, fotos removidas, busca vazia e limite de requisições mostram mensagens e permitem tentar novamente. A busca não inventa resultados quando a API falha. As fotos da referência estão incluídas como fallback da galeria inicial.

## Login, perfil e recuperação

As contas persistem em `server/data/accounts.sqlite3`. Senhas usam salt e scrypt. No navegador, a sessão usa cookie HttpOnly. No aplicativo nativo, “Lembrar de mim” usa o armazenamento seguro do sistema.

Nome, e-mail e nome de usuário são salvos na conta do servidor. O nome de usuário aceita espaços, acentos e símbolos, sem exigir @ ou um padrão; pode ter até 100 caracteres. Avatar e biografia continuam locais. A atualização da API adiciona a coluna de nome de usuário ao banco existente sem apagar contas ou senhas.

Configurações aparecem primeiro, seguidas pelo formulário de perfil, sem abas ou preferências duplicadas.

A senha precisa ter pelo menos 8 caracteres. O cadastro informa essa regra antes de salvar. Os campos continuam editáveis e têm botões para limpar senha/confirmar senha, inclusive após uma validação recusada.

No modo local `APP_ENV=development`, a recuperação apresenta um código na janela e permite redefinir a senha. Não afirma que enviou e-mail. Em `APP_ENV=production`, configure SMTP em `server/.env` para enviar o código por e-mail. Códigos expiram em 30 minutos, só funcionam uma vez e invalidam as sessões anteriores.

## Windows

Instale o **Visual Studio** com **Desktop development with C++**, além do VS Code. Orientações: https://docs.flutter.dev/platform-integration/windows/building.

Escolha **ImagoHub · Windows** no VS Code, abra **Iniciar-Windows.bat**, ou:

```bash
python scripts/run.py --device windows
```

Para gerar no Windows:

```bash
flutter build windows --release --dart-define=API_BASE_URL=http://127.0.0.1:8787
```

A API precisa estar em execução para busca e contas. Ao distribuir, use a pasta completa de `build/windows/x64/runner/Release`, com DLLs e `data`.

## Android

Instale o Android SDK/Android Studio e abra um emulador. Selecione o emulador na barra inferior do VS Code e execute **ImagoHub · emulador Android**. Ele acessa a API do computador em `http://10.0.2.2:8787`.

Ou use dois terminais:

```bash
python server/server.py
```

```bash
flutter run -d ID_DO_EMULADOR --dart-define=API_BASE_URL=http://10.0.2.2:8787
```

Veja os IDs com `flutter devices`. O manifesto de debug permite HTTP para a API local. Aplicativos de release devem usar API HTTPS.

## Celular físico

O celular precisa alcançar a API: `127.0.0.1` no celular aponta para o próprio celular.

Para um teste na mesma rede, em `server/.env`:

```dotenv
APP_ENV=production
HOST=0.0.0.0
ALLOWED_ORIGINS=http://IP_DO_COMPUTADOR:8080
```

Inicie `python server/server.py` e permita a porta 8787 no firewall do computador. Android conectado por USB:

```bash
flutter run -d ID_DO_CELULAR --dart-define=API_BASE_URL=http://IP_DO_COMPUTADOR:8787
```

Para abrir o site no navegador do celular:

```bash
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080 --dart-define=API_BASE_URL=http://IP_DO_COMPUTADOR:8787
```

Abra `http://IP_DO_COMPUTADOR:8080` no celular. Busca, contas e biblioteca local funcionam; lembrar sessão web em produção requer HTTPS. SMTP é necessário para recuperação por e-mail nesse modo.

Os arquivos iOS também estão preparados. Gerar para iPhone exige macOS/Xcode.

## Publicar a versão web

Use uma API acessível por HTTPS. Configure `ALLOWED_ORIGINS` com a origem do site e gere:

```bash
flutter build web --release --dart-define=API_BASE_URL=https://sua-api.exemplo.com
```

`build/web` é o site estático. A API Python deve ser hospedada separadamente atrás de HTTPS. `server/.env` é configuração privada do servidor.

## Verificação

```bash
flutter analyze
flutter test --dart-define=REFERENCE_MODE=true
python -m unittest discover -s server/tests -v
```

`REFERENCE_MODE` é só para testes visuais: mostra os assets exatos sem depender da rede. A execução normal usa as URLs de imagem da Unsplash.

Os testes cobrem busca/paginação, respostas atrasadas, dimensões/ixid, persistência, bibliotecas separadas, navegação, seleção múltipla, criação/remoção em pastas, cadastro, login real, recuperação e layout em 320/390/1440 px. Novas capturas dos widgets são geradas em `verification/rendered`. As capturas anteriores à mudança de login ficam em `verification/rendered-versao-anterior`. Os resultados estão em `verification/RESULTADOS.md`.

Windows/Android/iOS precisam das ferramentas de cada plataforma para gerar executáveis. Este pacote contém código e configuração; consulte os resultados para distinguir builds realizados e plataformas preparadas.

## Onde editar

| Arquivo | Conteúdo |
|---|---|
| lib/ui/screens/ | Telas. |
| lib/ui/app_shell.dart | Barra, cabeçalho e ligação entre telas. |
| lib/ui/theme.dart | Cores, fonte e tema. |
| lib/state/app_state.dart | Favoritos, pastas, perfil, busca e sessão. |
| lib/services/api_client.dart | Comunicação HTTP. |
| assets/ | Imagens, ícones, logo e fonte. |
| server/server.py | Unsplash e autenticação. |
| .vscode/ | Tarefas e execução no VS Code. |

Para encerrar, use **q** no terminal Flutter ou **Parar** no VS Code. Encerre a API do VS Code com **Terminal → Encerrar tarefa → ImagoHub: API**. `scripts/run.py` encerra a API que ele iniciou quando o Flutter termina.

