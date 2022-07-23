//
//  CompareContent.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 08.04.2022.
//

import AVFoundation
import UIKit

final class CompareContent: UIView {
  private enum Constants {
    static let backgroundColor: UIColor = .black
    static let horizontalRatio: CGFloat = 3 / 4
    static let verticalRatio: CGFloat = 4 / 3
    static let sliderVerticalInset: CGFloat = 10
    static let sliderHorizontalInset: CGFloat = 16
    static let rotationDuration: TimeInterval = 0.2
  }

  private let manager: CameraManager
  private let factory: CameraViewFactory
  private let year1: Int
  private let year2: Int
  private let oldImage: UIImage
  private let animationDuration: TimeInterval

  private lazy var newImagePreview = factory.makeNewImagePreview()
  private lazy var newImageView = factory.makeRotatingImage()
  private lazy var yearStack = factory.makeYearStack(leftYear: year1, rightYear: year2)
  private lazy var oldImageView = factory.makeRotatingImage()
  private lazy var alphaSlider = factory.makeAlphaSlider()
  private let sliderContainer = UIView()
  private lazy var oldImageOverlay = factory.makeOldImageOverlay()
  private lazy var compareStack = factory.makeCompareStack()

  private lazy var previewRatioConstraint = newImagePreview.heightAnchor.constraint(
    equalTo: newImagePreview.widthAnchor,
    multiplier: Constants.horizontalRatio
  )

  // MARK: - init()

