//
//  MenuBarRootView.swift
//  USB-C Speed
//
//  菜单栏弹出窗口的外壳：顶部用开关切换简洁/详细，底部放版本号和全局操作。
//

import SwiftUI
import AppKit

// MARK: - MenuBarRootView
struct MenuBarRootView: View {
  let usbData: USBData
  var onCheckForUpdates: () -> Void = {}

  @State private var showsDetailedView = false
  /// 控制整棵树：切换时所有节点一起展开或收起。
  @State private var allExpanded = false

  /// 两种视图共用同一棵树，只改宽度会让窗口在切换时跳一下，所以宽度固定。
  private static let panelWidth: CGFloat = 460
  private static let compactHeight: CGFloat = 520
  private static let detailedHeight: CGFloat = 660

  var body: some View {
    VStack(spacing: 0) {
      toolbar

      Divider()

      ScrollView {
        content
          .padding(.horizontal, 14)
          .padding(.top, 12)
          .padding(.bottom, 10)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)

      Divider()

      footer
    }
    .frame(width: Self.panelWidth, height: panelHeight)
  }

  private var toolbar: some View {
    HStack(spacing: 12) {
      Toggle("Show More", isOn: $showsDetailedView)
        .toggleStyle(.switch)
        .controlSize(.small)

      Spacer(minLength: 8)

      Button {
        allExpanded.toggle()
      } label: {
        Label {
          Text(allExpanded ? "Collapse All" : "Expand All")
        } icon: {
          Image(systemName: allExpanded
                ? "rectangle.compress.vertical"
                : "rectangle.expand.vertical")
        }
        .font(.callout)
      }
      .buttonStyle(.borderless)
      .help(allExpanded ? "Collapse Every Node" : "Expand Every Node")
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 8)
  }

  @ViewBuilder
  private var content: some View {
    if showsDetailedView {
      USBDataView(usbData: usbData, allExpanded: $allExpanded)
    } else {
      SimplifiedUSBDataView(usbData: usbData, allExpanded: $allExpanded)
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
    .padding(.horizontal, 14)
    .padding(.vertical, 6)
  }

  private var panelHeight: CGFloat {
    showsDetailedView ? Self.detailedHeight : Self.compactHeight
  }

  private var versionText: String {
    let info = Bundle.main.infoDictionary ?? [:]
    let marketingVersion = info["CFBundleShortVersionString"] as? String ?? "—"
    let buildNumber = info["CFBundleVersion"] as? String ?? ""
    return buildNumber.isEmpty ? marketingVersion : "\(marketingVersion) (\(buildNumber))"
  }
}
