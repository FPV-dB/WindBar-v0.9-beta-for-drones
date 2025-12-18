//
//  AppDelegate.swift
//  WindBar v1.3
//
//  Created by d on 11/12/2025.
//

import Foundation
import Cocoa
import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {

    var statusItem: NSStatusItem?
    let weatherManager = WeatherManager()
    var popover: NSPopover?
    var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {

        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.title = "—"   // default glyph

        // Create SwiftUI popover view
        let view = WindBarView().environmentObject(weatherManager)
        let hosting = NSHostingController(rootView: view)

        let pop = NSPopover()
        pop.behavior = .transient
        pop.contentSize = NSSize(width: weatherManager.layout.width, height: 460)
        pop.contentViewController = hosting
        popover = pop

        // Toggle popover on click
        statusItem?.button?.target = self
        statusItem?.button?.action = #selector(togglePopover)

        // Update status bar title when the displayed wind changes
        weatherManager.$windSpeedDisplayed
            .receive(on: RunLoop.main)
            .sink { [weak self] text in
                self?.statusItem?.button?.title = text ?? "—"
            }
            .store(in: &cancellables)

        // Adjust popover width when layout changes
        weatherManager.$layout
            .receive(on: RunLoop.main)
            .sink { [weak self] layout in
                guard let self = self else { return }
                if let pop = self.popover {
                    var size = pop.contentSize
                    size.width = layout.width
                    pop.contentSize = size
                }
            }
            .store(in: &cancellables)

        // First load
        weatherManager.refresh()
    }

    @objc func togglePopover() {
        guard let button = statusItem?.button else { return }

        if let pop = popover, pop.isShown {
            pop.performClose(nil)
        } else {
            popover?.show(relativeTo: button.bounds,
                          of: button,
                          preferredEdge: .minY)
        }
    }
}

