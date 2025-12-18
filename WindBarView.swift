//
//  WindBarView.swift
//  WindBar v1.3
//
//  Created by d on 11/12/2025.
//

import Foundation
import SwiftUI
import Combine
import AppKit

struct WindBarView: View {

    @EnvironmentObject var manager: WeatherManager
    @State private var showRecommendations = false
    @State private var showPopularPilots = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            
            HStack {
                Spacer()
                Button {
                    NSApp.terminate(nil)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Quit WindBar")
            }

            // HEADER
            HStack {
                Image(systemName: "wind")
                Text("WindBar")
                    .font(.title2)
                Spacer()
                if let date = manager.lastUpdated {
                    Text(date, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // CURRENT WIND + ALERT STATUS
            if manager.isLoading {
                HStack {
                    ProgressView()
                    Text("Loading…")
                }
            } else if let speed = manager.windSpeedKmh {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Image(systemName: "location")
                    Text(currentLocationDescription)
                    Spacer()
                    
                    // Alert indicator
                    if manager.alertsEnabled {
                        alertBadge
                    }
                }
                .font(.caption)

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Image(systemName: "wind")
                    Text("\(speed, specifier: "%.1f")")
                        .font(.system(size: 22, weight: .medium))
                    Text(manager.windUnit.display)
                        .font(.headline)
                    Spacer()
                }

                HStack(spacing: 6) {
                    if let temp = manager.temperatureDisplayed {
                        Image(systemName: "thermometer")
                        Text(temp)
                            .font(.headline)
                    }
                    Spacer()
                }
                .font(.caption)
                
                HStack(spacing: 6) {
                    if let uv = manager.uvIndex {
                        Image(systemName: "sun.max")
                        Text("UV Index")
                            .font(.subheadline)
                        Text("\(uv, specifier: "%.1f") — \(manager.uvCategory(for: uv))")
                            .font(.headline)
                    }
                    Spacer()
                }
                .font(.caption)

                Text(currentLocationDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("No data yet.")
            }

            // ERROR
            if let err = manager.errorMessage {
                Text(err)
                    .font(.caption)
                    .foregroundColor(.red)
            }

            Divider().padding(.vertical, 4)

            // WIND ALERTS SECTION
            Text("Drone Safety Alert")
                .font(.headline)

            Toggle("Enable wind alerts", isOn: $manager.alertsEnabled)

            if manager.alertsEnabled {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Max safe wind:")
                        Spacer()
                        Text("\(Int(manager.maxWindSpeed)) \(manager.windUnit.display)")
                            .foregroundColor(.secondary)
                    }
                    .font(.callout)
                    
                    Slider(value: $manager.maxWindSpeed, in: 5...30, step: 1)
                        .onChange(of: manager.maxWindSpeed) { _ in
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                manager.refresh()
                            }
                        }
                    
                    HStack(spacing: 8) {
                        Text("65mm tinywhoop 10-15 km/h recommended")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Button {
                            showRecommendations.toggle()
                        } label: {
                            Label("Recommended wind limits", systemImage: "info.circle")
                        }
                        .buttonStyle(.link)
                        .font(.caption2)
                        .popover(isPresented: $showRecommendations) {
                            RecommendedWindPopover()
                                .padding(12)
                                .frame(width: 260)
                        }
                    }
                    
                    alertStatusMessage
                        .font(.callout)
                        .padding(.vertical, 4)
                }
                .padding(.leading, 8)
            }

            Divider().padding(.vertical, 4)

            // LOCATION MODE PICKER
            Text("Location")
                .font(.headline)

