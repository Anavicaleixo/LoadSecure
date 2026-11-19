# LoadSecure

Aplicação Flutter Web para equipes de empresas de logística industrial.

## Contas e equipes

O cadastro em **Minha empresa** cria uma empresa e seu primeiro administrador.
No perfil, **Usuários e permissões** mostra o código de equipe. Um colega faz
seu cadastro em **Entrar na equipe**, com esse código, seu próprio e-mail e
senha. O login resolve a empresa a partir da conta cadastrada. As empresas
compartilham dados apenas entre seus membros. Para abrir o Site privado,
os visitantes precisam também ter acesso concedido nas opções de
compartilhamento do Sites.

## Persistência

Cargas, movimentações, impactos, inspeções, rotas, checklists e configurações
são persistidos no D1 e consultados pelo servidor no contexto da empresa da
sessão. A interface sincroniza mudanças de colegas a cada oito segundos.
Edições concorrentes do mesmo registro usam versões para evitar sobrescrever
silenciosamente alterações. Dados da sessão não ficam em localStorage.

Senhas usam PBKDF2/SHA-256 com salt individual. Sessões usam cookies Secure,
HttpOnly e SameSite=None com Partitioned para funcionar no Site incorporado. Administradores podem consultar a equipe e alterar
configurações; membros não obtêm o código de equipe pela API. Todas as
consultas usam parâmetros SQL e a empresa é determinada no servidor.

## Desenvolvimento

```sh
flutter pub get
flutter run -d chrome
npm install
npm run db:generate
npm run test:server
flutter analyze
flutter test
```

A interface precisa do servidor em `/api` na mesma origem para autenticar
e sincronizar. O Worker exportado está em `server/index.js`. A publicação
usa o binding D1 `DB`, aplica as migrations de `drizzle` e serve os assets
de Flutter em `dist/client` através de `ASSETS`.

Integrações de sensores, câmera, Google/Microsoft e envio de e-mail ainda
não estão conectadas. Empresas novas começam com seus registros vazios.

## Web e celular

A versão web usa os widgets Flutter deste projeto. O aplicativo móvel em
Flutter para Android e iOS utiliza WebView para abrir essa mesma plataforma
privada, incluindo a autenticação do Sites. Assim, não inclui tokens de
serviço nem uma cópia separada dos dados da empresa.

Para executar no navegador:

```sh
flutter run -d chrome
```

Para executar no celular conectado:

```sh
flutter run
```

Para gerar o APK, com Android SDK instalado:

```sh
flutter build apk --release
```

Para iOS, em macOS com Xcode e assinatura configurados:

```sh
flutter build ios --release
```

O nome do aplicativo e seus ícones estão personalizados. O endereço pode
ser configurado por `--dart-define=LOADSECURE_SITE_URL=https://...`.
As pastas Android/iOS e o código móvel foram preparados e analisados; não
foi possível gerar/testar APK ou IPA neste ambiente sem Android SDK/Xcode.

Os QR Codes são gerados por carga e abrem sua tela após o login. O usuário
que estiver em outra empresa não consegue acessar os registros da carga.
A câmera integrada de leitura ainda não está conectada; os códigos podem
ser lidos pela câmera do celular, ou consultados pela entrada manual.
