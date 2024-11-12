//
//  USB_C_SpeedApp.swift
//  USB-C Speed
//
//  Created by zhaoxin on 2024-11-10.
//

import SwiftUI
import ServiceManagement
//import UserNotifications

@main
struct USB_C_SpeedApp: App {
  @StateObject private var usbMonitor = USBMonitor()
  @State private var isMenuBarViewPresented = true

  var body: some Scene {
    WindowGroup {
      USBDataView(usbData: usbMonitor.usbData)
        .onAppear {
          registerLogin()
        }
    }

    // 修改 MenuBarExtra 以使用自定义视图
    MenuBarExtra("USB-C Speed", systemImage: "bolt.fill") {
      SimplifiedUSBDataView(usbData: usbMonitor.usbData)
    }
    .menuBarExtraStyle(.window)
  }

  func registerLogin() {
    // 将应用程序添加到登录项
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

  func register(_ app: SMAppService) {
    do {
      try app.register()
      print("register")
    } catch {
      print("Error: \(error.localizedDescription)")
    }
  }
}
