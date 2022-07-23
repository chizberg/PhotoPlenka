//
//  SquishyButton.swift
//  SquishyButton
//
//  Created by Алексей Шерстнёв on 19.02.2022.
//

import UIKit

internal class SquishyButton: UIButton {
  private enum Style {
    static let animationTransform = CGAffineTransform(scaleX: 0.9, y: 0.9)
  }

  let animator = UIViewPropertyAnimator()

  override init(frame: CGRect) {
    super.init(frame: frame)
    addTargets()
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func addTargets() {
    addTarget(self, action: #selector(touchDown), for: .touchDown)
    addTarget(self, action: #selector(touchUp), for: .touchUpInside)
    addTarget(self, action: #selector(touchUp), for: .touchUpOutside)
    addTarget(self, action: #selector(touchUp), for: .touchCancel)
  }

  func updateLayout(isSelected _: Bool) {}

  @objc func touchDown() {
    if animator.isRunning { animator.stopAnimation(true) }
    animator.addAnimations { [weak self] in
      guard let self = self else { return }
      self.transform = Style.animationTransform
      self.updateLayout(isSelected: true)
    }
    animator.startAnimation()
  }

  @objc func touchUp() {
    if animator.isRunning { animator.stopAnimation(true) }
    animator.addAnimations { [weak self] in
      guard let self = self else { return }
      self.transform = .identity
      self.updateLayout(isSelected: false)
    }
    animator.startAnimation()
  }
}
