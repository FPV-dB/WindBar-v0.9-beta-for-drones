//
//  WindUnit.swift
//  WindBar v1.3
//
//  Created by d on 18/12/2025.
//


//
//  WeatherManager.swift
//  WindBar v1.3
//
//  Created by d on 11/12/2025.
//

import Combine
import CoreLocation
import AppKit

// -------------------------------------------------------------
// MARK: - ENUMS
// -------------------------------------------------------------

enum WindUnit: String, CaseIterable, Identifiable, Codable {
    case kmh, mph, ms, knots
    var id: String { rawValue }

    var display: String {
        switch self {
        case .kmh: return "km/h"
        case .mph: return "mph"
        case .ms: return "m/s"
        case .knots: return "knots"
        }
    }
}

enum LocationMode: String, CaseIterable, Identifiable {
    case cityName
    case coordinates
    case countryCity

    var id: String { rawValue }

    var label: String {
        switch self {
        case .cityName: return "City"
        case .coordinates: return "Coords"
        case .countryCity: return "World"
        }
    }
}

enum LayoutWidth: String, CaseIterable, Identifiable, Codable {
    case compact, regular, wide
    var id: String { rawValue }
    var width: CGFloat {
        switch self {
        case .compact: return 340
        case .regular: return 420
        case .wide:    return 520
        }
    }
    var display: String {
        switch self {
        case .compact: return "Compact"
        case .regular: return "Regular"
        case .wide:    return "Wide"
        }
    }
}

enum TemperatureUnit: String, CaseIterable, Identifiable, Codable {
    case celsius, fahrenheit
    var id: String { rawValue }
    var display: String {
        switch self {
        case .celsius: return "°C"
        case .fahrenheit: return "°F"
        }
    }
}

struct HourlyEntry: Identifiable {
    let id = UUID()
    let label: String
    let tempC: Double?
    let windSpeed: Double?
    let windDirectionDeg: Double?
}

enum WindAlertState {
    case disabled
    case safe       // Wind is in safe range
    case tooStrong  // Wind exceeds max
    case unknown    // No data yet
}

// -------------------------------------------------------------
// MARK: - WeatherManager
// -------------------------------------------------------------

@MainActor
final class WeatherManager: NSObject, ObservableObject {
    
    private enum DefaultsKeys {
        static let latitude = "lastLatitude"
        static let longitude = "lastLongitude"
    }

    // ---------- Published State ----------

    @Published var useDummyData: Bool = false { didSet { refresh() } }
    @Published var windUnit: WindUnit = .kmh { didSet { refresh() } }
    @Published var temperatureUnit: TemperatureUnit = .celsius { didSet { /* no refetch needed; convert locally */ } }
    @Published var locationMode: LocationMode = .cityName { didSet { refresh() } }
    @Published var layout: LayoutWidth = .compact

    @Published var cityName: String = "Adelaide"

    @Published var latitude: Double? {
        didSet { persistCoordinatesIfNeeded() }
    }
    @Published var longitude: Double? {
        didSet { persistCoordinatesIfNeeded() }
    }

    // WORLD REGION SELECTION
    @Published var selectedRegion: String = "Oceania" {
        didSet {
            if let first = WorldCities[selectedRegion]?.keys.sorted().first {
                selectedCountry = first
            }
        }
    }

    @Published var selectedCountry: String = "Australia" {
        didSet {
            if let cities = WorldCities[selectedRegion]?[selectedCountry]?.cities,
               let firstCity = cities.first {
                selectedCity = firstCity
            }
        }
    }

    @Published var selectedCity: String = "Adelaide"

    @Published var windSpeedKmh: Double?
    @Published var windDirectionDeg: Double?
    @Published var temperatureC: Double?
    @Published var uvIndex: Double?
    @Published var lastUpdated: Date?

    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    @Published var windSpeedDisplayed: String?

    // Auto-refresh every X minutes (minimum 5)
    @Published var refreshIntervalMinutes: Int = 15 {
        didSet {
            if refreshIntervalMinutes < 5 { refreshIntervalMinutes = 5 }
            scheduleAutoRefresh()
        }
    }

    @Published var hourlyForecast: [HourlyEntry] = []

    // ---------- WIND ALERTS ----------
    @Published var alertsEnabled: Bool = false {
        didSet {
            if !alertsEnabled {
                alertState = .disabled
            } else {
                checkWindAlert()
            }
        }
    }
    
    @Published var maxWindSpeed: Double = 15.0  // Default 15 km/h max for small drones
    
    @Published var alertState: WindAlertState = .disabled
    
    // Track previous state to detect transitions
    private var previousAlertState: WindAlertState = .disabled

    // ---------- Private ----------
    private let locationManager = CLLocationManager()
    private let urlSession = URLSession(configuration: .default)
    private var refreshTimer: AnyCancellable?
    private var cityNameCancellable: AnyCancellable?

