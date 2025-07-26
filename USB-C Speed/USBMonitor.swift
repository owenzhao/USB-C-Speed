//
//  USBMonitor.swift
//  USB-C Speed
//
//  Created by zhaoxin on 2024-11-13.
//

import Combine
import Foundation
import UserNotifications

class USBMonitor: ObservableObject {
  @Published var usbData: USBData = USBData(spusbHostDataType: [], spThunderboltDataType: [])
  private let usbNotificationCenter = USBNotificationCenter()
  // 添加 Combine 订阅存储
  private var cancellables = Set<AnyCancellable>()

  init() {
    // 使用 Combine 替换 NotificationCenter
    NotificationCenter.default
      .publisher(for: USBNotificationCenter.deviceChangeNotification)
      .debounce(for: .seconds(1), scheduler: RunLoop.main)
      .sink { [weak self] _ in
        Task { @MainActor in
          await self?.updateDevices()
        }
      }
      .store(in: &cancellables)

    // 初始加载USB和雷电数据
    loadUSBData()
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
    task.arguments = ["SPUSBHostDataType", "SPThunderboltDataType", "-json"]
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
    print("开始比较新旧 USB 数据")
    let newDevices = getAllDevices(in: newData)
    let oldDevices = getAllDevices(in: oldData)

    print("新设备数量: \(newDevices.count)")
    print("旧设备数量: \(oldDevices.count)")

    // 打印全部新设备
    print("新设备列表:")
    newDevices.forEach { print("  - \($0.name): \($0.speed) (ID: \($0.id))") }

    // 打印全部旧设备
    print("旧设备列表:")
    oldDevices.forEach { print("  - \($0.name): \($0.speed) (ID: \($0.id))") }

    let addedDevices = newDevices.filter { newDevice in
      !oldDevices.contains { $0.id == newDevice.id }
    }
    let removedDevices = oldDevices.filter { oldDevice in
      !newDevices.contains { $0.id == oldDevice.id }
    }

    print("添加的设备数量: \(addedDevices.count)")
    print("移除的设备数量: \(removedDevices.count)")

    if !addedDevices.isEmpty {
      print("检测到新增设备:")
      addedDevices.forEach { print("  - \($0.name): \($0.speed) (ID: \($0.id))") }
      return (.addDevice, addedDevices)
    } else if !removedDevices.isEmpty {
      print("检测到移除设备:")
      removedDevices.forEach { print("  - \($0.name): \($0.speed) (ID: \($0.id))") }
      return (.removeDevice, removedDevices)
    } else {
      print("没有检测到设备变化")
      return (.noChange, [])
    }
  }

  // 获取usbData的所有Devices（包括USB和雷电设备）
  private func getAllDevices(in usbData: USBData) -> [Device] {
    var devices = [Device]()
    for spusbDataType in usbData.spusbHostDataType {
      if let items = spusbDataType.items {
        // 修改这里，将USB设备转换为Device对象
        let usbDevices = items.flatMap { getAllUSBDevices(from: $0) }
        devices.append(contentsOf: usbDevices.map { Device(usbDevice: $0) })
      }
    }

    for spThunderboltDataType in usbData.spThunderboltDataType {
      if let items = spThunderboltDataType.items {
        let thunderboltDevices = items.flatMap { getAllThunderboltDevices(from: $0) }
        devices.append(contentsOf: thunderboltDevices.map { Device(thunderboltDevice: $0) })
      }
    }
    return devices
  }

  // 从USBDevice里获取所有的USBDevice，因为它可能存在嵌套关系
  private func getAllUSBDevices(from usbDevice: USBDevice) -> [USBDevice] {
    var devices = [usbDevice]
    if let items = usbDevice.items {
      for item in items {
        devices.append(contentsOf: getAllUSBDevices(from: item))
      }
    }
    return devices
  }

  // 从ThunderboltDevice里获取所有的ThunderboltDevice，因为它可能存在嵌套关系
  private func getAllThunderboltDevices(from thunderboltDevice: ThunderboltDevice) -> [ThunderboltDevice] {
    var devices = [thunderboltDevice]
    if let items = thunderboltDevice.items {
      for item in items {
        devices.append(contentsOf: getAllThunderboltDevices(from: item))
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

      guard state != .noChange else {
        print("没有设备变化")
        return
      }

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

extension USBMonitor {
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

  static func getReadableReceptacleStatus(_ status: String) -> String {
    switch status {
    case "receptacle_connected":
      return "已连接"
    case "receptacle_no_devices_connected":
      return "未连接"
    default:
      return status
    }
  }

  static func getReadableSpeed(_ speed: String) -> String {
    switch speed {
    case "Up to 20 Gb/s":
      return "最高20Gb/s"
    case "Up to 40 Gb/s":
      return "最高40Gb/s"
    default:
      return speed
    }
  }

  static func getReadableMode(_ mode: String) -> String {
    switch mode {
    case "usb_four":
      return "USB 4"
    case "thunderbolt_three":
      return "雷电 3"
    case "thunderbolt_four":
      return "雷电 4"
    default:
      return mode
    }
  }
}

struct Device: Identifiable {
  let id: String
  let name: String
  let speed: String

  init(usbDevice: USBDevice) {
    self.id = usbDevice.locationID ?? UUID().uuidString
    self.name = usbDevice.name
    self.speed = USBMonitor.getDeviceSpeedString(usbDevice.linkSpeed ?? "unkown")
  }

  init(thunderboltDevice: ThunderboltDevice) {
    self.id = thunderboltDevice.deviceIdKey ?? UUID().uuidString
    self.name = thunderboltDevice.name
    self.speed = USBMonitor.getReadableSpeed(thunderboltDevice.receptacleUpstreamAmbiguousTag?.currentSpeedKey ?? "未知")
  }
}
