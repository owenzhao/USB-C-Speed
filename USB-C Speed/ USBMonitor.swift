//
//   USBMonitor.swift
//  USB-C Speed
//
//  Created by zhaoxin on 2024-11-13.
//

import Foundation
import UserNotifications

class USBMonitor: ObservableObject {
  @Published var usbData: USBData = USBData(spusbDataType: [])
  private let usbNotificationCenter = USBNotificationCenter()

  init() {
    // 初始化时设置通知观察者
    setupNotificationObservers()
    // 初始加载USB数据
    loadUSBData()
  }

  private func setupNotificationObservers() {
    NotificationCenter.default.addObserver(self, selector: #selector(handleUSBDeviceAdded), name: USBNotificationCenter.usbDeviceAddedNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(handleUSBDeviceRemoved), name: USBNotificationCenter.usbDeviceRemovedNotification, object: nil)
  }

  @objc private func handleUSBDeviceAdded() {
    Task { @MainActor in
      await updateUSBDevice()
    }
  }

  @objc private func handleUSBDeviceRemoved() {
    Task { @MainActor in
      await updateUSBDevice()
    }
  }

  private func loadUSBData() {
    do {
      self.usbData = try getUSBData()
    } catch {
      print("加载 USB 数据时出错：\(error)")
    }
  }

  // 通过system_profiler SPUSBDataType读取USB设备信息
  private func listUSBDevices() -> String {
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
      return "错误：\(error.localizedDescription)"
    }
  }

  private func getUSBData() throws -> USBData {
    let text = listUSBDevices()
    let decoder = JSONDecoder()
    let jsonData = Data(text.utf8)
    return try decoder.decode(USBData.self, from: jsonData)
  }

  // 对比新、旧两个USBData，看是添加了设备还是移除了设备，然后返回结果
  private func compareUSBData(newData: USBData, oldData: USBData) -> (USBDeviceChangeState, [USBDevice]) {
    let newDevices = getAllUSBDevices(in: newData)
    let oldDevices = getAllUSBDevices(in: oldData)

    let addedDevices = newDevices.filter { newDevice in
      !oldDevices.contains { $0.serialNum == newDevice.serialNum }
    }
    let removedDevices = oldDevices.filter { oldDevice in
      !newDevices.contains { $0.serialNum == oldDevice.serialNum }
    }

    if !addedDevices.isEmpty {
      return (.addDevice, addedDevices)
    } else if !removedDevices.isEmpty {
      return (.removeDevice, removedDevices)
    } else {
      return (.noChange, [])
    }
  }

  // 获取usbData的所有USBDevices
  private func getAllUSBDevices(in usbData: USBData) -> [USBDevice] {
    var usbDevices = [USBDevice]()
    for spusbDataType in usbData.spusbDataType {
      for item in spusbDataType.items {
        usbDevices.append(contentsOf: getAllUSBDevices(in: item))
      }
    }
    return usbDevices
  }

  private func getAllUSBDevices(in usbDevice: USBDevice) -> [USBDevice] {
    var usbDevices = [USBDevice]()
    usbDevices.append(usbDevice)
    if let items = usbDevice.items {
      for item in items {
        usbDevices.append(contentsOf: getAllUSBDevices(in: item))
      }
    }
    return usbDevices
  }

  // 将结构体转化为文本输出
  private func getString(for changes: (USBDeviceChangeState, [USBDevice])) -> String {
    switch changes.0 {
    case .addDevice:
      return "添加了设备：\(changes.1)"
    case .removeDevice:
      return "移除了设备：\(changes.1)"
    case .noChange:
      return "没有变化"
    }
  }

  enum USBDeviceChangeState {
    case addDevice
    case removeDevice
    case noChange
  }

  @MainActor
  func updateUSBDevice() async {
    do {
      let oldData = self.usbData
      self.usbData = try getUSBData()
      let (state, devices) = compareUSBData(newData: self.usbData, oldData: oldData)
      let message = getString(for: (state, devices))
      try await sendNotification(message: message)
    } catch {
      print("更新 USB 设备时出错：\(error)")
    }
  }

  private func requestNotificationAuthorization(with message: String) async throws {
    let center = UNUserNotificationCenter.current()
    let options: UNAuthorizationOptions = [.alert, .sound]
    let granted = try await center.requestAuthorization(options: options)
    if granted {
      print("授权已获得。")
      try await sendNotification(message: message)
    } else {
      print("授权被拒绝。")
    }
  }

  private func sendNotification(message: String) async throws {
    print(message)
    let center = UNUserNotificationCenter.current()
    let settings = await center.notificationSettings()
    guard (settings.authorizationStatus == .authorized) ||
            (settings.authorizationStatus == .provisional) else {
      try await requestNotificationAuthorization(with: message)
      return
    }
    let content = UNMutableNotificationContent()
    content.title = "USB 设备变化"
    content.body = message
    content.sound = .default
    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
    do {
      try await center.add(request)
      print("通知已成功发送。")
    } catch {
      print("发送通知时出错：\(error.localizedDescription)")
    }
  }
}

// 文件结束。没有额外的代码。
