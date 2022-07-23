//
//  RotatingContainer.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 08.04.2022.
//

import UIKit

// контейнер, с которым удобнее анимировать повороты на экране камеры
// можно повернуть как дочерний view, так и накладывать transform для контейнера
// использую в основном на экране с камерой
final class RotatingContainer: UIView {
  var innerView: UIView

  init(innerView: UIView) {
    self.innerView = innerView
    super.init(frame: .zero)
    addSubview(innerView)
    clipsToBounds = true
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    innerView.frame = bounds
  }

  func applyToInnerView(transform: CGAffineTransform) {
    self.innerView.transform = transform
    self.innerView.frame = self.bounds
  }

  var imageView: UIImageView? {
    get { innerView as? UIImageView }
    set {
      if let newInner = newValue {
        innerView = newInner
      }
    }
  }

  var zoomableImageView: ZoomableImageView? {
    get { innerView as? ZoomableImageView }
    set {
      if let newInner = newValue {
        innerView = newInner
      }
    }
  }

  var button: UIButton? {
    innerView as? UIButton
  }
}

extension UIButton {
  var contained: RotatingContainer {
    RotatingContainer(innerView: self)
  }
}
