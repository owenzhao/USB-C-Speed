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
        usbHostDataSection
        thunderboltDataSection
      }
      .padding()
    }
  }

  @ViewBuilder
  private var usbHostDataSection: some View {
    ForEach(Array(zip(usbData.spusbHostDataType.indices, usbData.spusbHostDataType)), id: \.0) { _, dataType in
      VStack(alignment: .leading) {
        Text(dataType.name)
          .font(.headline)
        SPUSBHostDataTypeView(dataType: dataType)
      }
    }
  }

  @ViewBuilder
  private var thunderboltDataSection: some View {
    ForEach(Array(zip(usbData.spThunderboltDataType.indices, usbData.spThunderboltDataType)), id: \.0) { _, dataType in
      VStack(alignment: .leading) {
        Text(dataType.name)
          .font(.headline)
        SPThunderboltDataTypeView(dataType: dataType)
      }
    }
  }
}

// MARK: - SPUSBHostDataTypeView
struct SPUSBHostDataTypeView: View {
  let dataType: SPUSBHostDataType

  var body: some View {
    VStack(alignment: .leading) {
      if let driver = dataType.driver {
        Text("Driver: \(driver)")
      }
      if let hardwareType = dataType.hardwareType {
        Text("Hardware Type: \(hardwareType)")
      }
      if let locationID = dataType.locationID {
        Text("Location ID: \(locationID)")
      }

      // Handle devices
      devicesList
    }
  }

  @ViewBuilder
  private var devicesList: some View {
    if let items = dataType.items, !items.isEmpty {
      ForEach(items, id: \.name) { device in
        USBDeviceView(device: device)
      }
    } else {
      Text("No devices")
    }
  }
}

// MARK: - SPThunderboltDataTypeView
struct SPThunderboltDataTypeView: View {
  let dataType: SPThunderboltDataType

  var body: some View {
    VStack(alignment: .leading) {
      Text("Device Name: \(dataType.deviceNameKey)")
      Text("Domain UUID: \(dataType.domainUuidKey)")
      Text("Route String: \(dataType.routeStringKey)")
      Text("Switch UID: \(dataType.switchUidKey)")
      Text("Vendor Name: \(dataType.vendorNameKey)")

      receptacleInfo
      thunderboltDevicesList
    }
  }

  @ViewBuilder
  private var receptacleInfo: some View {
    if let receptacle = dataType.receptacle1Tag {
      VStack(alignment: .leading) {
        Text("Receptacle Info:")
        Text("  Current Speed: \(getReadableSpeed(receptacle.currentSpeedKey))")
        Text("  Link Status: \(receptacle.linkStatusKey)")
        if let receptacleId = receptacle.receptacleIdKey {
          Text("  Receptacle ID: \(receptacleId)")
        }
        Text("  Receptacle Status: \(getReadableReceptacleStatus(receptacle.receptacleStatusKey))")
      }
    }
  }

  @ViewBuilder
  private var thunderboltDevicesList: some View {
    if let items = dataType.items, !items.isEmpty {
      ForEach(items, id: \.name) { device in
        ThunderboltDeviceView(device: device)
      }
    } else {
      Text("No devices")
    }
  }

  private func getReadableSpeed(_ speed: String) -> String {
    return speed // This would be replaced with proper speed formatting
  }

  private func getReadableReceptacleStatus(_ status: String) -> String {
    return status // This would be replaced with proper status formatting
  }
}

// MARK: - USBDeviceView
struct USBDeviceView: View {
  let device: USBDevice
  @State private var isExpanded = false

  var body: some View {
    DisclosureGroup(isExpanded: $isExpanded) {
      deviceDetails
    } label: {
      Text(device.name)
    }
  }

  @ViewBuilder
  private var deviceDetails: some View {
    VStack(alignment: .leading) {
      if let linkSpeed = device.linkSpeed {
        Text("Link Speed: \(linkSpeed)")
      }
      if let productID = device.productID {
        Text("Product ID: \(productID)")
      }
      if let productVersion = device.productVersion {
        Text("Product Version: \(productVersion)")
      }
      if let serialNumber = device.serialNumber {
        Text("Serial Number: \(serialNumber)")
      }
      if let vendorID = device.vendorID {
        Text("Vendor ID: \(vendorID)")
      }
      if let vendorName = device.vendorName {
        Text("Vendor Name: \(vendorName)")
      }
      if let hardwareType = device.hardwareType {
        Text("Hardware Type: \(hardwareType)")
      }
      if let locationID = device.locationID {
        Text("Location ID: \(locationID)")
      }

      nestedDevices
      mediaItems
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.leading, 20)
  }

  @ViewBuilder
  private var nestedDevices: some View {
    if let items = device.items, !items.isEmpty {
      ForEach(items, id: \.name) { nestedDevice in
        USBDeviceView(device: nestedDevice)
          .padding(.leading, 20)
      }
    }
  }

  @ViewBuilder
  private var mediaItems: some View {
    if let media = device.media, !media.isEmpty {
      ForEach(media, id: \.name) { mediaItem in
        MediaView(media: mediaItem)
      }
    }
  }
}

// MARK: - ThunderboltDeviceView
struct ThunderboltDeviceView: View {
  let device: ThunderboltDevice
  @State private var isExpanded = false

  var body: some View {
    DisclosureGroup(isExpanded: $isExpanded) {
      deviceDetails
    } label: {
      Text(device.name)
    }
  }