    override init() {
        super.init()
        locationManager.delegate = self
        
        // Load last saved coordinates if available
        if UserDefaults.standard.object(forKey: DefaultsKeys.latitude) != nil,
           UserDefaults.standard.object(forKey: DefaultsKeys.longitude) != nil {
            let lat = UserDefaults.standard.double(forKey: DefaultsKeys.latitude)
            let lon = UserDefaults.standard.double(forKey: DefaultsKeys.longitude)
            self.latitude = lat
            self.longitude = lon
        }
        
        scheduleAutoRefresh()
        
        // Auto-refresh when city/suburb text changes (debounced)
        cityNameCancellable = $cityName
            .removeDuplicates()
            .debounce(for: .milliseconds(600), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.locationMode == .cityName {
                    self.refresh()
                }
            }
    }

    deinit {
        refreshTimer?.cancel()
    }
    
    private func persistCoordinatesIfNeeded() {
        guard let la = latitude, let lo = longitude else { return }
        UserDefaults.standard.set(la, forKey: DefaultsKeys.latitude)
        UserDefaults.standard.set(lo, forKey: DefaultsKeys.longitude)
    }

    // -------------------------------------------------------------
    // MARK: - Refresh Logic
    // -------------------------------------------------------------

    func refresh() {
        errorMessage = nil
        if useDummyData {
            loadDummy()
        } else {
            Task { await fetchLive() }
        }
    }

    func useDeviceLocation() {
        errorMessage = nil
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }

    func flagEmoji(for country: String, region: String) -> String {
        WorldCities[region]?[country]?.flag ?? ""
    }

    // -------------------------------------------------------------
    // MARK: - Auto Refresh
    // -------------------------------------------------------------

    private func scheduleAutoRefresh() {
        refreshTimer?.cancel()

        refreshTimer = Timer.publish(
            every: TimeInterval(refreshIntervalMinutes * 60),
            on: .main,
            in: .common
        )
        .autoconnect()
        .sink { [weak self] _ in
            self?.refresh()
        }
    }

    // -------------------------------------------------------------
    // MARK: - Dummy Data
    // -------------------------------------------------------------

    private func loadDummy() {
        isLoading = false
        errorMessage = nil

        windSpeedKmh = 18
        windDirectionDeg = 230
        temperatureC = 23
        // Conversion handled in UI; no change needed here
        uvIndex = 5.5
        lastUpdated = Date()

        hourlyForecast = (0..<6).map { i in
            HourlyEntry(
                label: "\(String(format: "%02d", (Calendar.current.component(.hour, from: .now) + i) % 24)):00",
                tempC: 23 + Double(i),
                windSpeed: 18 + Double(i),
                windDirectionDeg: 230
            )
        }

        updateMenuBarSpeed()
        checkWindAlert()
    }

    // -------------------------------------------------------------
    // MARK: - Networking
    // -------------------------------------------------------------

    private func fetchLive() async {
        isLoading = true
        defer { isLoading = false }

        do {
            var lat = latitude
            var lon = longitude

            switch locationMode {
            case .cityName:
                (lat, lon) = try await geocode(cityName)

            case .coordinates:
                guard let la = latitude, let lo = longitude else {
                    errorMessage = "Enter valid coordinates."
                    return
                }
                lat = la
                lon = lo

            case .countryCity:
                let query = "\(selectedCity), \(selectedCountry)"
                (lat, lon) = try await geocode(query)
            }

            guard let finalLat = lat, let finalLon = lon else { return }

            var comps = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
            comps.queryItems = [
                URLQueryItem(name: "latitude", value: "\(finalLat)"),
                URLQueryItem(name: "longitude", value: "\(finalLon)"),
                URLQueryItem(name: "current", value: "temperature_2m,wind_speed_10m,wind_direction_10m,uv_index"),
                URLQueryItem(name: "hourly", value: "temperature_2m,wind_speed_10m,wind_direction_10m,uv_index"),
                URLQueryItem(name: "forecast_days", value: "1"),
                URLQueryItem(name: "timezone", value: "auto"),
                URLQueryItem(name: "windspeed_unit", value: windUnit.rawValue)
            ]

            let (data, response) = try await urlSession.data(from: comps.url!)

            guard let http = response as? HTTPURLResponse,
                  (200..<300).contains(http.statusCode)
            else {
                errorMessage = "Weather service error."
                return
            }

            let decoded = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
            apply(openMeteo: decoded)

        } catch {
            errorMessage = "Failed: \(error.localizedDescription)"
        }
    }

    // -------------------------------------------------------------
    // MARK: - Apply Response
    // -------------------------------------------------------------

