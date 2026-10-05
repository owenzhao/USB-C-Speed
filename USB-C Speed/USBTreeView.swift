//
//  USBTreeView.swift
//  USB-C Speed
//
//  统一的设备树：只有两种行——节点行（三角 + 名称 + 右侧速度）和属性行（定宽标签 + 值）。
//  简洁/详细只决定每个节点显示多少字段，树的形状与缩进完全一致。
//

import SwiftUI

// MARK: - 度量
//
// 与系统信息对齐的一组固定值：
// - 三角固定在最左侧一列，所有层级的三角对齐；
// - 每层缩进固定步长；
// - 属性行的标签列定宽，让同一块内的值形成一条竖线。

/// 树的缩进步长。
private let treeIndentStep: CGFloat = 18
/// 三角列宽度。
private let treeDisclosureWidth: CGFloat = 14
/// 属性行标签列宽度。
private let treeLabelColumnWidth: CGFloat = 120
/// 同一层级内相邻节点的间距。
private let treeRowSpacing: CGFloat = 14
/// 节点与其属性/子节点之间的间距。
private let treeGroupSpacing: CGFloat = 24

// MARK: - 属性项

/// 一行属性：标签本地化，值按原样显示。
struct USBPropertyItem {
  let label: LocalizedStringKey
  let value: String

  init(_ label: String, _ value: String) {
    self.label = LocalizedStringKey(label)
    self.value = value
  }
}

/// 详细程度。简洁模式只保留一眼需要的字段，详细模式显示 system_profiler 的全部字段。
enum USBTreeVerbosity {
  case essentials
  case all
}

// MARK: - 树

/// 完整的 USB / Thunderbolt 设备树。
struct USBTreeView: View {
  let usbData: USBData
  var isDetailed = false
  /// 顶部「展开全部 / 收起全部」的一次性广播：值变化时每个节点跟随。
  @Binding var allExpanded: Bool

  init(usbData: USBData, isDetailed: Bool = false, allExpanded: Binding<Bool> = .constant(false)) {
    self.usbData = usbData
    self.isDetailed = isDetailed
    self._allExpanded = allExpanded
  }

  private var verbosity: USBTreeVerbosity { isDetailed ? .all : .essentials }

  /// 简洁模式只列有连接设备的总线；详细模式保留空接口，便于排查端口问题。
  private var usbBuses: [SPUSBHostDataType] {
    isDetailed ? usbData.spusbHostDataType : usbData.spusbHostDataType.filter { hasConnectedDevices($0) }
  }

  /// 整棵树上是否还有设备（USB 主机或雷雳总线上的都算）。
  private var treeHasDevices: Bool {
    usbData.spusbHostDataType.contains(where: hasConnectedDevices)
      || usbData.spThunderboltDataType.contains(where: hasConnectedDevices)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: treeRowSpacing) {
      if treeHasDevices {
        ForEach(usbBuses.indices, id: \.self) { index in
          USBHostNodeView(
            dataType: usbBuses[index],
            verbosity: verbosity,
            allExpanded: $allExpanded
          )
        }

        ForEach(usbData.spThunderboltDataType.indices, id: \.self) { index in
          ThunderboltBusNodeView(
            dataType: usbData.spThunderboltDataType[index],
            verbosity: verbosity,
            allExpanded: $allExpanded
          )
        }
      } else {
        emptyState
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .textSelection(.enabled)
  }

  private var emptyState: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("No devices")
        .font(.callout.weight(.semibold))
      Text("Connect a USB or Thunderbolt device to see its link speed here.")
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .padding(.vertical, 12)
  }
}

// MARK: - USB 主机

struct USBHostNodeView: View {
  let dataType: SPUSBHostDataType
  let verbosity: USBTreeVerbosity
  let allExpanded: Binding<Bool>

  @State private var isExpanded: Bool

  init(dataType: SPUSBHostDataType, verbosity: USBTreeVerbosity, allExpanded: Binding<Bool>) {
    self.dataType = dataType
    self.verbosity = verbosity
    self.allExpanded = allExpanded
    _isExpanded = State(initialValue: true)
  }

  private var devices: [USBDevice] { dataType.items ?? [] }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      treeNodeRow(name: dataType.name, speed: nil, depth: 0, isExpanded: $isExpanded)

