# jWeather

App meteo per macOS con icona nella barra dei menu e widget a comparsa. Realizzata con SwiftUI, senza dipendenze esterne, utilizza i dati di [Open-Meteo](https://open-meteo.com).

## Funzionalità

- Previsioni meteo tramite Open-Meteo.
- Widget a comparsa accessibile dalla barra dei menu.
- Visualizzazione delle condizioni meteorologiche con animazioni atmosferiche.
- Animazioni per cielo sereno, nuvoloso, nebbia, pioggia, neve e temporali, con varianti giorno/notte e diverse intensità.
- Supporto per la preferenza di sistema «Riduci movimento».
- Possibilità di passare da Celsius a Fahrenheit.
- Aggiornamento manuale delle condizioni meteorologiche.
- Interfaccia nativa per macOS, realizzata interamente con SwiftUI.

## Requisiti

- macOS 14 o successivo.
- Xcode 26.

## Installazione e avvio

### Compilare da Xcode

1. Apri `jWeather.xcodeproj` con Xcode.
2. Seleziona lo schema **jWeather** e la destinazione **My Mac**.
3. Configura la firma del progetto con **Sign to Run Locally** oppure con il tuo account sviluppatore.
4. Premi **⌘R** per compilare ed eseguire l'applicazione.

Il Bundle Identifier predefinito è `com.jami.jWeather`. Puoi modificarlo nelle impostazioni **Signing & Capabilities** del progetto.

## Distribuzione

Per creare un file DMG distribuibile, esegui dalla directory principale del progetto:

```bash
./scripts/make-dmg.sh
```

Lo script genera `build/jWeather.dmg` con una build Release firmata ad hoc.

### Notarizzazione

Per distribuire una versione notarizzata sono necessari un account Apple Developer e un certificato Developer ID.

Configura le variabili d'ambiente con la tua identità di firma e il tuo Team ID:

```bash
export SIGN_IDENTITY="Developer ID Application: Nome (TEAMID)"
export TEAM_ID="TEAMID"
```

Crea il DMG e invialo ad Apple per la notarizzazione:

```bash
./scripts/make-dmg.sh
xcrun notarytool submit build/jWeather.dmg --keychain-profile jWeather-notary --wait
xcrun stapler staple build/jWeather.dmg
```

Il profilo `jWeather-notary` deve essere configurato in precedenza tramite:

```bash
xcrun notarytool store-credentials jWeather-notary
```

Senza notarizzazione, macOS potrebbe bloccare la prima apertura dell'applicazione a causa delle restrizioni di sicurezza di Gatekeeper.

## Struttura del progetto

```text
jWeather/
  App/        Avvio dell'app, menu e barra dei menu
  Model/      Stato, condizioni meteo e logica applicativa
  Services/   Open-Meteo, geocoding, città e cache
  Messages/   Testi e messaggi dell'interfaccia
  Theme/      Palette e superfici dell'interfaccia
  Views/      Componenti dell'interfaccia SwiftUI
  Effects/    Animazioni atmosferiche
  Resources/  Asset, icona, Info.plist ed entitlements
scripts/      Script per la creazione del DMG
```

## Crediti

I dati meteorologici sono forniti da [Open-Meteo](https://open-meteo.com/).

Realizzato con Swift e SwiftUI per macOS.