  init(
    manager: CameraManager,
    factory: CameraViewFactory = CameraViewFactory(),
    year1: Int,
    year2: Int,
    oldImage: UIImage,
    animationDuration: TimeInterval = Constants.rotationDuration
  ) {
    self.manager = manager
    self.factory = factory
    self.year1 = year1
    self.year2 = year2
    self.oldImage = oldImage
    self.animationDuration = animationDuration
    super.init(frame: .zero)
    configureActions()
    backgroundColor = Constants.backgroundColor
    addSubviews()
    applyConstraints()
    set(state: .sideBySide)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: actions

  private func configureActions() {
    manager.authorize(success: {
      DispatchQueue.main.async { [weak self] in
        guard let self = self else { return }
        let session = self.manager.makeSessionWithAccess()
        self.newImagePreview.session = session
        session?.startRunning()
      }
    }, failure: {})
    alphaSlider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
  }

  @objc func sliderValueChanged(_ sender: UISlider) {
    oldImageOverlay.alpha = CGFloat(sender.value)
  }

  func takePhoto() {
    DispatchQueue.global().async { [weak self] in
      guard let self = self else { return }
      self.manager.takePhoto(delegate: self)
    }
  }

  // MARK: addSubviews()

  private func addSubviews() {
    oldImageView.imageView?.image = oldImage
    oldImageOverlay.zoomableImageView?.image = oldImage
    sliderContainer.addSubview(alphaSlider)
    compareStack.addArrangedSubview(newImagePreview)
    compareStack.addArrangedSubview(newImageView)
    compareStack.addArrangedSubview(yearStack)
    compareStack.addArrangedSubview(oldImageView)
    compareStack.addArrangedSubview(sliderContainer)
    addSubview(compareStack)
    addSubview(oldImageOverlay)
  }

  // MARK: constraints

  private func applyConstraints() {
    // compareStack
    NSLayoutConstraint.activate([
      compareStack.topAnchor.constraint(equalTo: topAnchor),
      compareStack.leadingAnchor.constraint(equalTo: leadingAnchor),
      compareStack.trailingAnchor.constraint(equalTo: trailingAnchor),
      compareStack.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])

    // image ratios
    NSLayoutConstraint.activate([
      previewRatioConstraint,
      oldImageView.heightAnchor.constraint(
        equalTo: oldImageView.widthAnchor,
        multiplier: Constants.horizontalRatio
      ),
      newImageView.heightAnchor.constraint(
        equalTo: newImageView.widthAnchor,
        multiplier: Constants.horizontalRatio
      ),
    ])

    // alphaSlider
    NSLayoutConstraint.activate([
      alphaSlider.leadingAnchor.constraint(
        equalTo: sliderContainer.leadingAnchor,
        constant: Constants.sliderHorizontalInset
      ),
      alphaSlider.trailingAnchor.constraint(
        equalTo: sliderContainer.trailingAnchor,
        constant: -Constants.sliderHorizontalInset
      ),
      alphaSlider.topAnchor.constraint(
        equalTo: sliderContainer.topAnchor,
        constant: Constants.sliderVerticalInset
      ),
      alphaSlider.bottomAnchor.constraint(
        equalTo: sliderContainer.bottomAnchor,
        constant: -Constants.sliderVerticalInset
      ),
    ])

    // overlay
    NSLayoutConstraint.activate([
      oldImageOverlay.topAnchor.constraint(equalTo: compareStack.topAnchor),
      oldImageOverlay.bottomAnchor.constraint(equalTo: sliderContainer.topAnchor),
      oldImageOverlay.leadingAnchor.constraint(equalTo: compareStack.leadingAnchor),
      oldImageOverlay.trailingAnchor.constraint(equalTo: compareStack.trailingAnchor),
    ])

    // YearStack
    NSLayoutConstraint.activate([
      yearStack.heightAnchor.constraint(equalToConstant: 20),
    ])
  }

  private func updateRatioConstraint(isVertical: Bool) {
    let newRatio = isVertical ? Constants.verticalRatio : Constants.horizontalRatio
    previewRatioConstraint.isActive = false
    previewRatioConstraint = newImagePreview.heightAnchor.constraint(
      equalTo: newImagePreview.widthAnchor,
      multiplier: newRatio
    )
    previewRatioConstraint.isActive = true
  }
}

// MARK: - cameraUnit

extension CompareContent: CameraUnit {
  func set(state: CompareState) {
    switch state {
    case .sideBySide:
      newImagePreview.isHidden = false
      newImageView.isHidden = true
      sliderContainer.isHidden = true
      oldImageOverlay.isHidden = true
      oldImageView.isHidden = false
      yearStack.isHidden = false
      newImageView.imageView?.image = nil
      updateRatioConstraint(isVertical: false)
    case .overlay:
      newImagePreview.isHidden = false
      newImageView.isHidden = true
      sliderContainer.isHidden = false
      oldImageOverlay.isHidden = false
      oldImageView.isHidden = true
      yearStack.isHidden = true
      newImageView.imageView?.image = nil
      updateRatioConstraint(isVertical: true)
      oldImageOverlay.alpha = 0.5
      oldImageOverlay.zoomableImageView?.resetScale()
    case .share:
      newImagePreview.isHidden = true
      newImageView.isHidden = false
      sliderContainer.isHidden = true
      oldImageOverlay.isHidden = true
      oldImageView.isHidden = false
      yearStack.isHidden = false
      updateRatioConstraint(isVertical: false)
    }
  }

  func rotate(_ orientation: UIDeviceOrientation) {
    guard let transform = orientation.rotationTransform else { return }
    UIView.animate(withDuration: animationDuration) {
      self.oldImageView.applyToInnerView(transform: transform)
      self.oldImageOverlay.applyToInnerView(transform: transform)
      self.oldImageOverlay.zoomableImageView?.resetScale()
    }
  }
}

extension CompareContent: AVCapturePhotoCaptureDelegate {
  func photoOutput(
    _: AVCapturePhotoOutput,
    didFinishProcessingPhoto photo: AVCapturePhoto,
    error: Error?
  ) {
    guard let data = photo.fileDataRepresentation(), error == nil else {
      return
    }
    let image = UIImage(data: data)
    newImageView.imageView?.image = image
  }
}

extension CompareContent {
  var sideBySideImage: UIImage {
    let renderer = UIGraphicsImageRenderer(bounds: bounds)
    return renderer.image { rendererContext in
      layer.render(in: rendererContext.cgContext)
    }
  }

  var separateImages: (oldImage: UIImage, newImage: UIImage)? {
    guard let newImage = newImageView.imageView?.image else {
      return nil
    }
    return (oldImage, newImage)
  }
}
