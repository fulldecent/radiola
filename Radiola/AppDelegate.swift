//
//  AppDelegate.swift
//  Radiola
//
//  Created by Alex Sokolov on 26.05.2020.
//  Copyright © 2020 Alex Sokolov. All rights reserved.
//

import Cocoa
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let showMainWindow = Self("showMainWindow")
    static let showHistoryWindow = Self("showHistoryWindow")
    static let showPreferencesWindow = Self("showPreferencesWindow")
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    private let oplDirectoryName = "com.github.SokoloffA.Radiola/"
    private let oplFileName = "bookmarks.opml"
    private let audioSytstem = AudioSytstem()
    private let mediaKeys = MediaKeysController()

    @IBOutlet var pauseMenuItem: NSMenuItem!
    @IBOutlet var playMenuItem: NSMenuItem!
    @IBOutlet var checkForUpdatesMenuItem: NSMenuItem!

    private var statusBar: StatusBarController!

    /* ****************************************
     *
     * ****************************************/
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(processError),
                                               name: Alarm.notificationName,
                                               object: nil)

        let dirName = URL(
            fileURLWithPath: oplDirectoryName,
            relativeTo: FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first)

        if !FileManager.default.fileExists(atPath: dirName.absoluteString) {
            do {
                try FileManager.default.createDirectory(at: dirName, withIntermediateDirectories: true)
            } catch {
                fatalError(error.localizedDescription)
            }
        }

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerStatusChanged),
                                               name: Notification.Name.PlayerStatusChanged,
                                               object: nil)

        player.station = AppState.shared.lastStation()

        statusBar = StatusBarController()

        playMenuItem.target = player
        playMenuItem.action = #selector(Player.play)

        pauseMenuItem.target = player
        pauseMenuItem.action = #selector(Player.stop)

        checkForUpdatesMenuItem.target = updater
        checkForUpdatesMenuItem.action = #selector(Updater.checkForUpdates)

        playerStatusChanged()

        if settings.playLastStation {
            debug("Auto play \(settings.lastStationUrl ?? "nil")")
            player.play()
        }

        KeyboardShortcuts.onKeyUp(for: .showMainWindow) { [self] in showStationView(nil) }
        KeyboardShortcuts.onKeyUp(for: .showHistoryWindow) { [self] in showHistory(nil) }
    }

    /* ****************************************
     *
     * ****************************************/
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    /* ****************************************
     *
     * ****************************************/
    @IBAction func startPlay(_ sender: NSMenuItem) {
        player.play()
    }

    /* ****************************************
     *
     * ****************************************/
    @IBAction func stopPlay(_ sender: NSMenuItem) {
        player.stop()
    }

    /* ****************************************
     *
     * ****************************************/
    @objc func togglePlay(_ sender: NSMenuItem) {
        player.toggle()
    }

    /* ****************************************
     *
     * ****************************************/
    @objc func playerStatusChanged() {
        switch player.status {
            case Player.Status.paused:
                playMenuItem.isHidden = false
                pauseMenuItem.isHidden = true

            case Player.Status.connecting:
                playMenuItem.isHidden = true
                pauseMenuItem.isHidden = false

            case Player.Status.playing:
                playMenuItem.isHidden = true
                pauseMenuItem.isHidden = false
        }
    }

    /* ****************************************
     *
     * ****************************************/
    @objc func showStationView(_ sender: Any?) {
        _ = StationsWindow.show()
    }

    /* ****************************************
     *
     * ****************************************/
    @objc func showHistory(_ sender: Any?) {
        _ = HistoryWindow.show()
    }

    /* ****************************************
     *
     * ****************************************/
    @IBAction func showPreferences(_ sender: Any) {
        _ = PreferencesWindow.show()
    }

    /* ****************************************
     *
     * ****************************************/
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        NSApp.setActivationPolicy(.accessory)
        return false
    }

    /* ****************************************
     *
     * ****************************************/
    @objc private func processError(_ notification: Notification) {
        guard let alarm = notification.object as? Alarm else { return }

        DispatchQueue.main.async {
            guard let button = self.statusBar.menuItem.button else { return }

            let dialog = AlarmPopover()
            dialog.messageText = alarm.title
            dialog.informativeText = alarm.message ?? ""
            dialog.show(of: button)
        }
    }
}