  @ViewBuilder
  private var deviceDetails: some View {
    VStack(alignment: .leading) {
      if let deviceIdKey = device.deviceIdKey {
        Text("Device ID: \(deviceIdKey)")
      }
      if let deviceNameKey = device.deviceNameKey {
        Text("Device Name: \(deviceNameKey)")
      }
      if let deviceRevisionKey = device.deviceRevisionKey {
        Text("Device Revision: \(deviceRevisionKey)")
      }
      if let modeKey = device.modeKey {
        Text("Mode: \(getReadableMode(modeKey))")
      }
      if let routeStringKey = device.routeStringKey {
        Text("Route String: \(routeStringKey)")
      }
      if let switchUidKey = device.switchUidKey {
        Text("Switch UID: \(switchUidKey)")
      }
      if let switchVersionKey = device.switchVersionKey {
        Text("Switch Version: \(switchVersionKey)")
      }
      if let vendorIdKey = device.vendorIdKey {
        Text("Vendor ID: \(vendorIdKey)")
      }
      if let vendorNameKey = device.vendorNameKey {
        Text("Vendor Name: \(vendorNameKey)")
      }

      receptacleInfo
      nestedDevices
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.leading, 20)
  }

  @ViewBuilder
  private var receptacleInfo: some View {
    if let receptacle = device.receptacleUpstreamAmbiguousTag {
      VStack(alignment: .leading) {
        Text("Receptacle Info:")
        Text("  Current Speed: \(getReadableSpeed(receptacle.currentSpeedKey))")
        Text("  Link Status: \(receptacle.linkStatusKey)")
        Text("  Receptacle Status: \(getReadableReceptacleStatus(receptacle.receptacleStatusKey))")
      }
    }
  }

  @ViewBuilder
  private var nestedDevices: some View {
    if let items = device.items, !items.isEmpty {
      ForEach(items, id: \.name) { nestedDevice in
        ThunderboltDeviceView(device: nestedDevice)
          .padding(.leading, 20)
      }
    }
  }

  private func getReadableSpeed(_ speed: String) -> String {
    return speed // This would be replaced with proper speed formatting
  }

  private func getReadableReceptacleStatus(_ status: String) -> String {
    return status // This would be replaced with proper status formatting
  }

  private func getReadableMode(_ mode: String) -> String {
    return mode // This would be replaced with proper mode formatting
  }
}

// MARK: - MediaView
struct MediaView: View {
  let media: Media
  @State private var isExpanded = false

  var body: some View {
    DisclosureGroup(isExpanded: $isExpanded) {
      mediaDetails
    } label: {
      Text(media.name)
    }
  }

  @ViewBuilder
  private var mediaDetails: some View {
    VStack(alignment: .leading) {
      if let bsdName = media.bsdName {
        Text("BSD Name: \(bsdName)")
      }
      if let logicalUnit = media.logicalUnit {
        Text("Logical Unit: \(logicalUnit)")
      }
      if let partitionMapType = media.partitionMapType {
        Text("Partition Map Type: \(partitionMapType)")
      }
      if let removableMedia = media.removableMedia {
        Text("Removable Media: \(removableMedia)")
      }
      if let size = media.size {
        Text("Size: \(size)")
      }
      if let sizeInBytes = media.sizeInBytes {
        Text("Size in Bytes: \(sizeInBytes)")
      }
      if let smartStatus = media.smartStatus {
        Text("Smart Status: \(smartStatus)")
      }
      if let usbInterface = media.usbInterface {
        Text("USB Interface: \(usbInterface)")
      }

      volumesList
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.leading, 20)
  }

  @ViewBuilder
  private var volumesList: some View {
    if let volumes = media.volumes, !volumes.isEmpty {
      ForEach(volumes, id: \.name) { volume in
        VolumeView(volume: volume)
      }
    }
  }
}

// MARK: - VolumeView
struct VolumeView: View {
  let volume: Volume

  var body: some View {
    VStack(alignment: .leading) {
      if let bsdName = volume.bsdName {
        Text("BSD Name: \(bsdName)")
      }
      if let fileSystem = volume.fileSystem {
        Text("File System: \(fileSystem)")
      }
      if let ioContent = volume.ioContent {
        Text("IO Content: \(ioContent)")
      }
      if let size = volume.size {
        Text("Size: \(size)")
      }
      if let sizeInBytes = volume.sizeInBytes {
        Text("Size in Bytes: \(sizeInBytes)")
      }
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

// MARK: - Preview Provider
struct USBDataView_Previews: PreviewProvider {
  static var previews: some View {
    // Create a sample USBData object for preview
    let sampleUSBData = USBData(
      spusbHostDataType: [
        SPUSBHostDataType(
          items: [
            USBDevice(
              name: "Sample USB Device",
              linkSpeed: "5 Gb/s",
              productID: "0x1234",
              productVersion: "0x0100",
              serialNumber: "123456789",
              vendorID: "0x5678",
              vendorName: "Sample Vendor",
              hardwareType: "Removable",
              locationID: "0x01234567",
              items: nil,
              media: nil
            ),
          ],
          name: "USB 3.1 Bus",
          driver: "AppleT8132USBXHCI",
          hardwareType: "Built-in",
          locationID: "0x02000000"
        ),
      ],
      spThunderboltDataType: []
    )

    USBDataView(usbData: sampleUSBData)
  }
}
