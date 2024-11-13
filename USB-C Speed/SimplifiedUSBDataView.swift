//
//  SimplifiedUSBDataView.swift
//  USB-C Speed
//
//  Created by zhaoxin on 2024-11-11.
//

import SwiftUI

// MARK: - SimplifiedUSBDataView
struct SimplifiedUSBDataView: View {
  let usbData: USBData

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        // 使用组合的唯一标识符
        // 修改这里以过滤掉无设备的spusbDataType
        ForEach(Array(zip(usbData.spusbDataType.indices, usbData.spusbDataType)).filter { !($0.1.items?.isEmpty ?? true) }, id: \.0) { index, dataType in
          VStack(alignment: .leading) {
            Text(dataType.name)
              .font(.headline)
            SimplifiedSPUSBDataTypeView(dataType: dataType)
          }
        }
        // 添加雷电设备支持
        // 修改这里以过滤掉无设备的spThunderboltDataType
        ForEach(Array(zip(usbData.spThunderboltDataType.indices, usbData.spThunderboltDataType)).filter { !($0.1.items?.isEmpty ?? true) }, id: \.0) { index, dataType in
          VStack(alignment: .leading) {
            Text(dataType.name)
              .font(.headline)
            SimplifiedSPThunderboltDataTypeView(dataType: dataType)
          }
        }
      }
    }
    .padding()
  }
}

// MARK: - SimplifiedSPUSBDataTypeView
struct SimplifiedSPUSBDataTypeView: View {
  let dataType: SPUSBDataType

  var body: some View {
    // 仅显示设备列表，不显示属性信息
    if let items = dataType.items {
      ForEach(items, id: \.name) { device in
        SimplifiedUSBDeviceView(device: device)
      }
    } else {
      Text("无设备")
    }
  }
}

// MARK: - SimplifiedSPThunderboltDataTypeView
struct SimplifiedSPThunderboltDataTypeView: View {
  let dataType: SPThunderboltDataType

  var body: some View {
    // 仅显示设备列表，不显示属性信息
    if let items = dataType.items {
      ForEach(items, id: \.name) { device in
        SimplifiedThunderboltDeviceView(device: device)
      }
    } else {
      Text("无设备")
    }
  }
}

// MARK: - SimplifiedUSBDeviceView
struct SimplifiedUSBDeviceView: View {
  let device: USBDevice
  @State private var isExpanded = false

  var body: some View {
    DisclosureGroup(isExpanded: $isExpanded) {
      VStack(alignment: .leading) {
        // 仅显示指定的属性，并处理可选值
        Text("总线电源: \(device.busPower ?? "未知")毫安")
        Text("已使用总线电源: \(device.busPowerUsed ?? "未知")毫安")
        Text("设备速度: \(getDeviceSpeedString(device.deviceSpeed))")
        Text("额外使用电流: \(device.extraCurrentUsed ?? "未知")毫安")
        Text("制造商: \(device.manufacturer ?? "未知")")

        // 处理嵌套的设备
        if let items = device.items {
          ForEach(items, id: \.name) { nestedDevice in
            SimplifiedUSBDeviceView(device: nestedDevice)
              .padding(.leading, 20)
          }
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.leading, 20)
    } label: {
      Text(device.name)
    }
  }

  // 设备速度转换函数
  func getDeviceSpeedString(_ speed: String) -> String {
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
}

// MARK: - SimplifiedThunderboltDeviceView
struct SimplifiedThunderboltDeviceView: View {
  let device: ThunderboltDevice
  @State private var isExpanded = false

  var body: some View {
    DisclosureGroup(isExpanded: $isExpanded) {
      VStack(alignment: .leading) {
        // 仅显示指定的属性
        Text("设备名称: \(device.deviceNameKey ?? "未知")")
        Text("供应商名称: \(device.vendorNameKey ?? "未知")")
        if let modeKey = device.modeKey {
          Text("模式: \(USBMonitor.getReadableMode(modeKey))")
        }
        // 显示receptacleUpstreamAmbiguousTag信息
        if let receptacle = device.receptacleUpstreamAmbiguousTag {
          Text("接口信息:")
          Text("  当前速度: \(USBMonitor.getReadableSpeed(receptacle.currentSpeedKey))")
          Text("  链接状态: \(receptacle.linkStatusKey)")
          Text("  接口状态: \(USBMonitor.getReadableReceptacleStatus(receptacle.receptacleStatusKey))")
        }

        // 处理嵌套的设备
        if let items = device.items {
          ForEach(items, id: \.name) { nestedDevice in
            SimplifiedThunderboltDeviceView(device: nestedDevice)
              .padding(.leading, 20)
          }
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.leading, 20)
    } label: {
      Text(device.name)
    }
  }
}

// MARK: - 预览 Provider
struct SimplifiedUSBDataView_Previews: PreviewProvider {
  static var previews: some View {
    // 创建一个示例 USBData 对象用于预览
    // 修改这里以包含 spThunderboltDataType 参数
    let sampleUSBData = USBData(spusbDataType: [/* 在这里添加USB示例数据 */], spThunderboltDataType: [/* 在这里添加雷电示例数据 */])
    SimplifiedUSBDataView(usbData: sampleUSBData)
  }
}
