//
//  USBDataView.swift
//  USB-C Speed
//
//  Created by zhaoxin on 2024-11-10.
//

import SwiftUI

// MARK: - USBDataView
struct USBDataView: View {
  let usbData: USBData

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        // 使用组合的唯一标识符
        ForEach(Array(zip(usbData.spusbDataType.indices, usbData.spusbDataType)), id: \.0) { index, dataType in
          VStack(alignment: .leading) {
            Text(dataType.name)
              .font(.headline)
            SPUSBDataTypeView(dataType: dataType)
          }
        }
      }
      .padding()
    }
  }
}

// MARK: - SPUSBDataTypeView
struct SPUSBDataTypeView: View {
  let dataType: SPUSBDataType

  var body: some View {
    VStack(alignment: .leading) {
      Text("Host Controller: \(dataType.hostController)")
      if let pciDevice = dataType.pciDevice {
        Text("PCI Device: \(pciDevice)")
      }
      if let pciRevision = dataType.pciRevision {
        Text("PCI Revision: \(pciRevision)")
      }
      if let pciVendor = dataType.pciVendor {
        Text("PCI Vendor: \(pciVendor)")
      }
      ForEach(dataType.items, id: \.name) { device in
        USBDeviceView(device: device)
      }
    }
  }
}

// MARK: - USBDeviceView
struct USBDeviceView: View {
  let device: USBDevice
  @State private var isExpanded = false

  var body: some View {
    DisclosureGroup(isExpanded: $isExpanded) {
      VStack(alignment: .leading) {
        Text("BCD Device: \(device.bcdDevice)")
        Text("Bus Power: \(device.busPower)")
        Text("Bus Power Used: \(device.busPowerUsed)")
        Text("Device Speed: \(getDeviceSpeedString(device.deviceSpeed))")
        Text("Extra Current Used: \(device.extraCurrentUsed)")
        Text("Location ID: \(device.locationID)")
        Text("Manufacturer: \(device.manufacturer)")
        Text("Product ID: \(device.productID)")
        Text("Vendor ID: \(device.vendorID)")
        if let serialNum = device.serialNum {
          Text("Serial Number: \(serialNum)")
        }
        if let media = device.media {
          ForEach(media, id: \.name) { mediaItem in
            MediaView(media: mediaItem)
          }
        }
      }
    } label: {
      Text(device.name)
//        .onTapGesture { // 添加这个手势识别器
//          isExpanded.toggle()
//        }
    }
  }

  // 添加这个函数来转换设备速度
  func getDeviceSpeedString(_ speed: String) -> String {
    switch speed.lowercased() {
    case "low_speed":
      return "1.5 Mbit/s (USB 1.0 低速)"
    case "full_speed":
      return "12 Mbit/s (USB 1.1 全速)"
    case "high_speed":
      return "480 Mbit/s (USB 2.0 高速)"
    case "super_speed":
      return "5 Gbit/s (USB 3.0 超速)"
    case "super_speed_plus":
      return "10 Gbit/s (USB 3.1 超高速)"
    case "super_speed_plus_20":
      return "20 Gbit/s (USB 3.2 超高速+)"
    default:
      return "\(speed) (未知速度)"
    }
  }
}

// MARK: - MediaView
struct MediaView: View {
  let media: Media
  @State private var isExpanded = false

  var body: some View {
    DisclosureGroup(isExpanded: $isExpanded) {
      VStack(alignment: .leading) {
        Text("BSD Name: \(media.bsdName)")
        Text("Logical Unit: \(media.logicalUnit)")
        Text("Partition Map Type: \(media.partitionMapType)")
        Text("Removable Media: \(media.removableMedia)")
        Text("Size: \(media.size)")
        Text("Size in Bytes: \(media.sizeInBytes)")
        Text("Smart Status: \(media.smartStatus)")
        Text("USB Interface: \(media.usbInterface)")
        ForEach(media.volumes, id: \.name) { volume in
          VolumeView(volume: volume)
        }
      }
    } label: {
      Text(media.name)
//        .onTapGesture { // 添加这个手势识别器
//          isExpanded.toggle()
//        }
    }
  }
}

// MARK: - VolumeView
struct VolumeView: View {
  let volume: Volume

  var body: some View {
    VStack(alignment: .leading) {
      Text("BSD Name: \(volume.bsdName)")
      if let fileSystem = volume.fileSystem {
        Text("File System: \(fileSystem)")
      }
      Text("IOContent: \(volume.iocontent)")
      Text("Size: \(volume.size)")
      Text("Size in Bytes: \(volume.sizeInBytes)")
      if let volumeUUID = volume.volumeUUID {
        Text("Volume UUID: \(volumeUUID)")
      }
      if let freeSpace = volume.freeSpace {
        Text("Free Space: \(freeSpace)")
      }
      if let freeSpaceInBytes = volume.freeSpaceInBytes {
        Text("Free Space in Bytes: \(freeSpaceInBytes)")
      }
      if let mountPoint = volume.mountPoint {
        Text("Mount Point: \(mountPoint)")
      }
      if let writable = volume.writable {
        Text("Writable: \(writable)")
      }
    }
  }
}

// 预览 Provider
struct USBDataView_Previews: PreviewProvider {
  static var previews: some View {
    // 创建一个示例 USBData 对象用于预览
    let sampleUSBData = USBData(spusbDataType: [/* 在这里添加示例数据 */])
    USBDataView(usbData: sampleUSBData)
  }
}

// 文件结束。无其他代码。
