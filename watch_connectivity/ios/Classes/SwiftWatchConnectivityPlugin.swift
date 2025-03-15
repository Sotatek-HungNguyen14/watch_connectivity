import Flutter
import UIKit
import WatchConnectivity

public class SwiftWatchConnectivityPlugin: NSObject, FlutterPlugin, WCSessionDelegate {
  let channel: FlutterMethodChannel
  let session: WCSession?
    
  init(channel: FlutterMethodChannel) {
    self.channel = channel
        
    if WCSession.isSupported() {
      session = WCSession.default
    } else {
      session = nil
    }
        
    super.init()
        
    session?.delegate = self
    session?.activate()
  }
    
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "watch_connectivity", binaryMessenger: registrar.messenger())
    let instance = SwiftWatchConnectivityPlugin(channel: channel)
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    // Getters
    case "isSupported":
      result(WCSession.isSupported())
    case "isPaired":
      result(session?.isPaired ?? false)
    case "isReachable":
      result(session?.isReachable ?? false)
    case "applicationContext":
      result(session?.applicationContext ?? [:])
    case "receivedApplicationContexts":
      result([session?.receivedApplicationContext ?? [:]])
    // Methods
    case "sendMessage":
      session?.sendMessage(call.arguments as! [String: Any], replyHandler: nil)
      result(nil)
    case "updateApplicationContext":
      do {
        try session?.updateApplicationContext(call.arguments as! [String: Any])
        result(nil)
      } catch {
        result(FlutterError(code: "Error updating application context", message: error.localizedDescription, details: nil))
      }
    // Not implemented
    default:
      result(FlutterMethodNotImplemented)
    }
  }
    
  public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    
  public func sessionDidBecomeInactive(_ session: WCSession) {}
    
  public func sessionDidDeactivate(_ session: WCSession) {}
    
  public func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
    DispatchQueue.main.async {
      self.channel.invokeMethod("didReceiveMessage", arguments: message)
    }
  }
    
  public func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
    DispatchQueue.main.async {
      self.channel.invokeMethod("didReceiveApplicationContext", arguments: applicationContext)
    }
  }
  public func session(_ session: WCSession, didReceive file: WCSessionFile) {
    // In thông tin file để kiểm tra
    print("Đã nhận file từ Apple Watch!")
    print("File URL: \(file.fileURL.path)")
    print("Metadata: \(file.metadata ?? [:])")
    
    // Lưu file vào thư mục Record trong Documents của ứng dụng
    do {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let recordDirectory = documentsDirectory.appendingPathComponent("Record")
        
        // Tạo thư mục Record nếu chưa tồn tại
        if !FileManager.default.fileExists(atPath: recordDirectory.path) {
            try FileManager.default.createDirectory(at: recordDirectory, withIntermediateDirectories: true)
            print("Đã tạo thư mục Record tại: \(recordDirectory.path)")
        }
        
        let fileName = file.fileURL.lastPathComponent
        let destinationURL = recordDirectory.appendingPathComponent(fileName)
        
        // Kiểm tra nếu file đã tồn tại thì xóa trước
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }
        
        // Sao chép file từ vị trí tạm thời vào thư mục Record
        try FileManager.default.copyItem(at: file.fileURL, to: destinationURL)
        
        print("Đã lưu file vào: \(destinationURL.path)")
    } catch {
        print("Lỗi khi lưu file: \(error.localizedDescription)")
    }
  }
}
