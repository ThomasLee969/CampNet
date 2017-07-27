//
//  AppDelegate.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/1/17.
//  Copyright © 2017年 Sihan Li. All rights reserved.
//

import NetworkExtension
import UIKit
import UserNotifications

import BRYXBanner
import CampNetKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    static let bannerDuration = 3.0

    var window: UIWindow?

    fileprivate let networkActivityQueue = DispatchQueue(label: "\(Bundle.main.bundleIdentifier!).networkActivityQueue", qos: .userInitiated)
    fileprivate var networkActivityCounter: Int = 0
    
    func setNetworkActivityIndicatorVisible(_ value: Bool) {
        networkActivityQueue.async {
            self.networkActivityCounter += value ? 1 : -1
            UIApplication.shared.isNetworkActivityIndicatorVisible = self.networkActivityCounter > 0
        }
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        requestNotificationAuthorization(options: [.alert, .sound])
        registerHotspotHelper(displayName: NSLocalizedString("Campus network managed by CampNet", comment: "Display name of the HotspotHelper"))
        addObservers()

        return true
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func requestNotificationAuthorization(options: UNAuthorizationOptions) {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: options) { (granted, error) in
            if granted {
                print("User notifications are allowed.")
            } else {
                print("User notifications are not allowed. Error: \(error.debugDescription).")
            }
        }
    }

    func registerHotspotHelper(displayName: String) {
        let options = [kNEHotspotHelperOptionDisplayName: displayName as NSObject]
        let queue = DispatchQueue.global(qos: .utility)

        let result = NEHotspotHelper.register(options: options, queue: queue, handler: Account.handler)
        
        if result {
            print("HotspotHelper registered.")
        } else {
            print("Unable to HotspotHelper registered.")
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        let content = notification.request.content
        let banner = Banner(title: content.title, subtitle: content.body, backgroundColor: #colorLiteral(red: 0.9098039269, green: 0.4784313738, blue: 0.6431372762, alpha: 1))
        banner.show(duration: AppDelegate.bannerDuration)
        
        completionHandler([])
    }
    
    func sendErrorNotification(title: String, body: String, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default()
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
    
    func accountLoginError(_ notification: Notification) {
        guard let account = notification.userInfo?["account"] as? Account,
              let error = notification.userInfo?["error"] as? CampNetError else {
                return
        }
        
        let title = String.localizedStringWithFormat(NSLocalizedString("Unable to Login \"%@\"", comment: "Alert title when failed to login."), account.username)
        sendErrorNotification(title: title, body: error.localizedDescription, identifier: "accountLoginError")
    }
    
    func accountLogoutError(_ notification: Notification) {
        guard let account = notification.userInfo?["account"] as? Account,
              let error = notification.userInfo?["error"] as? CampNetError else {
                return
        }
        
        let title = String.localizedStringWithFormat(NSLocalizedString("Unable to Logout \"%@\"", comment: "Alert title when failed to logout."), account.username)
        sendErrorNotification(title: title, body: error.localizedDescription, identifier: "accountLogoutError")
    }
    
    func accountStatusError(_ notification: Notification) {
        guard let account = notification.userInfo?["account"] as? Account,
              let error = notification.userInfo?["error"] as? CampNetError else {
                return
        }
        
        let title = String.localizedStringWithFormat(NSLocalizedString("Unable to Update Status of \"%@\"", comment: "Alert title when failed to update account status."), account.username)
        sendErrorNotification(title: title, body: error.localizedDescription, identifier: "accountStatusError")
    }
    
    func accountProfileError(_ notification: Notification) {
        guard let account = notification.userInfo?["account"] as? Account,
              let error = notification.userInfo?["error"] as? CampNetError else {
                return
        }
        
        let title = String.localizedStringWithFormat(NSLocalizedString("Unable to Update Profile of \"%@\"", comment: "Alert title when failed to update account profile."), account.username)
        sendErrorNotification(title: title, body: error.localizedDescription, identifier: "accountProfileError")
    }
    
    func accountLoginIpError(_ notification: Notification) {
        guard let ip = notification.userInfo?["ip"] as? String,
              let error = notification.userInfo?["error"] as? CampNetError else {
                return
        }
        
        let title = String.localizedStringWithFormat(NSLocalizedString("Unable to Login %@", comment: "Alert title when failed to login IP."), ip)
        sendErrorNotification(title: title, body: error.localizedDescription, identifier: "accountLoginIpError")
    }
    
    func accountLogoutSessionError(_ notification: Notification) {
        guard let session = notification.userInfo?["session"] as? Session,
              let error = notification.userInfo?["error"] as? CampNetError else {
                return
        }
        
        let title = String.localizedStringWithFormat(NSLocalizedString("Unable to Logout \"%@\"", comment: "Alert title when failed to logout a session."), session.device ?? session.ip)
        sendErrorNotification(title: title, body: error.localizedDescription, identifier: "accountLogoutSessionError")
    }
    
    func accountHistoryError(_ notification: Notification) {
        guard let account = notification.userInfo?["account"] as? Account,
              let error = notification.userInfo?["error"] as? CampNetError else {
                return
        }
        
        let title = String.localizedStringWithFormat(NSLocalizedString("Unable to Update History of \"%@\"", comment: "Alert title when failed to update account history."), account.username)
        sendErrorNotification(title: title, body: error.localizedDescription, identifier: "accountHistoryError")
    }
    
    func addObservers() {
        let selectors: [(Notification.Name, Selector)] = [
            (.accountLoginError, #selector(accountLoginError(_:))),
            (.accountLogoutError, #selector(accountLogoutError(_:))),
            (.accountStatusError, #selector(accountStatusError(_:))),
            (.accountProfileError, #selector(accountProfileError(_:))),
            (.accountLoginIpError, #selector(accountLoginIpError(_:))),
            (.accountLogoutSessionError, #selector(accountLogoutSessionError(_:))),
            (.accountHistoryError, #selector(accountHistoryError(_:)))
        ]
        
        for (name, selector) in selectors {
            NotificationCenter.default.addObserver(self, selector: selector, name: name, object: nil)
        }
    }

}

