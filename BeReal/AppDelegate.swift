//
//  AppDelegate.swift
//  BeReal
//
//  Created by Claudia Espinosa on 10/10/25.
//

import UIKit
import ParseSwift


@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

            ParseSwift.initialize(applicationId: "ZzuAOZBlsTuAYH7V4JUQXL1NtRcabhhEQnqEy1Fz",
                clientKey: "AFhRPBxLkq4dDIxCuQlyFhZC9PGojknLD4rsAaIQ",
                serverURL: URL(string: "https://parseapi.back4app.com")!)

        return true
    }


    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
}
