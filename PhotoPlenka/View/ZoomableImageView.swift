//
//  ZoomableImageView.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 12.03.2022.
//

import UIKit

final class ZoomableImageView: UIScrollView {
  private enum Constants {
    static let minZoom: CGFloat = 1
    static let maxZoom: CGFloat = 3
    static let doubleTapZoom: CGFloat = 2
  }

  private let minZoom: CGFloat
  private let maxZoom: CGFloat

  private let imageView: UIImageView = {
    let imageView = UIImageView()
    imageView.contentMode = .scaleAspectFit
    return imageView
  }()

  init(
    frame: CGRect = .zero,
    minZoom: CGFloat = Constants.minZoom,
    maxZoom: CGFloat = Constants.maxZoom
  ) {
    self.minZoom = minZoom
    self.maxZoom = maxZoom
    super.init(frame: frame)
    addSubview(imageView)

    minimumZoomScale = minZoom
    maximumZoomScale = maxZoom
    showsHorizontalScrollIndicator = false
    showsVerticalScrollIndicator = false
    delegate = self
    configureDoubleTap()
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func resetScale() {
    zoomScale = 1
    resetLayout()
  }

  private func resetLayout() {
    setImageFrame()
    contentSize = imageView.frame.size
    updateInsets()
  }

  var image: UIImage? {
    get { imageView.image }
    set {
      imageView.image = newValue
      resetLayout()
    }
  }

  private func configureDoubleTap() {
    let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTap))
    doubleTap.numberOfTapsRequired = 2
    addGestureRecognizer(doubleTap)
  }

  private func setImageFrame() {
    guard let image = imageView.image else { return }
    let ratio = image.size.height / image.size.width
    let width = bounds.width
    let height = width * ratio
    imageView.frame = CGRect(origin: .zero, size: CGSize(width: width, height: height))
  }

  private func updateInsets() {
    let offsetX = max((bounds.width - contentSize.width) * 0.5, 0)
    let offsetY = max((bounds.height - contentSize.height) * 0.5, 0)
    contentInset = UIEdgeInsets(top: offsetY, left: offsetX, bottom: 0, right: 0)
  }
}

extension ZoomableImageView: UIScrollViewDelegate {
  func viewForZooming(in _: UIScrollView) -> UIView? {
    imageView
  }

  func scrollViewDidZoom(_: UIScrollView) {
    updateInsets()
  }

  @objc private func doubleTap() {
    guard zoomScale == 1 else {
      setZoomScale(1, animated: true)
      return
    }
    setZoomScale(Constants.doubleTapZoom, animated: true)
  }
}