      if isExpanded {
        if verbosity == .all {
          treePropertyRows(rows: usbHostProperties(dataType), depth: 0)
        }

        if devices.isEmpty {
          treeNoteRow("No devices", depth: 0)
            .padding(.top, 10)
        } else {
          VStack(alignment: .leading, spacing: treeRowSpacing) {
            ForEach(devices.indices, id: \.self) { index in
              USBDeviceNodeView(
                device: devices[index],
                depth: 1,
                verbosity: verbosity,
                allExpanded: allExpanded
              )
            }
          }
          .padding(.top, treeGroupSpacing)
        }
      }
    }
    .onChange(of: allExpanded.wrappedValue) { _, newValue in
      isExpanded = newValue
    }
  }
}

// MARK: - Thunderbolt 总线

struct ThunderboltBusNodeView: View {
  let dataType: SPThunderboltDataType
  let verbosity: USBTreeVerbosity
  let allExpanded: Binding<Bool>

  @State private var isExpanded: Bool

  init(dataType: SPThunderboltDataType, verbosity: USBTreeVerbosity, allExpanded: Binding<Bool>) {
    self.dataType = dataType
    self.verbosity = verbosity
    self.allExpanded = allExpanded
    _isExpanded = State(initialValue: false)
  }

  private var devices: [ThunderboltDevice] { dataType.items ?? [] }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      treeNodeRow(
        name: thunderboltBusName(dataType.name),
        speed: nil,
        depth: 0,
        isExpanded: $isExpanded
      )

      if isExpanded {
        treePropertyRows(rows: thunderboltBusProperties(dataType, verbosity: verbosity), depth: 0)

        if devices.isEmpty {
          treeNoteRow("No devices", depth: 0)
            .padding(.top, 10)
        } else {
          VStack(alignment: .leading, spacing: treeRowSpacing) {
            ForEach(devices.indices, id: \.self) { index in
              ThunderboltDeviceNodeView(
                device: devices[index],
                depth: 1,
                verbosity: verbosity,
                allExpanded: allExpanded
              )
            }
          }
          .padding(.top, treeGroupSpacing)
        }
      }
    }
    .onChange(of: allExpanded.wrappedValue) { _, newValue in
      isExpanded = newValue
    }
  }
}

// MARK: - USB 设备

struct USBDeviceNodeView: View {
  let device: USBDevice
  let depth: Int
  let verbosity: USBTreeVerbosity
  let allExpanded: Binding<Bool>

  @State private var isExpanded: Bool

  init(device: USBDevice, depth: Int, verbosity: USBTreeVerbosity, allExpanded: Binding<Bool>) {
    self.device = device
    self.depth = depth
    self.verbosity = verbosity
    self.allExpanded = allExpanded
    _isExpanded = State(initialValue: false)
  }

  private var children: [USBDevice] { device.items ?? [] }
  private var media: [Media] { device.media ?? [] }
  private var hasChildren: Bool { !children.isEmpty || !media.isEmpty }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      if hasChildren {
        treeNodeRow(
          name: device.name,
          speed: usbDeviceSpeed(device),
          depth: depth,
          isExpanded: $isExpanded
        )
      } else {
        treeLeafRow(
          name: device.name,
          speed: usbDeviceSpeed(device),
          depth: depth
        )
      }

      if isExpanded {
        treePropertyRows(rows: usbDeviceProperties(device, verbosity: verbosity), depth: depth + 1)

        if !children.isEmpty {
          VStack(alignment: .leading, spacing: treeRowSpacing) {
            ForEach(children.indices, id: \.self) { index in
              USBDeviceNodeView(
                device: children[index],
                depth: depth + 1,
                verbosity: verbosity,
                allExpanded: allExpanded
              )
            }
          }
          .padding(.top, treeGroupSpacing)
        }

        if !media.isEmpty {
          VStack(alignment: .leading, spacing: treeRowSpacing) {
            ForEach(media.indices, id: \.self) { index in
              MediaNodeView(
                media: media[index],
                depth: depth + 1,
                verbosity: verbosity,
                allExpanded: allExpanded
              )
            }
          }
          .padding(.top, treeGroupSpacing)
        }
      }
    }
    .onChange(of: allExpanded.wrappedValue) { _, newValue in
      isExpanded = newValue
    }
  }
}

