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
  let spThunderboltDataType: [SPThunderboltDataType]

  enum CodingKeys: String, CodingKey {
    case spusbDataType = "SPUSBDataType"
    case spThunderboltDataType = "SPThunderboltDataType"
  }
}

// MARK: - SPUSBDataType
struct SPUSBDataType: Codable {
  let items: [USBDevice]?
  let name: String
  let hostController: String?
  let pciDevice: String?
  let pciRevision: String?
  let pciVendor: String?

  enum CodingKeys: String, CodingKey {
    case items = "_items"
    case name = "_name"
    case hostController = "host_controller"
    case pciDevice = "pci_device"
    case pciRevision = "pci_revision"
    case pciVendor = "pci_vendor"
  }
}

// MARK: - SPThunderboltDataType
struct SPThunderboltDataType: Codable {
  let items: [ThunderboltDevice]?
  let name: String
  let deviceNameKey: String
  let domainUuidKey: String
  let receptacle1Tag: Receptacle?
  let routeStringKey: String
  let switchUidKey: String
  let vendorNameKey: String

  enum CodingKeys: String, CodingKey {
    case items = "_items"
    case name = "_name"
    case deviceNameKey = "device_name_key"
    case domainUuidKey = "domain_uuid_key"
    case receptacle1Tag = "receptacle_1_tag"
    case routeStringKey = "route_string_key"
    case switchUidKey = "switch_uid_key"
    case vendorNameKey = "vendor_name_key"
  }
}

// MARK: - Receptacle
struct Receptacle: Codable {
  let currentSpeedKey: String
  let linkStatusKey: String
  let receptacleIdKey: String?
  let receptacleStatusKey: String

  enum CodingKeys: String, CodingKey {
    case currentSpeedKey = "current_speed_key"
    case linkStatusKey = "link_status_key"
    case receptacleIdKey = "receptacle_id_key"
    case receptacleStatusKey = "receptacle_status_key"
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    currentSpeedKey = try container.decode(String.self, forKey: .currentSpeedKey)
    linkStatusKey = try container.decode(String.self, forKey: .linkStatusKey)
    receptacleIdKey = try container.decodeIfPresent(String.self, forKey: .receptacleIdKey)
    receptacleStatusKey = try container.decode(String.self, forKey: .receptacleStatusKey)
  }
}

// MARK: - ThunderboltDevice
struct ThunderboltDevice: Codable {
  let name: String
  let deviceIdKey: String?
  let deviceNameKey: String?
  let deviceRevisionKey: String?
  let modeKey: String?
  let receptacleUpstreamAmbiguousTag: Receptacle?
  let routeStringKey: String?
  let switchUidKey: String?
  let switchVersionKey: String?
  let vendorIdKey: String?
  let vendorNameKey: String?
  let items: [ThunderboltDevice]?

  enum CodingKeys: String, CodingKey {
    case name = "_name"
    case deviceIdKey = "device_id_key"
    case deviceNameKey = "device_name_key"
    case deviceRevisionKey = "device_revision_key"
    case modeKey = "mode_key"
    case receptacleUpstreamAmbiguousTag = "receptacle_upstream_ambiguous_tag"
    case routeStringKey = "route_string_key"
    case switchUidKey = "switch_uid_key"
    case switchVersionKey = "switch_version_key"
    case vendorIdKey = "vendor_id_key"
    case vendorNameKey = "vendor_name_key"
    case items = "_items"
  }
}

// MARK: - USBDevice
struct USBDevice: Codable, Identifiable {
  let id = UUID()
  let name: String
  let deviceSpeed: String
  let manufacturer: String?
  let serialNum: String?
  let locationID: String?
  let items: [USBDevice]?
  let productID: String?
  let vendorID: String?
  let bcdDevice: String?
  let busPower: String?
  let busPowerUsed: String?
  let extraCurrentUsed: String?
  let media: [Media]?

  enum CodingKeys: String, CodingKey {
    case name = "_name"
    case deviceSpeed = "device_speed"
    case manufacturer
    case serialNum = "serial_num"
    case locationID = "location_id"
    case items = "_items"
    case productID = "product_id"
    case vendorID = "vendor_id"
    case bcdDevice = "bcd_device"
    case busPower = "bus_power"
    case busPowerUsed = "bus_power_used"
    case extraCurrentUsed = "extra_current_used"
    case media = "Media"
  }
}

// MARK: - Media
struct Media: Codable {
  let name: String
  let bsdName: String?
  let logicalUnit: Int?
  let partitionMapType: String?
  let removableMedia: String?
  let size: String?
  let sizeInBytes: Int64?
  let smartStatus: String?
  let usbInterface: Int?
  let volumes: [Volume]?

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
  let bsdName: String?
  let fileSystem: String?
  let ioContent: String?
  let size: String?
  let sizeInBytes: Int64?
  let volumeUUID: String?
  let freeSpace: String?
  let freeSpaceInBytes: Int64?
  let mountPoint: String?
  let writable: String?

  enum CodingKeys: String, CodingKey {
    case name = "_name"
    case bsdName = "bsd_name"
    case fileSystem = "file_system"
    case ioContent = "iocontent"
    case size
    case sizeInBytes = "size_in_bytes"
    case volumeUUID = "volume_uuid"
    case freeSpace = "free_space"
    case freeSpaceInBytes = "free_space_in_bytes"
    case mountPoint = "mount_point"
    case writable
  }
}
