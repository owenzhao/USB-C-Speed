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
        usbHostSection
        thunderboltSection
      }
      .padding()
    }
  }

  @ViewBuilder
  private var usbHostSection: some View {
      ForEach(usbData.spusbHostDataType.indices, id: \.self) { index in
        let dataType = usbData.spusbHostDataType[index]
        if let items = dataType.items, !items.isEmpty {
          VStack(alignment: .leading) {
            Text(dataType.name)
              .font(.headline)
            SimplifiedSPUSBDataTypeView(dataType: dataType)
          }
        }
      }
  }

  @ViewBuilder
  private var thunderboltSection: some View {
      ForEach(usbData.spThunderboltDataType.indices, id: \.self) { index in
        let dataType = usbData.spThunderboltDataType[index]
        if let items = dataType.items, !items.isEmpty {
          VStack(alignment: .leading) {
            Text(dataType.name)
              .font(.headline)
            SimplifiedSPThunderboltDataTypeView(dataType: dataType)
          }
        }
      }
  }
}

// MARK: - SimplifiedSPUSBDataTypeView
struct SimplifiedSPUSBDataTypeView: View {
  let dataType: SPUSBHostDataType

  var body: some View {
    if let items = dataType.items {
      ForEach(items, id: \.name) { device in
        SimplifiedUSBDeviceView(device: device)
      }
    } else {
      Text("No devices")
    }
  }
}

// MARK: - SimplifiedSPThunderboltDataTypeView
struct SimplifiedSPThunderboltDataTypeView: View {
  let dataType: SPThunderboltDataType

  var body: some View {
    if let items = dataType.items {
      ForEach(items, id: \.name) { device in
        SimplifiedThunderboltDeviceView(device: device)
      }
    } else {
      Text("No devices")
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
        // Show properties from the JSON structure
        if let linkSpeed = device.linkSpeed {
          Text("Speed: \(linkSpeed)")
        }
        if let vendorName = device.vendorName {
          Text("Vendor: \(vendorName)")
        }
        if let vendorID = device.vendorID {
          Text("Vendor ID: \(vendorID)")
        }
        if let productID = device.productID {
          Text("Product ID: \(productID)")
        }
        if let serialNumber = device.serialNumber {
          Text("Serial Number: \(serialNumber)")
        }
        if let hardwareType = device.hardwareType {
          Text("Hardware Type: \(hardwareType)")
        }

        // Handle nested devices
        nestedDevicesView
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.leading, 20)
    } label: {
      Text(device.name)
    }
  }

  @ViewBuilder
  private var nestedDevicesView: some View {
    if let items = device.items, !items.isEmpty {
      ForEach(items, id: \.name) { nestedDevice in
        SimplifiedUSBDeviceView(device: nestedDevice)
          .padding(.leading, 20)
      }
    }
  }

  // Format device speed string if needed
  func getFormattedSpeed(_ speed: String) -> String {
    if speed.contains("Gb/s") || speed.contains("Mb/s") {
      return speed
    } else {
      return "\(speed) (Unknown)"
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
        if let deviceName = device.deviceNameKey {
          Text("Device Name: \(deviceName)")
        }
        if let vendorName = device.vendorNameKey {
          Text("Vendor Name: \(vendorName)")
        }
        if let modeKey = device.modeKey {
          Text("Mode: \(getReadableMode(modeKey))")
        }

        receptacleInfoView
        nestedDevicesView
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.leading, 20)
    } label: {
      Text(device.name)
    }
  }

  @ViewBuilder
  private var receptacleInfoView: some View {
    if let receptacle = device.receptacleUpstreamAmbiguousTag {
      VStack(alignment: .leading) {
        Text("Connection Info:")
        Text("  Current Speed: \(getReadableSpeed(receptacle.currentSpeedKey))")
        Text("  Link Status: \(receptacle.linkStatusKey)")
        Text("  Receptacle Status: \(getReadableReceptacleStatus(receptacle.receptacleStatusKey))")
      }
    }
  }

  @ViewBuilder
  private var nestedDevicesView: some View {
    if let items = device.items, !items.isEmpty {
      ForEach(items, id: \.name) { nestedDevice in
        SimplifiedThunderboltDeviceView(device: nestedDevice)
          .padding(.leading, 20)
      }
    }
  }

  // Helper methods for formatting display values
  func getReadableSpeed(_ speed: String) -> String {
    return speed // Could be enhanced with specific formatting
  }

  func getReadableReceptacleStatus(_ status: String) -> String {
    return status // Could be enhanced with specific formatting
  }

  func getReadableMode(_ mode: String) -> String {
    switch mode {
    case "0":
      return "Legacy"
    case "1":
      return "Thunderbolt 3"
    case "2":
      return "USB 3.1"
    default:
      return mode
    }
  }
}

// MARK: - Preview Provider
struct SimplifiedUSBDataView_Previews: PreviewProvider {
  static var previews: some View {
    let sampleUsbDevice = USBDevice(
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
    )

    let sampleUSBData = USBData(
      spusbHostDataType: [
        SPUSBHostDataType(
          items: [sampleUsbDevice],
          name: "USB 3.1 Bus",
          driver: "AppleT8132USBXHCI",
          hardwareType: "Built-in",
          locationID: "0x02000000"
        )
      ],
      spThunderboltDataType: []
    )

    SimplifiedUSBDataView(usbData: sampleUSBData)
  }
}