// MARK: - Thunderbolt 设备

struct ThunderboltDeviceNodeView: View {
  let device: ThunderboltDevice
  let depth: Int
  let verbosity: USBTreeVerbosity
  let allExpanded: Binding<Bool>

  @State private var isExpanded: Bool

  init(device: ThunderboltDevice, depth: Int, verbosity: USBTreeVerbosity, allExpanded: Binding<Bool>) {
    self.device = device
    self.depth = depth
    self.verbosity = verbosity
    self.allExpanded = allExpanded
    _isExpanded = State(initialValue: false)
  }

  private var children: [ThunderboltDevice] { device.items ?? [] }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      if children.isEmpty {
        treeLeafRow(name: device.name, speed: thunderboltSpeed(device), depth: depth)
      } else {
        treeNodeRow(
          name: device.name,
          speed: thunderboltSpeed(device),
          depth: depth,
          isExpanded: $isExpanded
        )
      }

      if isExpanded {
        treePropertyRows(rows: thunderboltDeviceProperties(device, verbosity: verbosity), depth: depth + 1)

        if !children.isEmpty {
          VStack(alignment: .leading, spacing: treeRowSpacing) {
            ForEach(children.indices, id: \.self) { index in
              ThunderboltDeviceNodeView(
                device: children[index],
                depth: depth + 1,
                verbosity: verbosity,
                allExpanded: allExpanded
              )
            }
          }
          .padding(.top, treeGroupSpacing)
        }
      }
    }
    .onChange(of: allExpanded.wrappedValue) { _, newValue in
      isExpanded = newValue
    }
  }
}

// MARK: - 介质与卷

struct MediaNodeView: View {
  let media: Media
  let depth: Int
  let verbosity: USBTreeVerbosity
  let allExpanded: Binding<Bool>

  @State private var isExpanded: Bool

  init(media: Media, depth: Int, verbosity: USBTreeVerbosity, allExpanded: Binding<Bool>) {
    self.media = media
    self.depth = depth
    self.verbosity = verbosity
    self.allExpanded = allExpanded
    _isExpanded = State(initialValue: false)
  }

  private var volumes: [Volume] { media.volumes ?? [] }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      if volumes.isEmpty {
        treeLeafRow(name: media.name, speed: nil, depth: depth)
      } else {
        treeNodeRow(name: media.name, speed: nil, depth: depth, isExpanded: $isExpanded)
      }

      if isExpanded {
        treePropertyRows(rows: mediaProperties(media, verbosity: verbosity), depth: depth + 1)

        if !volumes.isEmpty {
          VStack(alignment: .leading, spacing: treeRowSpacing) {
            ForEach(volumes.indices, id: \.self) { index in
              VolumeNodeView(
                volume: volumes[index],
                depth: depth + 1,
                verbosity: verbosity
              )
            }
          }
          .padding(.top, treeGroupSpacing)
        }
      }
    }
    .onChange(of: allExpanded.wrappedValue) { _, newValue in
      isExpanded = newValue
    }
  }
}

struct VolumeNodeView: View {
  let volume: Volume
  let depth: Int
  let verbosity: USBTreeVerbosity

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      treeLeafRow(name: volume.name, speed: nil, depth: depth)
      treePropertyRows(rows: volumeProperties(volume, verbosity: verbosity), depth: depth + 1)
    }
  }
}

// MARK: - 行

/// 可展开的节点行：三角列 + 名称 + 右侧速度。
@ViewBuilder
private func treeNodeRow(
  name: String,
  speed: String?,
  depth: Int,
  isExpanded: Binding<Bool>
) -> some View {
  Button {
    withAnimation(.easeInOut(duration: 0.15)) {
      isExpanded.wrappedValue.toggle()
    }
  } label: {
    HStack(spacing: 0) {
      Image(systemName: "chevron.right")
        .font(.system(size: 9, weight: .semibold))
        .foregroundStyle(.secondary)
        .frame(width: treeDisclosureWidth, alignment: .leading)
        .rotationEffect(.degrees(isExpanded.wrappedValue ? 90 : 0))

      treeNodeLabel(name: name, speed: speed)
    }
    .padding(.leading, CGFloat(depth) * treeIndentStep)
    .padding(.vertical, 3)
    .contentShape(Rectangle())
  }
  .buttonStyle(.plain)
}

