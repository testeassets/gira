GIRA iOS 1.0 — PREPARAÇÃO PARA CODEMAGIC / TESTFLIGHT
======================================================

OBJETIVO
--------
Projeto iOS nativo em SwiftUI preparado para ser compilado na nuvem sem possuir Mac.

ARQUITETURA
-----------
GIRA iOS
 -> Google Sign-In iOS
 -> Google ID Token
 -> mesmo GIRA Backend Mobile
 -> Google Sheets / Drive / Histórico

O HMAC do Portal não fica no aplicativo iOS.

O QUE JÁ ESTÁ PREPARADO
-----------------------
- SwiftUI;
- visual alinhado ao GIRA Portal/Android;
- configuração inicial da URL do Backend;
- Google Sign-In;
- uso do mesmo Web Client ID do Backend;
- Dashboard;
- atividades;
- atualização de progresso;
- envio para revisão;
- aprovação;
- Equipe;
- Solicitações em lista;
- Perfil/logout;
- XcodeGen project.yml;
- GoogleSignIn como Swift Package;
- codemagic.yaml com workflow sem assinatura;
- workflow preparado para TestFlight/App Store.

O QUE AINDA PRECISA SER CRIADO NO GOOGLE CLOUD
-----------------------------------------------
Crie um OAuth Client do tipo iOS usando:

Bundle ID:
br.com.gira.mobile

Depois copie:
1. iOS Client ID;
2. REVERSED_CLIENT_ID.

No arquivo project.yml substitua:

GIRA_IOS_CLIENT_ID:
608060642580-i7c2qd3t6ls7t2k18ckksap646amfr4o.apps.googleusercontent.com

GIRA_REVERSED_CLIENT_ID:
com.googleusercontent.apps.608060642580-i7c2qd3t6ls7t2k18ckksap646amfr4o

O Web Client ID do Backend já está preenchido:
608060642580-kkq9fgsaj8dtrkot7p8jbel1li3p4rok.apps.googleusercontent.com

BACKEND
-------
O iOS pode usar o mesmo Backend Mobile usado pelo Android.

Na primeira abertura do app, informe:
https://script.google.com/macros/s/.../exec

da implantação BACKEND.

BUILD SEM MAC
-------------
1. Crie um repositório GitHub.
2. Envie esta pasta para o repositório.
3. Crie uma conta Codemagic.
4. Conecte o repositório.
5. O Codemagic detectará codemagic.yaml.
6. Execute primeiro:
   GIRA iOS - Build sem assinatura

Esse workflow:
- usa Mac na nuvem;
- instala XcodeGen;
- gera GIRA.xcodeproj;
- resolve GoogleSignIn;
- compila sem code signing.

DISTRIBUIÇÃO
------------
Para TestFlight/App Store você precisará:
- Apple Developer Program;
- Bundle ID registrado;
- app criado no App Store Connect;
- integração App Store Connect configurada no Codemagic;
- APP_STORE_APPLE_ID preenchido no codemagic.yaml.

Depois rode:
GIRA iOS - TestFlight/App Store

IMPORTANTE
----------
A Apple exige Xcode 26+ / SDK iOS 26+ para uploads atuais ao App Store Connect.
O Codemagic pode selecionar a imagem Xcode adequada na nuvem.

STATUS
------
Este pacote foi preparado e validado estruturalmente neste ambiente.
Não foi compilado com Xcode aqui, pois este ambiente não possui macOS/Xcode.
O primeiro build real deve ser o workflow sem assinatura do Codemagic.
