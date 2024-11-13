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
        // 添加这里以处理雷电数据类型
        ForEach(Array(zip(usbData.spThunderboltDataType.indices, usbData.spThunderboltDataType)), id: \.0) { index, dataType in
          VStack(alignment: .leading) {
            Text(dataType.name)
              .font(.headline)
            SPThunderboltDataTypeView(dataType: dataType)
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
      Text("主控制器: \(dataType.hostController ?? "未知")")
      if let pciDevice = dataType.pciDevice {
        Text("PCI设备: \(pciDevice)")
      }
      if let pciRevision = dataType.pciRevision {
        Text("PCI修订版: \(pciRevision)")
      }
      if let pciVendor = dataType.pciVendor {
        Text("PCI供应商: \(pciVendor)")
      }
      // 修改这里以处理items可能为nil的情况
      if let items = dataType.items {
        ForEach(items, id: \.name) { device in
          USBDeviceView(device: device)
        }
      } else {
        Text("无设备")
      }
    }
  }
}

// MARK: - SPThunderboltDataTypeView
struct SPThunderboltDataTypeView: View {
  let dataType: SPThunderboltDataType

  var body: some View {
    VStack(alignment: .leading) {
      // 移除主控制器，因为SPThunderboltDataType没有这个属性
      Text("设备名称: \(dataType.deviceNameKey)")
      Text("域UUID: \(dataType.domainUuidKey)")
      Text("路由字符串: \(dataType.routeStringKey)")
      Text("交换机UID: \(dataType.switchUidKey)")
      Text("供应商名称: \(dataType.vendorNameKey)")

      // 显示接口信息
      if let receptacle = dataType.receptacle1Tag {
        Text("接口信息:")
        Text("  当前速度: \(USBMonitor.getReadableSpeed(receptacle.currentSpeedKey))")
        Text("  链接状态: \(receptacle.linkStatusKey)")
        if let receptacleId = receptacle.receptacleIdKey {
          Text("  接口ID: \(receptacleId)")
        }
        Text("  接口状态: \(USBMonitor.getReadableReceptacleStatus(receptacle.receptacleStatusKey))")
      }

      // 修改这里以处理items可能为nil的情况
      if let items = dataType.items {
        ForEach(items, id: \.name) { device in
          ThunderboltDeviceView(device: device)
        }
      } else {
        Text("无设备")
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
        Text("BCD设备: \(device.bcdDevice ?? "未知")")
        Text("总线功率: \(device.busPower ?? "未知")mA")
        Text("已用总线功率: \(device.busPowerUsed ?? "未知")mA")
        Text("设备速度: \(USBMonitor.getDeviceSpeedString(device.deviceSpeed))")
        Text("额外使用电流: \(device.extraCurrentUsed ?? "未知")mA")
        Text("位置ID: \(device.locationID ?? "未知")")
        Text("制造商: \(device.manufacturer ?? "未知")")
        Text("产品ID: \(device.productID ?? "未知")")
        Text("供应商ID: \(device.vendorID ?? "未知")")
        if let serialNum = device.serialNum {
          Text("序列号: \(serialNum)")
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

// MARK: - ThunderboltDeviceView
struct ThunderboltDeviceView: View {
  let device: ThunderboltDevice
  @State private var isExpanded = false

  var body: some View {
    DisclosureGroup(isExpanded: $isExpanded) {
      VStack(alignment: .leading) {
        Text("设备ID: \(device.deviceIdKey ?? "未知")")
        Text("设备名称: \(device.deviceNameKey ?? "未知")")
        Text("设备版本: \(device.deviceRevisionKey ?? "未知")")
        if let modeKey = device.modeKey {
          Text("模式: \(USBMonitor.getReadableMode(modeKey))")
        }
        Text("路由字符串: \(device.routeStringKey ?? "未知")")
        Text("交换机UID: \(device.switchUidKey ?? "未知")")
        Text("交换机版本: \(device.switchVersionKey ?? "未知")")
        Text("供应商ID: \(device.vendorIdKey ?? "未知")")
        Text("供应商名称: \(device.vendorNameKey ?? "未知")")

        // 显示接口信息
        if let receptacle = device.receptacleUpstreamAmbiguousTag {
          Text("接口信息:")
          Text("  当前速度: \(USBMonitor.getReadableSpeed(receptacle.currentSpeedKey))")
          Text("  链接状态: \(receptacle.linkStatusKey)")
          Text("  接口状态: \(USBMonitor.getReadableReceptacleStatus(receptacle.receptacleStatusKey))")
        }

        // 处理嵌套设备
        if let items = device.items {
          ForEach(items, id: \.name) { nestedDevice in
            ThunderboltDeviceView(device: nestedDevice)
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

// MARK: - MediaView
struct MediaView: View {
  let media: Media
  @State private var isExpanded = false

  var body: some View {
    DisclosureGroup(isExpanded: $isExpanded) {
      VStack(alignment: .leading) {
        Text("BSD名称: \(media.bsdName ?? "未知")")
        Text("逻辑单元: \(media.logicalUnit ?? 0)")
        Text("分区映射类型: \(media.partitionMapType ?? "未知")")
        Text("可移除媒体: \(media.removableMedia ?? "未知")")
        Text("大小: \(media.size ?? "未知")")
        Text("字节大小: \(media.sizeInBytes ?? 0)")
        Text("智能状态: \(media.smartStatus ?? "未知")")
        Text("USB接口: \(media.usbInterface ?? 0)")
        // 修改这里以处理可选的 volumes 数组
        if let volumes = media.volumes {
          ForEach(volumes, id: \.name) { volume in
            VolumeView(volume: volume)
          }
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
      Text("BSD名称: \(volume.bsdName ?? "未知")")
      if let fileSystem = volume.fileSystem {
        Text("文件系统: \(fileSystem)")
      }
      Text("IO内容: \(volume.ioContent ?? "未知")")
      Text("大小: \(volume.size ?? "未知")")
      Text("字节大小: \(volume.sizeInBytes ?? 0)")
      if let volumeUUID = volume.volumeUUID {
        Text("卷UUID: \(volumeUUID)")
      }
      if let freeSpace = volume.freeSpace {
        Text("可用空间: \(freeSpace)")
      }
      if let freeSpaceInBytes = volume.freeSpaceInBytes {
        Text("可用空间字节数: \(freeSpaceInBytes)")
      }
      if let mountPoint = volume.mountPoint {
        Text("挂载点: \(mountPoint)")
      }
      if let writable = volume.writable {
        Text("可写: \(writable)")
      }
    }
  }
}

// 预览 Provider
struct USBDataView_Previews: PreviewProvider {
  static var previews: some View {
    // 创建一个示例 USBData 对象用于预览
    let sampleUSBData = USBData(spusbDataType: [/* 在这里添加USB示例数据 */], spThunderboltDataType: [/* 在这里添加雷电示例数据 */])
    USBDataView(usbData: sampleUSBData)
  }
}
