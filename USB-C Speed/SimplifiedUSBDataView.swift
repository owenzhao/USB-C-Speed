//
//  SimplifiedUSBDataView.swift
//  USB-C Speed
//
//  简洁视图：同一棵设备树，只保留常用字段。
//

import SwiftUI

// MARK: - SimplifiedUSBDataView
struct SimplifiedUSBDataView: View {
  let usbData: USBData
  @Binding var allExpanded: Bool

  var body: some View {
    USBTreeView(usbData: usbData, isDetailed: false, allExpanded: $allExpanded)
  }
}
