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
        ForEach(Array(zip(usbData.spusbDataType.indices, usbData.spusbDataType)), id: \.0) { index, dataType in
          VStack(alignment: .leading) {
            Text(dataType.name)
              .font(.headline)
            SimplifiedSPUSBDataTypeView(dataType: dataType)
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
    ForEach(dataType.items, id: \.name) { device in
      SimplifiedUSBDeviceView(device: device)
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
        // 仅显示指定的属性
        Text("总线电源: \(device.busPower)毫安")
        Text("已使用总线电源: \(device.busPowerUsed)毫安")
        Text("设备速度: \(getDeviceSpeedString(device.deviceSpeed))")
        Text("额外使用电流: \(device.extraCurrentUsed)毫安")
        Text("制造商: \(device.manufacturer)")

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

// MARK: - 预览 Provider
struct SimplifiedUSBDataView_Previews: PreviewProvider {
  static var previews: some View {
    // 创建一个示例 USBData 对象用于预览
    let sampleUSBData = USBData(spusbDataType: [/* 在这里添加示例数据 */])
    SimplifiedUSBDataView(usbData: sampleUSBData)
  }
}
