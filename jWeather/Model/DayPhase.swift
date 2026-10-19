import Foundation

enum DayPhase: Equatable {
    case day
    case night

    static func phase(at date: Date,
                      sun: [SunInterval]?,
                      coordinate: (latitude: Double, longitude: Double)) -> DayPhase {
        if let sun = sun, let first = sun.first, let last = sun.last,
           date >= first.sunrise.addingTimeInterval(-3600), date < last.sunset.addingTimeInterval(3600) {
            return sun.contains { $0.sunrise <= date && date < $0.sunset } ? .day : .night
        }
        return SolarPosition.isDaylight(at: date, latitude: coordinate.latitude, longitude: coordinate.longitude) ? .day : .night
    }
}

enum SolarPosition {
    static func elevationDegrees(at date: Date, latitude: Double, longitude: Double) -> Double {
        let rad = Double.pi / 180
        let days = date.timeIntervalSince1970 / 86400 + 2440587.5 - 2451545.0
        let meanLongitude = (280.460 + 0.9856474 * days).truncatingRemainder(dividingBy: 360)
        let meanAnomaly = ((357.528 + 0.9856003 * days).truncatingRemainder(dividingBy: 360)) * rad
        let eclipticLongitude = (meanLongitude + 1.915 * sin(meanAnomaly) + 0.020 * sin(2 * meanAnomaly)) * rad
        let obliquity = (23.439 - 0.0000004 * days) * rad
        let declination = asin(sin(obliquity) * sin(eclipticLongitude))
        let rightAscension = atan2(cos(obliquity) * sin(eclipticLongitude), cos(eclipticLongitude))
        let siderealHours = (18.697374558 + 24.06570982441908 * days).truncatingRemainder(dividingBy: 24)
        let hourAngle = (siderealHours * 15 + longitude) * rad - rightAscension
        let sinElevation = sin(latitude * rad) * sin(declination) + cos(latitude * rad) * cos(declination) * cos(hourAngle)
        return asin(max(-1, min(1, sinElevation))) / rad
    }

    static func isDaylight(at date: Date, latitude: Double, longitude: Double) -> Bool {
        elevationDegrees(at: date, latitude: latitude, longitude: longitude) > -0.833
    }
}