import Foundation

enum WeatherMessages {
    static let hourlyButton = "Previsioni orarie"
    static let nextHoursTitle = "PROSSIME ORE"
    static let nowLabel = "Adesso"
    static let noHourlyData = "Previsioni orarie non disponibili"

    static let feelsLike = "Percepita"
    static let wind = "Vento"
    static let humidity = "Umidità"
    static let uvIndex = "Indice UV"
    static let rainChance = "Pioggia"
    static let sunset = "Tramonto"

    static let lowPrefix = "Min"
    static let highPrefix = "Max"
    static let celsius = "°C"
    static let fahrenheit = "°F"
    static let windUnitMetric = "km/h"
    static let windUnitImperial = "mph"
    static let missingValue = "–"

    static func conditionName(_ condition: WeatherCondition) -> String {
        switch condition {
        case .sunny: return "Sereno"
        case .cloudy: return "Nuvoloso"
        case .rain: return "Pioggia"
        case .snow: return "Neve"
        case .storm: return "Temporale"
        case .fog: return "Nebbia"
        }
    }

    static let loadingTitle = "Carico…"
    static let noDataTitle = "Nessun dato"
    static let loadingMessage = "Un attimo, guardo fuori dalla finestra…"
    static let offlinePrefix = "Offline"
    static let outdatedPrefix = "Non aggiornato"

    static func errorMessage(_ error: WeatherError) -> String {
        switch error {
        case .offline: return "Non riesco a collegarmi. Controlla la rete."
        case .server: return "Il servizio meteo non risponde. Riprovo tra poco."
        case .invalidData: return "Ho ricevuto dati strani. Riprovo tra poco."
        }
    }

    static let citiesTitle = "CITTÀ"
    static let searchPlaceholder = "Cerca una città…"
    static let searching = "Cerco…"
    static let noResults = "Nessuna città trovata"
    static let searchFailed = "Ricerca non riuscita. Controlla la rete."
    static let searchHint = "Scrivi almeno 2 lettere"
    static let citiesFull = "Hai raggiunto il massimo di città salvate"

    static let addCity = "Aggiungi città"
    static let removeCity = "Rimuovi città"
    static let setDefaultCity = "Imposta come città predefinita"
    static let isDefaultCity = "Città predefinita"
    static let alreadySaved = "Già salvata"
    static let changeCity = "Cambia città"
    static let closeSheet = "Chiudi"
    static let clearSearch = "Cancella ricerca"
    static let unitToggle = "Passa tra Celsius e Fahrenheit"
    static let quitApp = "Esci da jWeather"
    static let mascotAccessibility = "Mascotte. Toccala per una frase nuova."

    static let menuRefresh = "Aggiorna ora"
    static let menuTestTools = "Strumenti di test"
    static let menuQuit = "Esci da jWeather"
    static let menuAbout = "Informazioni su jWeather"
    static let menuHide = "Nascondi jWeather"
    static let menuEdit = "Modifica"
    static let menuCut = "Taglia"
    static let menuCopy = "Copia"
    static let menuPaste = "Incolla"
    static let menuSelectAll = "Seleziona tutto"

    static let testToolsTitle = "STRUMENTI DI TEST"
    static let simulatedPrefix = "Simulato"
    static let sourceReal = "Reale"
    static let sourceSimulated = "Simulato"
    static let dayName = "Giorno"
    static let nightName = "Notte"

    static func intensityName(_ intensity: WeatherIntensity) -> String {
        switch intensity {
        case .light: return "Leggera"
        case .moderate: return "Media"
        case .heavy: return "Forte"
        }
    }

    static func networkName(_ network: SimulatedNetwork) -> String {
        switch network {
        case .online: return "Online"
        case .offline: return "Offline"
        case .error: return "Errore"
        }
    }

    static let greetingsMorning = [
        "Buongiorno Jamila!",
        "Buongiorno, dormigliona!",
        "Buongiorno, che ti piaccia o no."
    ]

    static let greetingsAfternoon = [
        "Buon pomeriggio!",
        "Ciao! Pranzato?",
        "Pisolino pomeridiano?"
    ]

    static let greetingsEvening = [
        "Buonasera Jamila!",
        "Che serata! Meow...",
        "È ora di una lobotomia!"
    ]

    static let greetingsNight = [
        "Ancora sveglia?",
        "Buonanotte… quasi!",
        "Shhh, è notte!"
    ]

    static let sunnyMessages = [
        "Giornata perfetta per una passeggiata!",
        "Il sole è tutto per te",
        "Mi stendo al sole, ci vediamo dopo",
        "Oggi si sta fuori, tu che dici?"
    ]

    static let cloudyMessages = [
        "Che cielo pensieroso!",
        "Ti piacciono le nuvole?",
        "Niente ombrello, solo la copertina",
        "Grigio ma accogliente, come te"
    ]

    static let rainMessages = [
        "Resta in casa, al calduccio",
        "Sei bella con gli occhiali ☺️",
        "Tisana ai mirtilli?",
        "Prr... come amo la pioggia"
    ]

    static let snowMessages = [
        "Perfetto per un pisolino",
        "Fiocchi e fusa!",
        "Io resto sul termosifone",
        "Troppo freddo... troppo"
    ]

    static let stormMessages = [
        "Passerà. Stai vicino a me",
        "Che boato! Io sono coraggioso… quasi",
        "Sotto la coperta si sta meglio",
        "Aspettiamo che finisca"
    ]

    static let fogMessages = [
        "A me piace molto la nebbia! A te?",
        "Il mondo oggi è silenzioso",
        "Si vede poco, ma ci sei tu"
    ]

    static func messages(for condition: WeatherCondition) -> [String] {
        switch condition {
        case .sunny: return sunnyMessages
        case .cloudy: return cloudyMessages
        case .rain: return rainMessages
        case .snow: return snowMessages
        case .storm: return stormMessages
        case .fog: return fogMessages
        }
    }

    static let hotMessages = [
        "Troppo caldo, cerco l'ombra",
        "Acqua fresca, per favore!",
        "Io mi sciolgo come un gelato"
    ]

    static let coldMessages = [
        "Brrr, sciarpetta obbligatoria",
        "Copriti bene, mi raccomando",
        "Mi arrotolo a palla per scaldarmi"
    ]

    static let windyMessages = [
        "Che vento! Tieni stretto il cappello!",
        "Mi si spettina tutto il pelo",
        "Oggi gli ombrelli volano via"
    ]

    static let highUVMessages = [
        "Occhio al sole: crema solare!",
        "Cerca un po' d'ombra"
    ]

    static let nightMessages = [
        "Finalmente sera... prr",
        "Ti piacciono le stelle?",
        "È tardi, ti sei meritata un riposino"
    ]

    static let tapMessages = [
        "Miao! Non toccarmi!",
        "Ehi, mi hai svegliato!",
        "Prr prr…",
        "Mi fai le coccole?",
        "Ti voglio bene 🍭",
        "Sono qui, sono qui...",
        "Ah però... che mani carine"
    ]

    static let hotFromCelsius = 30
    static let coldUpToCelsius = 3
    static let windyFromKmh = 35
    static let highUVFrom = 7
    static let contextualChanceOutOf10 = 6
    static let greetingChanceOutOf10 = 4

    static let geocodingLanguage = "it"
    static let todayPrefix = "Oggi"
    static let dateFormat = "d MMM"
    static let timeFormat = "HH:mm"
    static let dateLocale = "it_IT"
}