    private func apply(openMeteo: OpenMeteoResponse) {
        // Current conditions
        windSpeedKmh      = openMeteo.current.wind_speed_10m
        windDirectionDeg  = openMeteo.current.wind_direction_10m
        temperatureC      = openMeteo.current.temperature_2m
        uvIndex           = openMeteo.current.uv_index
        lastUpdated       = Date()

        // Hourly (limit 6)
        if let h = openMeteo.hourly {
            let count = min(6, h.time.count)

            hourlyForecast = (0..<count).map { i -> HourlyEntry in
                let raw = h.time[i]

                let timeLabel: String
                if let tPart = raw.split(separator: "T").last {
                    timeLabel = String(tPart.prefix(5))   // "HH:MM"
                } else {
                    timeLabel = raw
                }

                return HourlyEntry(
                    label: timeLabel,
                    tempC: h.temperature_2m?[safe: i],
                    windSpeed: h.wind_speed_10m?[safe: i],
                    windDirectionDeg: h.wind_direction_10m?[safe: i]
                )
            }
        } else {
            hourlyForecast = []
        }

        updateMenuBarSpeed()
        checkWindAlert()
    }

    // -------------------------------------------------------------
    // MARK: - Menu Bar Label
    // -------------------------------------------------------------

    private func updateMenuBarSpeed() {
        guard let speed = windSpeedKmh else {
            windSpeedDisplayed = "—"
            return
        }
        windSpeedDisplayed = "\(Int(speed)) \(windUnit.display)"
    }
    
    // MARK: - Temperature Formatting
    var temperatureDisplayed: String? {
        guard let c = temperatureC else { return nil }
        switch temperatureUnit {
        case .celsius:
            return String(format: "%.0f°C", c)
        case .fahrenheit:
            let f = c * 9.0/5.0 + 32.0
            return String(format: "%.0f°F", f)
        }
    }
    
    // MARK: - UV Index Category
    func uvCategory(for value: Double) -> String {
        switch value {
        case ..<3: return "Low"
        case 3..<6: return "Moderate"
        case 6..<8: return "High"
        case 8..<11: return "Very High"
        default: return "Extreme"
        }
    }

    // -------------------------------------------------------------
    // MARK: - Wind Alert Check
    // -------------------------------------------------------------

    private func checkWindAlert() {
        guard alertsEnabled else {
            alertState = .disabled
            return
        }

        guard let speed = windSpeedKmh else {
            alertState = .unknown
            return
        }

        let newState: WindAlertState
        if speed <= maxWindSpeed {
            newState = .safe
        } else {
            newState = .tooStrong
        }

        // Detect transition TO safe conditions (from too strong or unknown)
        let transitionedToSafe = newState == .safe && 
                                (previousAlertState == .tooStrong || 
                                 previousAlertState == .unknown)

        previousAlertState = alertState
        alertState = newState

        // Play sound when conditions become safe
        if transitionedToSafe {
            playAlertSound()
        }
    }

    private func playAlertSound() {
        // Play system sound - using "Glass" which is pleasant
        NSSound(named: "Glass")?.play()
        
        // Alternative sounds you can try:
        // NSSound(named: "Ping")?.play()
        // NSSound(named: "Pop")?.play()
        // NSSound(named: "Purr")?.play()
    }

    // -------------------------------------------------------------
    // MARK: - Geocoding
    // -------------------------------------------------------------

    private func geocode(_ name: String) async throws -> (Double, Double) {
        let encoded = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name

        let url = URL(string:
            "https://geocoding-api.open-meteo.com/v1/search?name=\(encoded)&count=1"
        )!

        let (data, _) = try await urlSession.data(from: url)
        let decoded = try JSONDecoder().decode(GeoResponse.self, from: data)

        guard let first = decoded.results?.first else {
            throw NSError(domain: "No geocode", code: 404)
        }

        return (first.latitude, first.longitude)
    }
}

// -------------------------------------------------------------
// MARK: - Models
// -------------------------------------------------------------

private struct GeoResponse: Decodable {
    struct Item: Decodable {
        let latitude: Double
        let longitude: Double
    }
    let results: [Item]?
}

private struct OpenMeteoResponse: Decodable {
    struct Current: Decodable {
        let temperature_2m: Double?
        let wind_speed_10m: Double?
        let wind_direction_10m: Double?
        let uv_index: Double?
    }
    struct Hourly: Decodable {
        let time: [String]
        let temperature_2m: [Double]?
        let wind_speed_10m: [Double]?
        let wind_direction_10m: [Double]?
        let uv_index: [Double]?
    }

    let current: Current
    let hourly: Hourly?
}

// Safe array indexing
private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// -------------------------------------------------------------
// MARK: - CLLocationManagerDelegate
// -------------------------------------------------------------

extension WeatherManager: CLLocationManagerDelegate {

    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }

        Task { @MainActor in
            self.latitude = loc.coordinate.latitude
            self.longitude = loc.coordinate.longitude
            self.locationMode = .coordinates
            self.persistCoordinatesIfNeeded()
            self.refresh()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didFailWithError error: Error) {
        Task { @MainActor in
            self.errorMessage = "Location error: \(error.localizedDescription)"
        }
    }
}
