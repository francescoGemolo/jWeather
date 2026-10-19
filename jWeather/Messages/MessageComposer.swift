import Foundation

struct MessageContext {
    let condition: WeatherCondition
    let temperature: Int?
    let windKmh: Int?
    let uvIndex: Int?
    let isDay: Bool
    let hour: Int
}

enum MessageComposer {
    static func contextualMessages(_ context: MessageContext) -> [String] {
        var contextual: [String] = []
        if let wind = context.windKmh, wind >= WeatherMessages.windyFromKmh, context.condition != .storm {
            contextual += WeatherMessages.windyMessages
        }
        if let temperature = context.temperature {
            if temperature >= WeatherMessages.hotFromCelsius {
                if context.isDay, context.condition == .sunny || context.condition == .cloudy {
                    contextual += WeatherMessages.hotMessages
                }
            } else if temperature <= WeatherMessages.coldUpToCelsius {
                contextual += WeatherMessages.coldMessages
            }
        }
        if let uv = context.uvIndex, uv >= WeatherMessages.highUVFrom, context.isDay, context.condition == .sunny {
            contextual += WeatherMessages.highUVMessages
        }
        return contextual
    }

    static func baseMessages(_ context: MessageContext) -> [String] {
        if !context.isDay, context.condition == .sunny || context.condition == .cloudy {
            return WeatherMessages.nightMessages
        }
        return WeatherMessages.messages(for: context.condition)
    }

    static func caption(_ context: MessageContext, avoiding last: String? = nil) -> String {
        let contextual = contextualMessages(context)
        var pool = baseMessages(context)
        if !contextual.isEmpty, Int.random(in: 0..<10) < WeatherMessages.contextualChanceOutOf10 {
            pool = contextual
        }
        return pick(from: pool, avoiding: last)
    }

    static func greetingMessages(hour: Int, isDay: Bool) -> [String] {
        switch hour {
        case 5..<12: return isDay ? WeatherMessages.greetingsMorning : WeatherMessages.greetingsNight
        case 12..<18: return isDay ? WeatherMessages.greetingsAfternoon : WeatherMessages.greetingsEvening
        case 18..<22: return WeatherMessages.greetingsEvening
        default: return WeatherMessages.greetingsNight
        }
    }

    static func greeting(hour: Int, isDay: Bool, avoiding last: String? = nil) -> String {
        pick(from: greetingMessages(hour: hour, isDay: isDay), avoiding: last)
    }

    static func chatter(avoiding last: String? = nil) -> String {
        pick(from: WeatherMessages.tapMessages, avoiding: last)
    }

    static func isFitting(_ line: String, in context: MessageContext) -> Bool {
        baseMessages(context).contains(line)
            || contextualMessages(context).contains(line)
            || greetingMessages(hour: context.hour, isDay: context.isDay).contains(line)
            || WeatherMessages.tapMessages.contains(line)
    }

    private static func pick(from pool: [String], avoiding last: String?) -> String {
        let options = pool.filter { $0 != last }
        return (options.isEmpty ? pool : options).randomElement() ?? ""
    }
}