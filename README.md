# jWeather

App meteo per macOS: icona nella barra dei menu e widget a comparsa. SwiftUI, nessuna dipendenza esterna, dati da [Open-Meteo](https://open-meteo.com).

- App standard: compare in Applicazioni e nel Dock; all'avvio apre subito il widget (anche cliccando di nuovo l'icona).
- Città predefinite alla prima installazione: Viterbo e Ferrara.
- Switch °C/°F e pulsante di chiusura nel widget.
- Clic destro sul widget (o sull'icona nella barra dei menu): **Aggiorna ora** e **Strumenti di test**. Il clic sinistro non esegue azioni.
- Animazioni distinte per sereno, nuvoloso, nebbia, pioggia, neve e temporale, con varianti giorno/notte e tre intensità. Rispettano «Riduci movimento».

## Strumenti di test

Dal menu del clic destro → **Strumenti di test** si apre un pannello dentro il widget. Scegli meteo, intensità, giorno o notte e rete (online, offline, errore): il widget si aggiorna subito, senza chiudersi. «Reale» riporta ai dati veri. La simulazione non viene mai salvata.

## Requisiti

macOS 14+ e Xcode 26 (l'icona è un file Icon Composer).

## Avvio

1. Apri `jWeather.xcodeproj`.
2. Schema **jWeather**, destinazione *My Mac*. La firma è «Sign to Run Locally»: non serve alcun account.
3. ⌘R.

Il Bundle Identifier è `com.jami.jWeather`: cambialo con il tuo in *Signing & Capabilities* se usi un account sviluppatore.

## Distribuire un .dmg

```bash
./scripts/make-dmg.sh
```

Crea `build/jWeather.dmg` (build Release firmata ad-hoc). Caricalo in *Releases* su GitHub.

Senza notarizzazione macOS blocca la prima apertura: l'utente deve fare clic destro → Apri, oppure `xattr -dr com.apple.quarantine /Applications/jWeather.app`.

Per un'app notarizzata servono un account Apple Developer e un certificato Developer ID:

```bash
export SIGN_IDENTITY="Developer ID Application: Nome (TEAMID)" TEAM_ID=TEAMID
./scripts/make-dmg.sh
xcrun notarytool submit build/jWeather.dmg --keychain-profile jWeather-notary --wait
xcrun stapler staple build/jWeather.dmg
```

(Il profilo si crea una volta con `xcrun notarytool store-credentials jWeather-notary`.)

## Struttura

```
jWeather/
  App/        avvio, menu, barra dei menu, pannello
  Model/      store, condizioni, giorno/notte, simulazione
  Services/   Open-Meteo, geocoding, città, cache
  Messages/   testi e scelta delle frasi
  Theme/      palette animabile e superfici
  Views/      interfaccia
  Effects/    animazioni atmosferiche
  Resources/  asset, icona, Info.plist, entitlements
scripts/      make-dmg.sh
```

## Git

```bash
git init && git add . && git commit -m "jWeather"
```