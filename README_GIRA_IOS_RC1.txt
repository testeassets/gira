GIRA iOS 1.0 RC1 — OAUTH READY
==============================

CONFIGURAÇÃO APLICADA
---------------------
Bundle ID:
br.com.gira.mobile

Backend:
https://script.google.com/macros/s/AKfycbzQKtA3RFd-PzZlW9q9m1d2uGTxyrE7oIrGCAbDrOpJdoZ4SYVU3YK8gDLwpKF5UuLo/exec

iOS Client ID:
608060642580-i7c2qd3t6ls7t2k18ckksap646amfr4o.apps.googleusercontent.com

Reversed Client ID / URL Scheme:
com.googleusercontent.apps.608060642580-i7c2qd3t6ls7t2k18ckksap646amfr4o

Server/Web Client ID:
608060642580-kkq9fgsaj8dtrkot7p8jbel1li3p4rok.apps.googleusercontent.com

FLUXO DO APP
------------
Abrir GIRA
  -> Login Google
  -> Dashboard

Não há tela para digitar Backend ou Web Client ID.

JÁ PREPARADO
------------
- SwiftUI nativo
- Google Sign-In para iOS
- integração com o mesmo Backend do Android
- Dashboard
- Atividades
- atualização de progresso
- envio para revisão
- aprovação
- Equipe
- Solicitações
- Perfil/logout
- XcodeGen
- Codemagic
- workflow de build sem assinatura
- workflow preparado para TestFlight/App Store

PRÓXIMO PASSO
-------------
Faça primeiro o build:

GIRA iOS - Build sem assinatura

Depois, para TestFlight:
- Apple Developer Program
- App ID / Bundle ID registrado
- app criado no App Store Connect
- integração App Store Connect no Codemagic
- assinatura Apple configurada

Observação:
O codemagic.yaml ainda contém um placeholder para o APP_STORE_APPLE_ID.
Isso é esperado e só será preenchido quando o app for criado no App Store Connect.

SEGURANÇA
---------
O HMAC do Portal não fica no app.
Client IDs OAuth são identificadores públicos.
Não compartilhe chaves privadas Apple, certificados privados ou senhas.
