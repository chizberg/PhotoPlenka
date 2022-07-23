//
//  CompareCameraController.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 08.04.2022.
//

import UIKit

final class CameraCompareController: UIViewController {
  private let manager = CameraManager()

  private let oldImage: UIImage
  private let year1: Int
  private let year2: Int

  private var state: CompareState = .sideBySide {
    didSet {
      set(state: state)
    }
  }

  // views
  private let factory = CameraViewFactory()
  private lazy var compareContent = CompareContent(
    manager: manager,
    factory: factory,
    year1: year1,
    year2: year2,
    oldImage: oldImage
  )
  private lazy var cameraControls = CameraControls(factory: factory)

  init(
    oldImage: UIImage,
    year1: Int,
    year2: Int
  ) {
    self.oldImage = oldImage
    self.year1 = year1
    self.year2 = year2
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .black
    cameraControls.delegate = self
    compareContent.translatesAutoresizingMaskIntoConstraints = false
    cameraControls.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(compareContent)
    view.addSubview(cameraControls)
    applyConstraints()

    UIDevice.current.beginGeneratingDeviceOrientationNotifications()
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(deviceOrientationDidChange),
      name: UIDevice.orientationDidChangeNotification,
      object: nil
    )
  }

  func applyConstraints() {
    NSLayoutConstraint.activate([
      compareContent.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      compareContent.leadingAnchor
        .constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
      compareContent.trailingAnchor
        .constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),

      cameraControls.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      cameraControls.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      cameraControls.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
      cameraControls.topAnchor.constraint(lessThanOrEqualTo: compareContent.bottomAnchor),
    ])
  }

  override var prefersStatusBarHidden: Bool {
    true
  }

  private var orientation: UIDeviceOrientation {
    UIDevice.current.orientation
  }

  private func set(state: CompareState) {
    compareContent.set(state: state)
    cameraControls.set(state: state)
  }

  @objc private func deviceOrientationDidChange() {
    compareContent.rotate(orientation)
    cameraControls.rotate(orientation)
  }

  public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
    .portrait
  }

  private func share(images: [UIImage]) {
    let shareVC = UIActivityViewController(activityItems: images, applicationActivities: nil)
    present(shareVC, animated: true, completion: {
      self.state = .sideBySide
    })
  }

  private func askExportMode() {
    let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
    let sideBySide = UIAlertAction(title: "Вместе", style: .default, handler: { [weak self] _ in
      guard let self = self else { return }
      self.share(images: [self.compareContent.sideBySideImage])
    })
    let separately = UIAlertAction(
      title: "По отдельности",
      style: .default,
      handler: { [weak self] _ in
        guard let self = self else { return }
        guard let images = self.compareContent.separateImages else { return }
        self.share(images: [images.newImage, images.oldImage])
      }
    )
    let cancel = UIAlertAction(title: "Отмена", style: .cancel, handler: nil)
    alert.addAction(sideBySide)
    alert.addAction(separately)
    alert.addAction(cancel)
    present(alert, animated: true)
  }
}

extension CameraCompareController: CameraControlsDelegate {
  func didChangeState() {
    switch state {
    case .sideBySide: state = .overlay
    case .overlay: state = .sideBySide
    case .share: askExportMode()
    }
  }

  func didTriggerShot() {
    guard state != .share else {
      state = .sideBySide
      return
    }
    compareContent.takePhoto()
    state = .share
  }

  func didTriggerBack() {
    self.dismiss(animated: true)
  }
}