            Picker("Mode", selection: $manager.locationMode) {
                ForEach(LocationMode.allCases) { mode in
                    Text(mode.label).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            Group {
                switch manager.locationMode {

                case .cityName:
                    TextField("City name", text: $manager.cityName)

                case .coordinates:
                    HStack {
                        Text("Lat")
                        TextField("Latitude", value: $manager.latitude, format: .number)
                    }
                    HStack {
                        Text("Lon")
                        TextField("Longitude", value: $manager.longitude, format: .number)
                    }

                case .countryCity:
                    Picker("Region", selection: $manager.selectedRegion) {
                        ForEach(WorldCities.keys.sorted(), id: \.self) { region in
                            Text(region).tag(region)
                        }
                    }

                    Picker("Country", selection: $manager.selectedCountry) {
                        ForEach(regionCountries, id: \.self) { country in
                            Text("\(manager.flagEmoji(for: country, region: manager.selectedRegion)) \(country)")
                                .tag(country)
                        }
                    }

                    Picker("City", selection: $manager.selectedCity) {
                        ForEach(regionCities, id: \.self) { city in
                            Text(city).tag(city)
                        }
                    }
                }
            }
            .font(.callout)

            // DISPLAY / UNITS / AUTO REFRESH
            Divider().padding(.vertical, 4)

            Text("Display")
                .font(.headline)

            Picker("Unit", selection: $manager.windUnit) {
                ForEach(WindUnit.allCases) { unit in
                    Text(unit.display).tag(unit)
                }
            }
            .pickerStyle(.segmented)

            Picker("Temperature", selection: $manager.temperatureUnit) {
                ForEach(TemperatureUnit.allCases) { unit in
                    Text(unit.display).tag(unit)
                }
            }
            .pickerStyle(.segmented)

            Picker("Window width", selection: $manager.layout) {
                ForEach(LayoutWidth.allCases) { opt in
                    Text(opt.display).tag(opt)
                }
            }
            .pickerStyle(.segmented)

            Toggle("Use dummy data", isOn: $manager.useDummyData)

            Stepper("Auto-refresh: \(manager.refreshIntervalMinutes) min",
                    value: $manager.refreshIntervalMinutes,
                    in: 5...60)

            Button {
                manager.refresh()
            } label: {
                Label("Refresh now", systemImage: "arrow.clockwise")
            }
            .padding(.top, 2)

            // HOURLY FORECAST
            if !manager.hourlyForecast.isEmpty {
                Divider().padding(.vertical, 4)
                Text("Next hours")
                    .font(.headline)

                ForEach(manager.hourlyForecast) { hour in
                    HStack {
                        Image(systemName: "clock")
                        Text(hour.label)
                            .frame(width: 50, alignment: .leading)

                        Spacer()

                        if let ws = hour.windSpeed {
                            HStack(spacing: 4) {
                                Image(systemName: "wind")
                                Text("\(Int(ws))\(unitSuffix)")
                                
                                if manager.alertsEnabled && ws <= manager.maxWindSpeed {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.caption2)
                                }
                            }
                        }
                    }
                    .font(.caption)
                }
            }

            // ABOUT SECTION
            Divider().padding(.vertical, 4)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("About")
                    .font(.headline)
                
                Text("WindBar")
                    .font(.callout)
                    .fontWeight(.medium)
                
                Text("A free app for drone enthusiasts")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Created by FPV-dB")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("This is my free gift to the drone community and anyone who wishes to know the wind speed. For me drones are a great form of therapy. One forgets the world's problems while flying.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                Button {
                    showPopularPilots.toggle()
                } label: {
                    Label("Recommended Pro Popular Pilots", systemImage: "person.3.fill")
                }
                .buttonStyle(.link)
                .font(.callout)
                .popover(isPresented: $showPopularPilots) {
                    PopularPilotsPopover()
                        .padding(12)
                        .frame(width: 300)
                }
            }
            
            Spacer(minLength: 2)
        }
        .padding(12)
        .frame(width: manager.layout.width)
    }

    // MARK: - Alert Components
    
    @ViewBuilder
    private var alertBadge: some View {
        switch manager.alertState {
        case .disabled:
            EmptyView()
        case .safe:
            HStack(spacing: 3) {
                Image(systemName: "checkmark.circle.fill")
                Text("Safe to fly")
            }
            .font(.caption2)
            .foregroundColor(.green)
        case .tooStrong:
            HStack(spacing: 3) {
                Image(systemName: "exclamationmark.triangle.fill")
                Text("Too windy")
            }
            .font(.caption2)
            .foregroundColor(.orange)
        case .unknown:
            HStack(spacing: 3) {
                Image(systemName: "questionmark.circle")
                Text("Checking...")
            }
            .font(.caption2)
            .foregroundColor(.gray)
        }
    }
    
    @ViewBuilder
    private var alertStatusMessage: some View {
        switch manager.alertState {
        case .disabled:
            EmptyView()
        case .safe:
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Conditions are safe for flying! 🚁")
                    .foregroundColor(.green)
            }
        case .tooStrong:
            if let speed = manager.windSpeedKmh {
                let excess = speed - manager.maxWindSpeed
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Wind is \(Int(excess)) \(manager.windUnit.display) too strong")
                        .foregroundColor(.orange)
                }
            }
        case .unknown:
            HStack(spacing: 4) {
                Image(systemName: "questionmark.circle")
                    .foregroundColor(.gray)
                Text("Waiting for wind data...")
                    .foregroundColor(.gray)
            }
        }
    }

    // MARK: - Helpers

    private var unitSuffix: String {
        switch manager.windUnit {
        case .kmh:  return "Kmh"
        case .mph:  return "mph"
        case .ms:   return "m/s"
        case .knots:return "knots"
        }
    }

    private var currentLocationDescription: String {
        switch manager.locationMode {
        case .cityName:
            return manager.cityName
        case .coordinates:
            if let la = manager.latitude, let lo = manager.longitude {
                return String(format: "%.3f, %.3f", la, lo)
            }
            return "Coords"
        case .countryCity:
            return "\(manager.selectedCity), \(manager.selectedCountry)"
        }
    }

    private var regionCountries: [String] {
        (WorldCities[manager.selectedRegion]?.keys.sorted()) ?? []
    }

    private var regionCities: [String] {
        WorldCities[manager.selectedRegion]?[manager.selectedCountry]?.cities ?? []
    }
}

