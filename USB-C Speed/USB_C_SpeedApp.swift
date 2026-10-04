//
//  USB_C_SpeedApp.swift
//  USB-C Speed
//
//  Created by zhaoxin on 2024-11-10.
//

import SwiftUI
import AppKit
import ServiceManagement
import Sparkle

private final class AppDelegate: NSObject, NSApplicationDelegate {
  let updaterController = SPUStandardUpdaterController(
    startingUpdater: true,
    updaterDelegate: nil,
    userDriverDelegate: nil
  )

  func applicationDidFinishLaunching(_ notification: Notification) {
    if updaterController.updater.automaticallyChecksForUpdates {
      updaterController.updater.checkForUpdatesInBackground()
    }
    registerLogin()
  }

  func checkForUpdates() {
    updaterController.checkForUpdates(nil)
  }

  // 将应用程序添加到登录项
  func registerLogin() {
    let app = SMAppService.mainApp

    switch app.status {
    case .notRegistered:
      register(app)
    case .enabled:
      print("The app is already in login items.")
    case .requiresApproval:
      // 用户需要手动添加应用程序到登录项
      SMAppService.openSystemSettingsLoginItems()
    case .notFound:
      register(app)
    @unknown default:
      fatalError()
    }
  }

  private func register(_ app: SMAppService) {
    do {
      try app.register()
      print("register")
    } catch {
      print("Error: \(error.localizedDescription)")
    }
  }
}

@main
struct USB_C_SpeedApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
  @StateObject private var usbMonitor = USBMonitor()

  var body: some Scene {
    MenuBarExtra {
      MenuBarRootView(
        usbData: usbMonitor.usbData,
        onCheckForUpdates: {
          appDelegate.updaterController.checkForUpdates(nil)
        }
      )
    } label: {
      HStack(spacing: 4) {
        Image(systemName: "bolt.fill")
        if let battery = usbMonitor.bluetoothBattery {
          Image(systemName: battery.isCharging ? "battery.100percent.bolt" : "battery.50percent")
          Text(Double(battery.level) / 100, format: .percent)
        }
      }
      .fixedSize()
    }
    .menuBarExtraStyle(.window)
  }
}
