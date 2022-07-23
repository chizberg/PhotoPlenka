//
//  FavouritesListController.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 12.04.2022.
//

import UIKit

enum PhotoListType {
  case favourites
  case localCluster
}

final class PhotoListController: UIViewController, ScrollableViewController {
  private enum Constants {
    static let sideInset: CGFloat = 16
    static let buttonSize: CGSize = .init(width: 40, height: 40)
    static let controllerCornerRadius: CGFloat = 29
    static let maskedCorners: CACornerMask = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
    static let cellID = String(describing: PreviewCell.self)
    static let favouritesTitle = "Избранное"
    static func clusterTitle(_ num: Int) -> String {
      switch num % 10 {
      case 1: return "\(num) фотография"
      case 2...4: return "\(num) фотографии"
      default: return "\(num) фотографий"
      }
    }
  }

  // scrollableController
  var scrollView: UIScrollView {
    tableView
  }

  var header: UIView {
    navBar
  }

  var scrollPan: UIGestureRecognizer? {
    didSet {
      guard let scrollPan = scrollPan else { return }
      scrollView.addGestureRecognizer(scrollPan)
    }
  }

  var headerPan: UIGestureRecognizer? {
    didSet {
      guard let headerPan = headerPan else { return }
      header.addGestureRecognizer(headerPan)
    }
  }

  // data
  private var photos: [Photo]
  let type: PhotoListType

  // views
  private let factory = PhotoListFactory()
  private lazy var backgroundView = factory.makeBackground()
  private lazy var tableView = factory.makeTableView()
  private lazy var navBar: UINavigationBar = factory.makeNavBar(
    rightItem: UIBarButtonItem(
      barButtonSystemItem: .close,
      target: self,
      action: #selector(self.closeButtonTapped)
    ),
    title: navTitle
  )
  private var navTitle: String {
    switch type {
    case .favourites: return Constants.favouritesTitle
    case .localCluster: return Constants.clusterTitle(photos.count)
    }
  }

  init(
    photos: [Photo]? = nil
  ) {
    if let photos = photos {
      self.photos = photos
      self.type = .localCluster
    } else {
      self.photos = FavouritesProvider.shared.favourites ?? []
      self.type = .favourites
    }
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.register(PreviewCell.self, forCellReuseIdentifier: Constants.cellID)
    tableView.multicastingDelegate.addDelegate(self)
    tableView.dataSource = self
    view.layer.cornerRadius = Constants.controllerCornerRadius
    view.layer.maskedCorners = Constants.maskedCorners
    view.clipsToBounds = true
    view.backgroundColor = nil
    view.addSubview(tableView)
    view.addSubview(navBar)
    view.insertSubview(backgroundView, at: 0)
    applyConstraints()
  }

  override func viewDidLayoutSubviews() {
    backgroundView.frame = view.bounds
  }

  func reloadData(
    photos: [Photo]? = nil
  ) {
    guard type == .favourites else {
      if let photos = photos { self.photos = photos }
      tableView.reloadData()
      return
    }
    self.photos = FavouritesProvider.shared.favourites ?? []
    tableView.reloadData()
  }

  private func applyConstraints() {
    NSLayoutConstraint.activate([
      navBar.topAnchor.constraint(equalTo: view.topAnchor),
      navBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      navBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
    ])

    NSLayoutConstraint.activate([
      tableView.leadingAnchor.constraint(
        equalTo: view.leadingAnchor,
        constant: Constants.sideInset
      ),
      tableView.trailingAnchor.constraint(
        equalTo: view.trailingAnchor,
        constant: -Constants.sideInset
      ),
      tableView.topAnchor.constraint(equalTo: navBar.bottomAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }

  @objc func closeButtonTapped() {
    navigationController?.popViewController(animated: true)
  }
}

extension PhotoListController: UITableViewDataSource, UITableViewDelegate {
  func numberOfSections(in _: UITableView) -> Int {
    1
  }

  func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
    photos.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellID, for: indexPath)
    guard let previewCell = cell as? PreviewCell else { return cell }
    previewCell.fillIn(photos[indexPath.row])
    return previewCell
  }

  func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
    let photo = photos[indexPath.row]
    let detailsController = PhotoDetailsController(
      cid: photo.cid,
      detailsProvider: PhotoDetailsProvider(networkService: NetworkService())
    )
    navigationController?.pushViewController(detailsController, animated: true)
  }
}