struct RecommendedWindPopover: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recommended maximum wind speeds")
                .font(.headline)
            Divider()
            Group {
                Text("• DJI Avata 2 — 20-30 km/h")
                Text("• DJI Neo 1 — 15 km/h")
                Text("• DJI Neo 2 — 20 km/h")
                Text("• DJI Mini 3 — 35 km/h")
                Text("• DJI Mini 4 Pro — 35 km/h")
                Text("• DJI Air 3S — 40 km/h")
                Text("• DJI Matrice Series 4 — 40 km/h")
                Text("• DJI Agras T50 — 20 km/h")
            }
            .font(.caption)
        }
    }
}

struct PopularPilotsPopover: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recommended Pro Popular Pilots")
                .font(.headline)
            Divider()
            VStack(alignment: .leading, spacing: 6) {
                // Pilot 1
                Link(destination: URL(string: "https://www.youtube.com/@BOTGRINDER")!) {
                    Text("BotGrinder")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                Text("YouTube Channel")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            VStack(alignment: .leading, spacing: 6) {
                // Pilot 2
                Link(destination: URL(string: "https://www.youtube.com/@spidersugar_fpv")!) {
                    Text("Spider Sugar FPV")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                Text("YouTube Channel")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            VStack(alignment: .leading, spacing: 6) {
                // Pilot 3
                Link(destination: URL(string: "https://www.youtube.com/@MrSteeleFPV")!) {
                    Text("Mr Steele")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                Text("YouTube Channel")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            VStack(alignment: .leading, spacing: 6) {
                // Pilot 4
                Link(destination: URL(string: "https://www.youtube.com/@koalafpv")!) {
                    Text("Koala FPV")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                Text("YouTube Channel")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            VStack(alignment: .leading, spacing: 6) {
                // Pilot 5
                Link(destination: URL(string: "https://www.youtube.com/@Kenheron")!) {
                    Text("Ken Heron - Funny expert pilot — Part 107")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                Text("YouTube Channel")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            VStack(alignment: .leading, spacing: 6) {
                // Pilot 6
                Link(destination: URL(string: "https://www.youtube.com/@grimripperrr")!) {
                    Text("Grim Ripper")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                Text("YouTube Channel")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