/// 叶子节点行：三角列留空，保证名称与其它层级对齐。
@ViewBuilder
private func treeLeafRow(name: String, speed: String?, depth: Int) -> some View {
  HStack(spacing: 0) {
    Color.clear.frame(width: treeDisclosureWidth, height: 1)
    treeNodeLabel(name: name, speed: speed)
  }
  .padding(.leading, CGFloat(depth) * treeIndentStep)
  .padding(.vertical, 3)
  .frame(maxWidth: .infinity, alignment: .leading)
}

/// 节点行内容：名称 + 右侧速度列（等宽数字，便于纵向比较）。
@ViewBuilder
private func treeNodeLabel(name: String, speed: String?) -> some View {
  HStack(spacing: 8) {
    Text(verbatim: name)
      .lineLimit(1)
      .truncationMode(.middle)
      .layoutPriority(1)

    Spacer(minLength: 8)

    if let speed, !speed.isEmpty {
      Text(verbatim: speed)
        .monospacedDigit()
        .foregroundStyle(.secondary)
        .lineLimit(1)
    }
  }
  .frame(maxWidth: .infinity, alignment: .leading)
}

/// 属性块：不参与交互，标签列定宽，值左对齐形成竖线。
@ViewBuilder
private func treePropertyRows(rows: [USBPropertyItem], depth: Int) -> some View {
  if !rows.isEmpty {
    VStack(alignment: .leading, spacing: 0) {
      ForEach(rows.indices, id: \.self) { index in
        treePropertyRow(rows[index], depth: depth)
      }
    }
    .padding(.top, 4)
  }
}

@ViewBuilder
private func treePropertyRow(_ item: USBPropertyItem, depth: Int) -> some View {
  HStack(alignment: .firstTextBaseline, spacing: 6) {
    Text(item.label)
      .foregroundStyle(.secondary)
      .lineLimit(1)
      .frame(width: treeLabelColumnWidth, alignment: .leading)

    Text(verbatim: item.value)
      .monospacedDigit()
      .lineLimit(1)
      .truncationMode(.middle)
      .frame(maxWidth: .infinity, alignment: .leading)
  }
  .font(.system(size: 12))
  .padding(.leading, CGFloat(depth) * treeIndentStep + treeDisclosureWidth)
  .padding(.vertical, 1)
}

/// 说明行：例如「没有设备」，与属性行同缩进但不成键值对。
@ViewBuilder
private func treeNoteRow(_ text: String, depth: Int) -> some View {
  Text(text)
    .font(.callout)
    .foregroundStyle(.tertiary)
    .padding(.leading, CGFloat(depth) * treeIndentStep + treeDisclosureWidth)
}

// MARK: - 属性构建

private func usbHostProperties(_ dataType: SPUSBHostDataType) -> [USBPropertyItem] {
  var rows: [USBPropertyItem] = []
  if let driver = dataType.driver {
    rows.append(USBPropertyItem("Driver", driver))
  }
  if let hardwareType = dataType.hardwareType {
    rows.append(USBPropertyItem("Connection Type", hardwareType))
  }
  if let locationID = dataType.locationID {
    rows.append(USBPropertyItem("Location ID", locationID))
  }
  return rows
}

