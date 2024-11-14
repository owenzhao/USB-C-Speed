//
//  USBNotificationCenter.swift
//  USB-C Speed
//
//  Created by zhaoxin on 2024-11-13.
//
//
import Foundation
import IOKit
import IOKit.usb
import IOKit.network

// 通过IOKit获取USB设备和雷电设备插拔的通知，然后将其转发为普通的通知
class USBNotificationCenter {
  // 只保留一个通知端口
  private var notificationPort: IONotificationPortRef?
  // 取消USB设备迭代器的注释
  private var usbAddedIterator: io_iterator_t = 0
  private var usbRemovedIterator: io_iterator_t = 0
  private var thunderboltAddedIterator: io_iterator_t = 0
  private var thunderboltRemovedIterator: io_iterator_t = 0

  // 只保留一个通知名称
  static let deviceChangeNotification = Notification.Name("DeviceChangeNotification")

  init() {
    // 在初始化时调用注册函数
    registerForDeviceNotifications()
  }

  private func registerForDeviceNotifications() {
    // 创建通知端口
    notificationPort = IONotificationPortCreate(kIOMainPortDefault)
    guard let notificationPort = notificationPort else {
      print("创建通知端口失败")
      return
    }

    // 获取运行循环源并添加到主运行循环
    let runLoopSource = IONotificationPortGetRunLoopSource(notificationPort).takeRetainedValue()
    CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .defaultMode)

    // 取消USB设备通知注册的注释
    registerNotification(for: kIOUSBDeviceClassName, added: &usbAddedIterator, removed: &usbRemovedIterator)

    // 注册雷电设备通知
    registerNotification(for: "IOPCIDevice", added: &thunderboltAddedIterator, removed: &thunderboltRemovedIterator)
  }

  private func registerNotification(for className: String, added: UnsafeMutablePointer<io_iterator_t>, removed: UnsafeMutablePointer<io_iterator_t>) {
    let matchingDict = IOServiceMatching(className)

    // 使用一个包装函数来处理设备添加
    let addCallback: IOServiceMatchingCallback = { (_, iterator) in
      // 只发送一次通知
      print("设备添加")
      NotificationCenter.default.post(name: USBNotificationCenter.deviceChangeNotification, object: nil)
      // 清空迭代器
      while IOIteratorNext(iterator) != IO_OBJECT_NULL { }
    }

    // 使用一个包装函数来处理设备移除
    let removeCallback: IOServiceMatchingCallback = { (_, iterator) in
      // 只发送一次通知
      print("设备移除")
      NotificationCenter.default.post(name: USBNotificationCenter.deviceChangeNotification, object: nil)
      // 清空迭代器
      while IOIteratorNext(iterator) != IO_OBJECT_NULL { }
    }

    IOServiceAddMatchingNotification(notificationPort, kIOFirstMatchNotification, matchingDict, addCallback, nil, added)
    IOServiceAddMatchingNotification(notificationPort, kIOTerminatedNotification, matchingDict, removeCallback, nil, removed)

    // 遍历现有设备以激活通知
    addCallback(nil, added.pointee)
    removeCallback(nil, removed.pointee)
  }
}
