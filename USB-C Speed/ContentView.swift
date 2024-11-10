//
//  ContentView.swift
//  USB-C Speed
//
//  Created by zhaoxin on 2024-11-10.
//

import SwiftUI
import IOKit
import IOKit.usb

struct ContentView: View {
  @State private var text = ""
  @State private var structedText = ""
  @State private var usbData: USBData?

  var body: some View {
    if let usbData {
      USBDataView(usbData: usbData)
    } else {
      VStack {
        Image(systemName: "globe")
          .imageScale(.large)
          .foregroundStyle(.tint)
        Text("Hello, world!")

        HStack {
          ScrollView {
            TextEditor(text: $text)
          }
        }
      }
      .padding()
      .task {
        self.text = listUSBDevices()

        let decoder = JSONDecoder()
        let jsonData = Data(text.utf8)

        do {
          let usbData = try decoder.decode(USBData.self, from: jsonData)
          self.usbData = usbData
          print(usbData)
        } catch {
          print(error)
        }
      }
    }
  }

  // 通过system_profiler SPUSBDataType读取USB设备信息
  func listUSBDevices() -> String {
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/sbin/system_profiler")
    task.arguments = ["SPUSBDataType", "-json"]
    let pipe = Pipe()
    task.standardOutput = pipe

    do {
      try task.run()
      let data = pipe.fileHandleForReading.readDataToEndOfFile()
      return String(data: data, encoding: .utf8) ?? ""
    } catch {
      return "Error: \(error.localizedDescription)"
    }
  }
}

#Preview {
  ContentView()
}
