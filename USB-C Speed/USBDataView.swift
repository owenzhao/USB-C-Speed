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
    }
    .padding()
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
        Text("Bus Power: \(device.busPower)mA")
        Text("Bus Power Used: \(device.busPowerUsed)mA")
        Text("Device Speed: \(USBMonitor.getDeviceSpeedString(device.deviceSpeed))")
        Text("Extra Current Used: \(device.extraCurrentUsed)mA")
        Text("Location ID: \(device.locationID)")
        Text("Manufacturer: \(device.manufacturer)")
        Text("Product ID: \(device.productID)")
        Text("Vendor ID: \(device.vendorID)")
        if let serialNum = device.serialNum {
          Text("Serial Number: \(serialNum)")
        }

        // 添加这里以处理嵌套的设备
        if let items = device.items {
          ForEach(items, id: \.name) { nestedDevice in
            USBDeviceView(device: nestedDevice)
              .padding(.leading, 20)
          }
        }

        if let media = device.media {
          ForEach(media, id: \.name) { mediaItem in
            MediaView(media: mediaItem)
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
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.leading, 20)
    } label: {
      Text(media.name)
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
