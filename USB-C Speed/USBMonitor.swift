//
//  USBMonitor.swift
//  USB-C Speed
//
//  Created by zhaoxin on 2024-11-13.
//

import Foundation
import UserNotifications

class USBMonitor: ObservableObject {
  @Published var usbData: USBData = USBData(spusbDataType: [], spThunderboltDataType: [])
  private let usbNotificationCenter = USBNotificationCenter()

  // 添加设备速度转换函数，添加对于雷电接口速度的支持
  static func getDeviceSpeedString(_ speed: String) -> String {
    switch speed.lowercased() {
    case "low_speed":
      return "1.5 Mbit/s (USB 1.0 低速)"
    case "full_speed":
      return "12 Mbit/s (USB 1.1 全速)"
    case "high_speed":
      return "480 Mbit/s (USB 2.0 高速)"
    case "super_speed":
      return "5 Gbit/s (USB 3.0 超高速)"
    case "super_speed_plus":
      return "10 Gbit/s (USB 3.1 超高速+)"
    case "super_speed_plus_20":
      return "20 Gbit/s (USB 3.2 超高速+ 20)"
    default:
      return "\(speed) (未知)"
    }
  }

  init() {
    // 初始化时设置通知观察者
    setupNotificationObservers()
    // 初始加载USB和雷电数据
    loadUSBData()
  }

  private func setupNotificationObservers() {
    NotificationCenter.default.addObserver(self, selector: #selector(handleUSBDeviceAdded), name: USBNotificationCenter.usbDeviceAddedNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(handleUSBDeviceRemoved), name: USBNotificationCenter.usbDeviceRemovedNotification, object: nil)
    // 添加雷电设备通知观察者
    NotificationCenter.default.addObserver(self, selector: #selector(handleThunderboltDeviceAdded), name: USBNotificationCenter.thunderboltDeviceAddedNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(handleThunderboltDeviceRemoved), name: USBNotificationCenter.thunderboltDeviceRemovedNotification, object: nil)
  }

  @objc private func handleUSBDeviceAdded() {
    Task { @MainActor in
      await updateDevices()
    }
  }

  @objc private func handleUSBDeviceRemoved() {
    Task { @MainActor in
      await updateDevices()
    }
  }

  // 添加雷电设备处理方法
  @objc private func handleThunderboltDeviceAdded() {
    Task { @MainActor in
      await updateDevices()
    }
  }

  @objc private func handleThunderboltDeviceRemoved() {
    Task { @MainActor in
      await updateDevices()
    }
  }

  private func loadUSBData() {
    do {
      self.usbData = try getUSBData()
    } catch {
      print("加载 USB 和雷电数据时出错：\(error)")
    }
  }

  // 通过system_profiler同时读取USB设备和雷电设备信息
  private func listUSBDevices() -> String {
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/sbin/system_profiler")
    task.arguments = ["SPUSBDataType", "SPThunderboltDataType", "-json"]
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
  private func compareUSBData(newData: USBData, oldData: USBData) -> (DeviceChangeState, [Device]) {
    let newDevices = getAllDevices(in: newData)
    let oldDevices = getAllDevices(in: oldData)

    let addedDevices = newDevices.filter { newDevice in
      !oldDevices.contains { $0.id == newDevice.id }
    }
    let removedDevices = oldDevices.filter { oldDevice in
      !newDevices.contains { $0.id == oldDevice.id }
    }

    if !addedDevices.isEmpty {
      return (.addDevice, addedDevices)
    } else if !removedDevices.isEmpty {
      return (.removeDevice, removedDevices)
    } else {
      return (.noChange, [])
    }
  }

  // 获取usbData的所有Devices（包括USB和雷电设备）
  private func getAllDevices(in usbData: USBData) -> [Device] {
    var devices = [Device]()
    for spusbDataType in usbData.spusbDataType {
      if let items = spusbDataType.items {
        // 修改这里，将USB设备转换为Device对象
        devices.append(contentsOf: items.map { Device(usbDevice: $0) })
      }
    }
    for spThunderboltDataType in usbData.spThunderboltDataType {
      if let items = spThunderboltDataType.items {
        devices.append(contentsOf: items.map { Device(thunderboltDevice: $0) })
      }
    }
    return devices
  }

  // 将结构体转化为文本输出
  private func getString(for changes: (DeviceChangeState, [Device])) -> String {
    var deviceInfos = "\n"

    for device in changes.1 {
      deviceInfos += getDeviceInfo(for: device) + "\n"
    }

    switch changes.0 {
    case .addDevice:
      return "添加了设备：\(deviceInfos)"
    case .removeDevice:
      return "移除了设备：\(deviceInfos)"
    case .noChange:
      return "没有变化"
    }
  }

  // 将Device简化输出，只输出name和speed
  private func getDeviceInfo(for device: Device) -> String {
    return "\(device.name)：\(device.speed)"
  }

  enum DeviceChangeState {
    case addDevice
    case removeDevice
    case noChange
  }

  @MainActor
  func updateDevices() async {
    do {
      let oldData = self.usbData
      self.usbData = try getUSBData()
      let (state, devices) = compareUSBData(newData: self.usbData, oldData: oldData)
      let message = getString(for: (state, devices))
      try await sendNotification(message: message)
    } catch {
      print("更新设备时出错：\(error)")
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

struct Device: Identifiable {
  let id: String
  let name: String
  let speed: String

  init(usbDevice: USBDevice) {
    self.id = usbDevice.serialNum ?? UUID().uuidString
    self.name = usbDevice.name
    self.speed = USBMonitor.getDeviceSpeedString(usbDevice.deviceSpeed)
  }

  init(thunderboltDevice: ThunderboltDevice) {
    self.id = thunderboltDevice.deviceIdKey ?? UUID().uuidString
    self.name = thunderboltDevice.name
    self.speed = thunderboltDevice.modeKey ?? "未知"
  }
}