private func usbDeviceProperties(_ device: USBDevice, verbosity: USBTreeVerbosity) -> [USBPropertyItem] {
  var rows: [USBPropertyItem] = []
  if let vendorName = device.vendorName {
    rows.append(USBPropertyItem("Vendor", vendorName))
  }
  if verbosity == .all {
    if let vendorID = device.vendorID {
      rows.append(USBPropertyItem("Vendor ID", vendorID))
    }
    if let productID = device.productID {
      rows.append(USBPropertyItem("Product ID", productID))
    }
    if let productVersion = device.productVersion {
      rows.append(USBPropertyItem("Product Version", productVersion))
    }
    if let serialNumber = device.serialNumber {
      rows.append(USBPropertyItem("Serial Number", serialNumber))
    }
  }
  if let hardwareType = device.hardwareType {
    rows.append(USBPropertyItem("Connection Type", hardwareType))
  }
  if let locationID = device.locationID {
    rows.append(USBPropertyItem("Location ID", locationID))
  }
  if verbosity == .all {
    if let powerSinkCapability = device.powerSinkCapability {
      rows.append(USBPropertyItem("Power Sink Capability", powerSinkCapability))
    }
    if let powerAllocated = device.powerAllocated {
      rows.append(USBPropertyItem("Power Allocated", powerAllocated))
    }
  }
  if let battery = device.bluetoothBattery {
    let level = "\(battery.level)%"
    if battery.isCharging {
      rows.append(USBPropertyItem("Bluetooth Battery Level", "\(level) · \(String(localized: "Charging"))"))
    } else {
      rows.append(USBPropertyItem("Bluetooth Battery Level", level))
    }
  }
  return rows
}

private func thunderboltBusProperties(_ dataType: SPThunderboltDataType, verbosity: USBTreeVerbosity) -> [USBPropertyItem] {
  var rows: [USBPropertyItem] = []
  if let receptacle = dataType.receptacle1Tag {
    rows.append(USBPropertyItem("Speed", receptacle.currentSpeedKey))
    rows.append(USBPropertyItem("Link Status", thunderboltLinkStatus(receptacle.linkStatusKey)))
    if verbosity == .all, let receptacleID = receptacle.receptacleIdKey {
      rows.append(USBPropertyItem("Receptacle ID", receptacleID))
    }
    rows.append(USBPropertyItem("Port Status", thunderboltReceptacleStatus(receptacle.receptacleStatusKey)))
  }
  if verbosity == .all {
    rows.append(USBPropertyItem("Route String", dataType.routeStringKey))
    rows.append(USBPropertyItem("Switch UID", dataType.switchUidKey))
    rows.append(USBPropertyItem("Domain UUID", dataType.domainUuidKey))
  }
  return rows
}

private func thunderboltDeviceProperties(_ device: ThunderboltDevice, verbosity: USBTreeVerbosity) -> [USBPropertyItem] {
  var rows: [USBPropertyItem] = []
  if let speed = thunderboltSpeed(device) {
    rows.append(USBPropertyItem("Speed", speed))
  }
  if let vendorName = device.vendorNameKey {
    rows.append(USBPropertyItem("Vendor", vendorName))
  }
  if verbosity == .all {
    if let deviceID = device.deviceIdKey {
      rows.append(USBPropertyItem("Device ID", deviceID))
    }
    if let vendorID = device.vendorIdKey {
      rows.append(USBPropertyItem("Vendor ID", vendorID))
    }
    if let deviceRevision = device.deviceRevisionKey {
      rows.append(USBPropertyItem("Device Revision", deviceRevision))
    }
    if let mode = device.modeKey {
      rows.append(USBPropertyItem("Mode", thunderboltMode(mode)))
    }
    if let routeString = device.routeStringKey {
      rows.append(USBPropertyItem("Route String", routeString))
    }
    if let switchUID = device.switchUidKey {
      rows.append(USBPropertyItem("Switch UID", switchUID))
    }
    if let switchVersion = device.switchVersionKey {
      rows.append(USBPropertyItem("Switch Version", switchVersion))
    }
    if let receptacle = device.receptacleUpstreamAmbiguousTag {
      rows.append(USBPropertyItem("Link Status", thunderboltLinkStatus(receptacle.linkStatusKey)))
      rows.append(USBPropertyItem("Port Status", thunderboltReceptacleStatus(receptacle.receptacleStatusKey)))
    }
  }
  return rows
}

