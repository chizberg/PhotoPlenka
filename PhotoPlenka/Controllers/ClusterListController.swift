//
//  ClusterListController.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 24.04.2022.
//

import UIKit

final class ClusterListController: UIViewController {
  private enum Constants {
    static let sideInset: CGFloat = 16
    static let buttonSize: CGSize = .init(width: 40, height: 40)
    static let controllerCornerRadius: CGFloat = 29
    static let maskedCorners: CACornerMask = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
    static let cellID = String(describing: PreviewCell.self)
  }

  private var photos: [Photo]

  init(photos: [Photo]) {
    self.photos = photos
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
