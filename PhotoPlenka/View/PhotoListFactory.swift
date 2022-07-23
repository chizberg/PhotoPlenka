//
//  PhotoListFactory.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 24.04.2022.
//

import UIKit

final class PhotoListFactory {
  func makeTableView() -> UITableView {
    let tableView = UITableView(frame: .zero, style: .grouped)
    tableView.backgroundColor = nil
    tableView.separatorStyle = .none
    tableView.showsVerticalScrollIndicator = false
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.clipsToBounds = false
    return tableView
  }

  func makeNavBar(
    leftItem: UIBarButtonItem? = nil,
    rightItem: UIBarButtonItem? = nil,
    title: String
  ) -> UINavigationBar {
    let bar = UINavigationBar(frame: .zero)
    bar.isTranslucent = true
    bar.translatesAutoresizingMaskIntoConstraints = false
    let topItem = UINavigationItem(title: title)
    topItem.rightBarButtonItem = rightItem
    topItem.leftBarButtonItem = leftItem
    bar.setItems([topItem], animated: true)
    return bar
  }

  func makeBackground() -> UIView {
    UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
  }
}
