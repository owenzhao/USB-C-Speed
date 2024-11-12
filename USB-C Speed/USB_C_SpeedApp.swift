//
//  USB_C_SpeedApp.swift
//  USB-C Speed
//
//  Created by zhaoxin on 2024-11-10.
//

import SwiftUI
import ServiceManagement

@main
struct USB_C_SpeedApp: App {
  @State private var usbData: USBData = USBData(spusbDataType: [])
  @State private var isMenuBarViewPresented = true

  var body: some Scene {
    WindowGroup {
      USBDataView(usbData: usbData)
        .task {
          let text = listUSBDevices()

          let decoder = JSONDecoder()
          let jsonData = Data(text.utf8)

          do {
            let usbData = try decoder.decode(USBData.self, from: jsonData)
            self.usbData = usbData
          } catch {
            print(error)
          }
        }
        .onAppear {
          registerLogin()
        }
    }

    // 修改 MenuBarExtra 以使用自定义视图
    MenuBarExtra("USB-C Speed", systemImage: "bolt.fill") {
      SimplifiedUSBDataView(usbData: usbData)
    }
    .menuBarExtraStyle(.window)
  }

  // 通过system_profiler SPUSBDataType读取USB设备信息
  func listUSBDevices() -> String {
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/sbin/system_profiler")
    task.arguments = ["SPUSBDataType", "-json"]
    let pipe = Pipe()
    task.standardOutput = pipe

    do {
      try task.run()
      let data = pipe.fileHandleForReading.readDataToEndOfFile()
      return String(data: data, encoding: .utf8) ?? ""
    } catch {
      return "Error: \(error.localizedDescription)"
    }
  }

  func registerLogin() {
    // 将应用程序添加到登录项
    let appService = SMAppService.mainApp

    switch appService.status {
    case .notRegistered:
      register()
    case .enabled:
      print("The app is already in login items.")
    case .requiresApproval:
      // 用户需要手动添加应用程序到登录项
      SMAppService.openSystemSettingsLoginItems()
      break
    case .notFound:
      register()
    @unknown default:
      fatalError()
    }
  }

  func register() {
    do {
      try appService.register()
      print("register")
    } catch {
      print("Error: \(error.localizedDescription)")
    }
  }
}
