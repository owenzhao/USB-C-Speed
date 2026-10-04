//
//  MenuBarRootView.swift
//  USB-C Speed
//
//  Created by zhaoxin on 2026-10-04.
//

import SwiftUI
import AppKit

// MARK: - MenuBarRootView
/// 菜单栏弹出窗口的外壳：顶部切换简洁/详细视图，底部放版本号和全局操作。
struct MenuBarRootView: View {
  let usbData: USBData
  var onCheckForUpdates: () -> Void = {}

  @State private var showsDetailedView = false

  private static let compactSize = CGSize(width: 380, height: 520)
  private static let detailedSize = CGSize(width: 460, height: 640)

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        Text("Show More")
        Spacer()
        Toggle("Show More", isOn: $showsDetailedView)
          .labelsHidden()
          .toggleStyle(.switch)
      }
      .padding(.horizontal)
      .padding(.vertical, 8)

      Divider()

      content
        .frame(maxWidth: .infinity, maxHeight: .infinity)

      Divider()

      footer
    }
    .frame(width: panelSize.width, height: panelSize.height)
  }

  @ViewBuilder
  private var content: some View {
    if showsDetailedView {
      USBDataView(usbData: usbData)
    } else {
      ScrollView {
        SimplifiedUSBDataView(usbData: usbData)
      }
    }
  }

  private var footer: some View {
    HStack(spacing: 12) {
      Text(versionText)
        .font(.caption)
        .foregroundStyle(.secondary)

      Spacer()

      Button("Check for Updates…", action: onCheckForUpdates)
        .buttonStyle(.borderless)
      Divider()
        .frame(height: 12)
      Button("Quit") {
        NSApplication.shared.terminate(nil)
      }
      .buttonStyle(.borderless)
    }
    .padding(.horizontal)
    .padding(.vertical, 6)
  }

  private var panelSize: CGSize {
    showsDetailedView ? Self.detailedSize : Self.compactSize
  }

  private var versionText: String {
    let info = Bundle.main.infoDictionary ?? [:]
    let marketingVersion = info["CFBundleShortVersionString"] as? String ?? "—"
    let buildNumber = info["CFBundleVersion"] as? String ?? ""
    return buildNumber.isEmpty ? marketingVersion : "\(marketingVersion) (\(buildNumber))"
  }
}
