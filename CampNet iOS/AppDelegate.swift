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

import CampNetKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

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
//        registerHotspotHelper(displayName: "hehe")

        return true
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
        UNUserNotificationCenter.current().requestAuthorization(options: options) { (granted, error) in
            if granted {
                print("User notifications are allowed.")
            } else {
                print("User notifications are not allowed. Error: ", error as Any)
            }
        }
    }

    func registerHotspotHelper(displayName: String) -> Bool {
        print("Registering HotspotHelper.")
        
        let options = [kNEHotspotHelperOptionDisplayName: displayName as NSObject]
        let queue = DispatchQueue.global(qos: .utility)

        return NEHotspotHelper.register(options: options, queue: queue) { (command) in
            print("\(command) received.")
        }
    }
}

