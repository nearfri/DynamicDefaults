//
//  AppDelegate.swift
//  Defaults
//
//  Created by Ukjeong Lee on 2018. 3. 1..
//  Copyright © 2018년 Ukjeong Lee. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        print(NSTemporaryDirectory())
        
        sample2()
        
        return true
    }
    
    func sample2() {
        let pref = MyPreferences.shared
        
        func printPref() {
            print("=============")
            print(pref.num)
            print(pref.str)
            print(pref.num2)
            print(pref.color)
            print("=============")
        }
        
        printPref()
        
        pref.num = 111111
        pref.str = "world"
        pref.num2 = nil
        pref.color = .green
        
        printPref()
    }
    
    func sample() {
        let pref = Preferences.shared
        
        print(pref.persistentKeyPaths)
        
        func printPref() {
            print(pref.intValue)
            print(pref.doubleValue)
            print(pref.floatValue)
            print(pref.boolValue)
            print(pref.stringValue)
            print(pref.intArrayValue)
            print(pref.stringArrayValue)
            print(pref.dataValue)
            print(pref.dateValue)
            print(pref.urlValue)
            print(pref.fileURLValue)
            print(pref.subInfo.number)
            print(pref.subInfo.title)
        }
        
        printPref()
        
        pref.intValue = 1
        pref.doubleValue = 2
        pref.floatValue = 3
        pref.boolValue = false
        pref.stringValue = "world"
        pref.intArrayValue = [10, 11, 12]
        pref.stringArrayValue = ["swift", "work"]
        pref.dataValue = Data(count: 20)
        pref.dateValue = Date()
        pref.urlValue = URL(string: "http://hello.com")!
        pref.fileURLValue = URL(fileURLWithPath: "/new/url/string")
        pref.optStringValue = "wow"
        pref.optIntValue = 8
        pref.optStringValue = nil
        pref.optIntValue = nil
//        pref.colorTypeValue = .yellow
        pref.subInfo.number = 88
        pref.subInfo.title = "hungry"
        
        printPref()
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


}

