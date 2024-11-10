//
//  Model.swift
//  USB-C Speed
//
//  Created by zhaoxin on 2024-11-10.
//

import Foundation

// MARK: - USBData
struct USBData: Codable {
  let spusbDataType: [SPUSBDataType]

  enum CodingKeys: String, CodingKey {
    case spusbDataType = "SPUSBDataType"
  }
}

// MARK: - SPUSBDataType
struct SPUSBDataType: Codable {
  let items: [USBDevice]
  let name: String
  let hostController: String
  let pciDevice, pciRevision, pciVendor: String?

  enum CodingKeys: String, CodingKey {
    case items = "_items"
    case name = "_name"
    case hostController = "host_controller"
    case pciDevice = "pci_device"
    case pciRevision = "pci_revision"
    case pciVendor = "pci_vendor"
  }
}

// MARK: - USBDevice
struct USBDevice: Codable {
  let name: String
  let bcdDevice: String
  let busPower, busPowerUsed: String
  let deviceSpeed: String
  let extraCurrentUsed, locationID: String
  let manufacturer: String
  let media: [Media]?
  let productID, vendorID: String
  let serialNum: String?
  var items: [USBDevice]?

  enum CodingKeys: String, CodingKey {
    case name = "_name"
    case bcdDevice = "bcd_device"
    case busPower = "bus_power"
    case busPowerUsed = "bus_power_used"
    case deviceSpeed = "device_speed"
    case extraCurrentUsed = "extra_current_used"
    case locationID = "location_id"
    case manufacturer
    case media = "Media"
    case productID = "product_id"
    case vendorID = "vendor_id"
    case serialNum = "serial_num"
    case items = "_items"
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    name = try container.decode(String.self, forKey: .name)
    bcdDevice = try container.decode(String.self, forKey: .bcdDevice)
    busPower = try container.decode(String.self, forKey: .busPower)
    busPowerUsed = try container.decode(String.self, forKey: .busPowerUsed)
    deviceSpeed = try container.decode(String.self, forKey: .deviceSpeed)
    extraCurrentUsed = try container.decode(String.self, forKey: .extraCurrentUsed)
    locationID = try container.decode(String.self, forKey: .locationID)
    manufacturer = try container.decode(String.self, forKey: .manufacturer)
    media = try container.decodeIfPresent([Media].self, forKey: .media)
    productID = try container.decode(String.self, forKey: .productID)
    vendorID = try container.decode(String.self, forKey: .vendorID)
    serialNum = try container.decodeIfPresent(String.self, forKey: .serialNum)
    items = try container.decodeIfPresent([USBDevice].self, forKey: .items)
  }
}

// MARK: - Media
struct Media: Codable {
  let name: String
  let bsdName: String
  let logicalUnit: Int
  let partitionMapType: String
  let removableMedia: String
  let size: String
  let sizeInBytes: Int
  let smartStatus: String
  let usbInterface: Int
  let volumes: [Volume]

  enum CodingKeys: String, CodingKey {
    case name = "_name"
    case bsdName = "bsd_name"
    case logicalUnit = "Logical Unit"
    case partitionMapType = "partition_map_type"
    case removableMedia = "removable_media"
    case size
    case sizeInBytes = "size_in_bytes"
    case smartStatus = "smart_status"
    case usbInterface = "USB Interface"
    case volumes
  }
}

// MARK: - Volume
struct Volume: Codable {
  let name: String
  let bsdName: String
  let fileSystem: String?
  let iocontent: String
  let size: String
  let sizeInBytes: Int
  let volumeUUID: String?
  let freeSpace: String?
  let freeSpaceInBytes: Int?  // 更改为Int?类型
  let mountPoint, writable: String?

  enum CodingKeys: String, CodingKey {
    case name = "_name"
    case bsdName = "bsd_name"
    case fileSystem = "file_system"
    case iocontent
    case size
    case sizeInBytes = "size_in_bytes"
    case volumeUUID = "volume_uuid"
    case freeSpace = "free_space"
    case freeSpaceInBytes = "free_space_in_bytes"
    case mountPoint = "mount_point"
    case writable
  }
}
