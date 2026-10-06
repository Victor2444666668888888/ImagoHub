# ImagoHub

ImagoHub é uma aplicação mobile/web em Flutter para explorar, buscar e salvar fotografias, com autenticação local de usuários, biblioteca pessoal e integração com a API da Unsplash.

O projeto simula uma galeria visual moderna com fluxo completo de login, cadastro, busca avançada, favoritos, pastas, perfil e configurações, tudo com persistência local no dispositivo e no backend Python.

## Visão geral

- Galeria e busca de fotos com filtros por categoria, cor, formato e texto
- Autenticação com conta própria do usuário
- Favoritos e organização em pastas pessoais
- Perfil com avatar, nome, usuário, e-mail e biografia
- API local em Python para gerenciar contas e servir como gateway para a Unsplash
- Suporte a Web, Android e Windows

## Tecnologias utilizadas

### Frontend
- Flutter
- Dart
- Material 3 / widgets do Flutter
- flutter_localizations
- shared_preferences
- flutter_secure_storage
- file_picker
- url_launcher
- flutter_svg

### Backend
- Python 3.11+
- SQLite
- Biblioteca padrão do Python
- HTTP server nativo (`http.server`)

### Integração externa
- Unsplash API
- Cookies e sessão local para autenticação

## Estrutura do projeto

```text
ImagoHub/
├── android/                  # projeto Android
├── assets/                   # imagens, ícones, fontes, dados JSON
├── ios/                      # projeto iOS
├── lib/                      # código principal do Flutter
│   ├── main.dart             # ponto de entrada da aplicação
│   ├── models/              # modelos de dados (foto, pasta, filtros, perfil)
│   ├── state/               # estado global da aplicação
│   ├── services/            # cliente HTTP e integrações
│   ├── ui/                  # telas, widgets e temas
│   └── ...
├── scripts/
│   └── run.py               # inicia a API e o app juntos
├── server/
│   ├── .env.example         # exemplo de variáveis de ambiente
│   ├── .env                 # ambiente local da API (não versionado)
│   ├── server.py            # backend do projeto
│   └── tests/
├── test/                     # testes do Flutter
├── verification/              # artefatos de verificação
├── web/                      # projeto web
├── windows/                  # projeto Windows
├── .gitignore
├── analysis_options.yaml
├── ImagoHub.code-workspace
├── LEIA-ME.md                # documentação detalhada em português
├── pubspec.yaml
├── pubspec.lock
├── README.md
└── ...
```

## Requisitos

Antes de rodar o projeto, verifique se você tem:

- Flutter SDK estável
- Python 3.11 ou superior
- Chrome instalado para execução em Web
- Android Studio + SDK para Android (se for testar em emulador)
- Visual Studio com Desktop development with C++ para Windows

Caso precise validar e configurar o ambiente:

```bash
flutter doctor
```

## Configuração do ambiente

O backend usa um arquivo `.env` dentro da pasta `server/`.

Exemplo:

```env
UNSPLASH_ACCESS_KEY=sua_chave
APP_ENV=development
IMAGOHUB_DATA_DIR=./data
ALLOWED_ORIGINS=http://localhost:8080,http://127.0.0.1:8080
```

O projeto já inclui um modelo em `server/.env.example`.

Se a chave da Unsplash não estiver configurada, a busca de fotos será desativada e a API retornará erro de configuração.

## Como executar

### Opção 1: via VS Code

1. Abra o workspace `ImagoHub.code-workspace`
2. Instale as extensões recomendadas: Flutter, Dart e Python
3. Selecione a configuração de execução `ImagoHub · Chrome`
4. Pressione `F5`

A tarefa também inicia automaticamente a API local.

### Opção 2: via script do projeto

```bash
python scripts/run.py --device chrome
```

### Opção 3: rodar manualmente

Em um terminal:

```bash
python server/server.py
```

Em outro terminal:

```bash
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8787
```

## Execução em outros dispositivos

### Android

```bash
flutter devices
flutter run -d <ID_DO_EMULADOR> --dart-define=API_BASE_URL=http://10.0.2.2:8787
```

O backend precisa estar disponível em `http://10.0.2.2:8787` quando o emulador for usado.

### Windows

```bash
flutter build windows --release --dart-define=API_BASE_URL=http://127.0.0.1:8787
```

Ou execute usando o atalho do projeto:

```bash
python scripts/run.py --device windows
```

## Funcionalidades principais

- Login e cadastro de usuários
- Recuperação de senha e validação de regras
- Busca por fotos do catálogo da Unsplash
- Filtros por categoria, cor, orientação e texto livre
- Visualização detalhada de cada imagem
- Favoritar fotos
- Organizar imagens em pastas pessoais
- Persistência de perfil e dados por conta do usuário
- Tema claro/escuro e ajustes de configuração

## Fluxo principal da aplicação

1. Usuário acessa a tela de login
2. Realiza cadastro ou autenticação
3. É levado à galeria
4. Pode buscar fotos, favoritar e salvar em pastas
5. O perfil e as configurações ficam disponíveis somente após autenticação

## Observações importantes

- A API local usa SQLite para armazenar contas e sessões
- As senhas são armazenadas com hash e salt
- O projeto mantém dados por usuário no dispositivo para evitar mistura de conteúdos
- A API usa a biblioteca padrão do Python; não há necessidade de instalar dependências extras via `pip`
- Caso use o aplicativo em ambiente de produção, ajuste a configuração de e-mail e CORS conforme necessário

## Documentação extra

A documentação detalhada do projeto está em [LEIA-ME.md](LEIA-ME.md).

## Licença

Este projeto é um aplicativo de demonstração/estudo e não possui licença pública formal definida no repositório.