private func mediaProperties(_ media: Media, verbosity: USBTreeVerbosity) -> [USBPropertyItem] {
  var rows: [USBPropertyItem] = []
  if let size = media.size {
    rows.append(USBPropertyItem("Size", size))
  }
  if let bsdName = media.bsdName {
    rows.append(USBPropertyItem("BSD Name", bsdName))
  }
  if verbosity == .all {
    if let logicalUnit = media.logicalUnit {
      rows.append(USBPropertyItem("Logical Unit", "\(logicalUnit)"))
    }
    if let partitionMapType = media.partitionMapType {
      rows.append(USBPropertyItem("Partition Map Type", partitionMapType))
    }
    if let removableMedia = media.removableMedia {
      rows.append(USBPropertyItem("Removable Media", removableMedia))
    }
    if let smartStatus = media.smartStatus {
      rows.append(USBPropertyItem("S.M.A.R.T. Status", smartStatus))
    }
    if let usbInterface = media.usbInterface {
      rows.append(USBPropertyItem("USB Interface", "\(usbInterface)"))
    }
  }
  return rows
}

private func volumeProperties(_ volume: Volume, verbosity: USBTreeVerbosity) -> [USBPropertyItem] {
  var rows: [USBPropertyItem] = []
  if let mountPoint = volume.mountPoint {
    rows.append(USBPropertyItem("Mount Point", mountPoint))
  }
  if let fileSystem = volume.fileSystem {
    rows.append(USBPropertyItem("File System", fileSystem))
  }
  if let size = volume.size {
    rows.append(USBPropertyItem("Size", size))
  }
  if let freeSpace = volume.freeSpace {
    rows.append(USBPropertyItem("Free Space", freeSpace))
  }
  if let writable = volume.writable {
    rows.append(USBPropertyItem("Writable", writable))
  }
  if verbosity == .all {
    if let bsdName = volume.bsdName {
      rows.append(USBPropertyItem("BSD Name", bsdName))
    }
    if let ioContent = volume.ioContent {
      rows.append(USBPropertyItem("IO Content", ioContent))
    }
    if let volumeUUID = volume.volumeUUID {
      rows.append(USBPropertyItem("Volume UUID", volumeUUID))
    }
  }
  return rows
}

// MARK: - 名称与取值

/// 总线上是否挂着设备（含 hub 的子树）。
func hasConnectedDevices(_ dataType: SPUSBHostDataType) -> Bool {
  !(dataType.items ?? []).isEmpty
}

func hasConnectedDevices(_ dataType: SPThunderboltDataType) -> Bool {
  !(dataType.items ?? []).isEmpty
}

/// 节点行右侧显示的速度。
func usbDeviceSpeed(_ device: USBDevice) -> String? {
  device.linkSpeed
}

/// 端口上报的当前链路速度。
func thunderboltSpeed(_ device: ThunderboltDevice) -> String? {
  device.receptacleUpstreamAmbiguousTag?.currentSpeedKey
}

/// system_profiler 把 Thunderbolt / USB4 总线报成 `thunderboltusb4_bus_3` 这类 key，
/// 显示前翻译成产品语言。
func thunderboltBusName(_ raw: String) -> String {
  guard raw.hasPrefix("thunderboltusb4_bus_") else { return raw }
  let index = raw.dropFirst("thunderboltusb4_bus_".count)
  return String(localized: "Thunderbolt / USB4 Bus \(index)")
}

/// 端口链路状态：优先按已知取值翻译，未知取值退化为人类可读的短语。
func thunderboltLinkStatus(_ raw: String) -> String {
  switch raw {
  case "0x2": String(localized: "Active")
  case "0x100": String(localized: "Inactive")
  default: humanizedStatus(raw)
  }
}

/// 端口状态：`receptacle_no_devices_connected` 这类 token 显示成正常文案。
func thunderboltReceptacleStatus(_ raw: String) -> String {
  switch raw {
  case "receptacle_connected": String(localized: "Connected")
  case "receptacle_no_devices_connected": String(localized: "No Device Connected")
  default: humanizedStatus(raw)
  }
}

private func humanizedStatus(_ raw: String) -> String {
  guard raw.contains("_") else { return raw }
  return raw
    .split(separator: "_")
    .map { $0.prefix(1).uppercased() + $0.dropFirst() }
    .joined(separator: " ")
}

private func thunderboltMode(_ raw: String) -> String {
  switch raw {
  case "0": String(localized: "Legacy")
  case "1": String(localized: "Thunderbolt 3")
  case "2": String(localized: "USB 3.1")
  case "usb_four": String(localized: "USB4")
  default: raw
  }
}
