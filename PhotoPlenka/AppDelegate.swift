//
//  AppDelegate.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 02.02.2022.
//

import CoreData
import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
  private enum Constants {
    // comes from CoreDataModel.xcdatamodel where favourites are stored
    static let containerName = "PhotoPlenka"
  }

  func application(
    _: UIApplication,
    didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Override point for customization after application launch.
    true
  }

  // MARK: UISceneSession Lifecycle

  func application(
    _: UIApplication,
    configurationForConnecting connectingSceneSession: UISceneSession,
    options _: UIScene.ConnectionOptions
  ) -> UISceneConfiguration {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    UISceneConfiguration(
      name: "Default Configuration",
      sessionRole: connectingSceneSession.role
    )
  }

  func application(_: UIApplication, didDiscardSceneSessions _: Set<UISceneSession>) {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
  }

  // MARK: CoreData

  lazy var persistentContainer: NSPersistentContainer = {
    let container = NSPersistentContainer(name: Constants.containerName)
    // TODO: handle errors properly
    container.loadPersistentStores(completionHandler: { _, _ in })
    return container
  }()

  func saveContext() {
    let context = persistentContainer.viewContext
    guard context.hasChanges else { return }
    // TODO: handle errors properly
    try? context.save()
  }
}
