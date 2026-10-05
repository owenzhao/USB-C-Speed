//
//  USBDataView.swift
//  USB-C Speed
//
//  详细视图：显示 system_profiler 报告的全部字段。
//

import SwiftUI

// MARK: - USBDataView
struct USBDataView: View {
  let usbData: USBData
  @Binding var allExpanded: Bool

  var body: some View {
    USBTreeView(usbData: usbData, isDetailed: true, allExpanded: $allExpanded)
  }
}
