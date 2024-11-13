//
//  USBNotificationCenter.swift
//  USB-C Speed
//
//  Created by zhaoxin on 2024-11-13.
//

import Foundation
import IOKit
import IOKit.usb

// 通过IOKit获取USB设备和雷电设备插拔的通知，然后将其转发为普通的通知
class USBNotificationCenter {
  private var notificationPort: IONotificationPortRef?
  private var usbAddedIterator: io_iterator_t = 0
  private var usbRemovedIterator: io_iterator_t = 0
  private var thunderboltAddedIterator: io_iterator_t = 0
  private var thunderboltRemovedIterator: io_iterator_t = 0

  // 通知名称常量
  static let usbDeviceAddedNotification = Notification.Name("USBDeviceAddedNotification")
  static let usbDeviceRemovedNotification = Notification.Name("USBDeviceRemovedNotification")
  static let thunderboltDeviceAddedNotification = Notification.Name("ThunderboltDeviceAddedNotification")
  static let thunderboltDeviceRemovedNotification = Notification.Name("ThunderboltDeviceRemovedNotification")

  init() {
    // 在初始化时调用注册函数
    registerForUSBNotifications()
    registerForThunderboltNotifications()
  }

  private func registerForUSBNotifications() {
    // 创建通知端口
    notificationPort = IONotificationPortCreate(kIOMainPortDefault)
    guard let notificationPort = notificationPort else {
      print("创建通知端口失败")
      return
    }

    // 获取运行循环源并添加到当前运行循环
    let runLoopSource = IONotificationPortGetRunLoopSource(notificationPort).takeRetainedValue()
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .defaultMode)

    // 创建匹配字典以匹配 USB 设备
    let matchingDict = IOServiceMatching(kIOUSBDeviceClassName)

    // 定义 USB 设备添加回调
    let addCallback: IOServiceMatchingCallback = { (_, iterator) in
      print("USB设备已添加")
      // 只处理第一个设备
      let object = IOIteratorNext(iterator)
      if object != IO_OBJECT_NULL {
        // 发送添加设备的通知
        NotificationCenter.default.post(name: USBNotificationCenter.usbDeviceAddedNotification, object: nil)
        IOObjectRelease(object)
      } else {
        NotificationCenter.default.post(name: USBNotificationCenter.usbDeviceRemovedNotification, object: nil)
      }
      // 清空剩余的迭代器
      while IOIteratorNext(iterator) != IO_OBJECT_NULL { }
    }

    // 定义 USB 设备移除回调
    let removeCallback: IOServiceMatchingCallback = { (_, iterator) in
      print("USB设备已移除")
      // 只处理第一个设备
      let object = IOIteratorNext(iterator)
      if object != IO_OBJECT_NULL {
        // 发送移除设备的通知
        NotificationCenter.default.post(name: USBNotificationCenter.usbDeviceRemovedNotification, object: nil)
        IOObjectRelease(object)
      } else {
        NotificationCenter.default.post(name: USBNotificationCenter.usbDeviceRemovedNotification, object: nil)
      }
      // 清空剩余的迭代器
      while IOIteratorNext(iterator) != IO_OBJECT_NULL { }
    }

    // 注册 USB 设备添加和移除通知
    IOServiceAddMatchingNotification(notificationPort, kIOFirstMatchNotification, matchingDict, addCallback, nil, &usbAddedIterator)
    IOServiceAddMatchingNotification(notificationPort, kIOTerminatedNotification, matchingDict, removeCallback, nil, &usbRemovedIterator)

    // 遍历现有设备以激活通知
    addCallback(nil, usbAddedIterator)
    removeCallback(nil, usbRemovedIterator)
  }

  private func registerForThunderboltNotifications() {
    // 创建通知端口（如果尚未创建）
    if notificationPort == nil {
      notificationPort = IONotificationPortCreate(kIOMainPortDefault)
      guard let notificationPort = notificationPort else {
        print("创建通知端口失败")
        return
      }
      // 获取运行循环源并添加到当前运行循环
      let runLoopSource = IONotificationPortGetRunLoopSource(notificationPort).takeRetainedValue()
      CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .defaultMode)
    }

    // 创建匹配字典以匹配雷电设备
    let matchingDict = IOServiceMatching("AppleThunderboltHALType")

    // 定义雷电设备添加回调
    let addCallback: IOServiceMatchingCallback = { (_, iterator) in
      print("雷电设备已添加")
      let object = IOIteratorNext(iterator)
      if object != IO_OBJECT_NULL {
        NotificationCenter.default.post(name: USBNotificationCenter.thunderboltDeviceAddedNotification, object: nil)
        IOObjectRelease(object)
      }
      while IOIteratorNext(iterator) != IO_OBJECT_NULL { }
    }

    // 定义雷电设备移除回调
    let removeCallback: IOServiceMatchingCallback = { (_, iterator) in
      print("雷电设备已移除")
      let object = IOIteratorNext(iterator)
      if object != IO_OBJECT_NULL {
        NotificationCenter.default.post(name: USBNotificationCenter.thunderboltDeviceRemovedNotification, object: nil)
        IOObjectRelease(object)
      }
      while IOIteratorNext(iterator) != IO_OBJECT_NULL { }
    }

    // 注册雷电设备添加和移除通知
    IOServiceAddMatchingNotification(notificationPort, kIOFirstMatchNotification, matchingDict, addCallback, nil, &thunderboltAddedIterator)
    IOServiceAddMatchingNotification(notificationPort, kIOTerminatedNotification, matchingDict, removeCallback, nil, &thunderboltRemovedIterator)

    // 遍历现有设备以激活通知
    addCallback(nil, thunderboltAddedIterator)
    removeCallback(nil, thunderboltRemovedIterator)
  }
}

// 文件结束。没有额外的代码。
