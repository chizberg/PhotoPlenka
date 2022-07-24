//
//  NearbyListController.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 14.02.2022.
//

import MapKit
import UIKit

final class NearbyListController: UIViewController, ScrollableViewController {
  var header: UIView {
    yearSelect
  }

  var scrollView: UIScrollView {
    nearbyList
  }

  var headerPan: UIGestureRecognizer? {
    didSet {
      guard let headerPan = headerPan else { return }
      header.addGestureRecognizer(headerPan)
    }
  }

  var scrollPan: UIGestureRecognizer? {
    didSet {
      guard let scrollPan = scrollPan else { return }
      scrollView.addGestureRecognizer(scrollPan)
    }
  }

  private enum Constants {
    static let sideInset: CGFloat = 16
    static let controllerCornerRadius: CGFloat = 29
    static let listCornerRadius: CGFloat = 13
    static let cellID = String(describing: PreviewCell.self)
    static let listTitle = "Интересное рядом"
    static let countLimit: Int = 10
  }

  // views
  private let yearSelect = YearSelector()
  private let nearbyList: UITableView = {
    let tableView = UITableView(frame: .zero, style: .grouped)
    tableView.backgroundColor = .clear
    tableView.separatorStyle = .none
    tableView.showsVerticalScrollIndicator = false
    tableView.layer.cornerRadius = Constants.listCornerRadius
    tableView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
    return tableView
  }()

  let backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))

  // data
  private var visibleAnnotations = [MKAnnotation]()
  private let detailsProvider: PhotoDetailsProviderProtocol

  init
    (
      mapController: YearSelectorDelegate,
      detailsProvider: PhotoDetailsProviderProtocol
    ) {
    self.detailsProvider = detailsProvider
    super.init(nibName: nil, bundle: nil)
    yearSelect.delegate = mapController
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.addSubview(yearSelect)
    nearbyList.multicastingDelegate.addDelegate(self)
    nearbyList.dataSource = self
    nearbyList.register(PreviewCell.self, forCellReuseIdentifier: Constants.cellID)
    view.addSubview(nearbyList)
    view.insertSubview(backgroundView, at: 0)
    view.clipsToBounds = true
    view.layer.cornerRadius = Constants.controllerCornerRadius
    view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    applyConstraints()
  }

  override func viewDidLayoutSubviews() {
    backgroundView.frame = view.bounds
  }

  private func applyConstraints() {
    yearSelect.translatesAutoresizingMaskIntoConstraints = false
    nearbyList.translatesAutoresizingMaskIntoConstraints = false

    NSLayoutConstraint.activate([
      yearSelect.topAnchor.constraint(equalTo: view.topAnchor, constant: Constants.sideInset),
      yearSelect.leadingAnchor.constraint(
        equalTo: view.leadingAnchor,
        constant: Constants.sideInset
      ),
      yearSelect.trailingAnchor.constraint(
        equalTo: view.trailingAnchor,
        constant: -Constants.sideInset
      ),
      yearSelect.heightAnchor.constraint(equalToConstant: 50),
    ])

    NSLayoutConstraint.activate([
      nearbyList.topAnchor.constraint(
        equalTo: yearSelect.bottomAnchor,
        constant: Constants.sideInset
      ),
      nearbyList.leadingAnchor.constraint(
        equalTo: view.leadingAnchor,
        constant: Constants.sideInset
      ),
      nearbyList.trailingAnchor.constraint(
        equalTo: view.trailingAnchor,
        constant: -Constants.sideInset
      ),
      nearbyList.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }
}

extension NearbyListController: MapObserver {
  func annotationsDidChange(annotations _: [MKAnnotation], visible: [MKAnnotation]) {
    let photoAnnotations = visible.filter { !($0 is MKUserLocation) }
    nearbyList.isHidden = photoAnnotations.isEmpty
    guard photoAnnotations.count > Constants.countLimit else {
      visibleAnnotations = photoAnnotations
      nearbyList.reloadData()
      return
    }
    visibleAnnotations = Array(photoAnnotations[..<Constants.countLimit])
    nearbyList.reloadData()
  }
}

extension NearbyListController: UITableViewDataSource, UITableViewDelegate {
  func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
    visibleAnnotations.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellID, for: indexPath)
    guard let previewCell = cell as? PreviewCell else { return cell }
    let annotation = visibleAnnotations[indexPath.row]
    switch annotation {
    case is MKUserLocation:
      break
    case let photo as Photo:
      previewCell.fillIn(photo)
    case let cluster as Cluster:
      previewCell.fillIn(cluster.photo)
    case let group as PhotoGroup:
      guard let photo = group.photos.first else { break }
      previewCell.fillIn(photo)
    default:
      fatalError("invalid annotation type")
    }
    return cell
  }

  func tableView(_: UITableView, titleForHeaderInSection _: Int) -> String? {
    Constants.listTitle
  }

  func tableView(_: UITableView, estimatedHeightForRowAt _: IndexPath) -> CGFloat {
    UITableView.automaticDimension
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let annotation = visibleAnnotations[indexPath.row]
    let photoData: Photo
    switch annotation {
    case let photo as Photo:
      photoData = photo
    case let cluster as Cluster:
      photoData = cluster.photo
    case let group as PhotoGroup:
      guard let photo = group.photos.first else { fallthrough }
      photoData = photo
    default:
      fatalError("invalid annotation type")
    }
    let singleController = PhotoDetailsController(
      cid: photoData.cid,
      detailsProvider: detailsProvider
    )
    navigationController?.pushViewController(singleController, animated: true)
  }
}
