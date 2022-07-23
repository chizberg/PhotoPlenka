//
//  NavigationAnimation.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 27.04.2022.
//

import UIKit

enum NavigationAnimation {
  case overlay // new screen is presented over an old one
  case sideToSide // new screen is moving from the right side
}

extension NavigationAnimation {
  private enum Style {
    // overlay stuff
    static let yFirstStep: CGFloat = 0.2
    static let behindScale: CGFloat = 0.8
    static let behindTransform = CGAffineTransform(scaleX: behindScale, y: behindScale)

    // sideToSide stuff
    static let spacing: CGFloat = 100 // horizontal spacing between new and old screens
    static let yOffset: CGFloat = 100 // 'from' screen goes down by offset
    static let fromTransform = CGAffineTransform(scaleX: 0.7, y: 0.7)
  }

  func keyframes(
    isPush: Bool,
    from: UIView,
    to: UIView,
    container: UIView
  ) -> (() -> Void) {
    isPush ?
      pushAnimation(from: from, to: to, container: container) :
      popAnimation(from: from, to: to, container: container)
  }

  private func pushAnimation(from: UIView, to: UIView, container: UIView) -> (() -> Void) {
    switch self {
    case .overlay: // TODO: fix push
      let (presentationFrame, hiddenFrame, middleFrame) = overlayFrames(
        from: from,
        container: container
      )
      container.addSubview(to)
      to.frame = hiddenFrame
      return {
        // push: an old screen should go behind (with a transform) and a new screen shold be shown over it
        UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.8) {
          to.frame = middleFrame // it goes to a middle frame at first
        }
        UIView.addKeyframe(withRelativeStartTime: 0.8, relativeDuration: 0.2) {
          to.frame = presentationFrame // and then smoothly goes to presentation frame
        }
        UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.5) {
          from.frame = middleFrame // while the old screen smoothly goes back
          from.transform = Style.behindTransform // with a transform
          container.setNeedsLayout()
        }
        UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) {
          from
            .transform =
            .identity // and when it's behind a new screen, it rapidly hides away
          from.frame = hiddenFrame
          container.setNeedsLayout()
        }
      }
    case .sideToSide:
      let (presentationFrame, leftHiddenFrame, rightHiddenFrame) = sideToSideFrames(
        from: from,
        container: container
      )
      container.addSubview(to)
      to.frame = rightHiddenFrame
      return {
        UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.5) {
          to.transform = .identity
          from.transform = Style.fromTransform
        }

        UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 1) {
          to.frame = presentationFrame
          from.center = leftHiddenFrame.center
        }
      }
    }
  }

  private func popAnimation(from: UIView, to: UIView, container: UIView) -> (() -> Void) {
    switch self {
    case .overlay:
      let (presentationFrame, hiddenFrame, _) = overlayFrames(
        from: from,
        container: container
      )
      container.insertSubview(to, at: 0)
      to.frame = hiddenFrame
      return {
        // pop: an new screen comes from behind while an old screen goes down
        // new = to, old = from, not to confuse
        let presentationCenter = from.center // we will need it later
        to.transform = Style.behindTransform // new screen has a transform
        container.setNeedsLayout()
        UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.7) {
          // it moves to a place where content should be
          to.center.y = presentationCenter.y + presentationFrame.height * Style.yFirstStep
        }
        UIView.addKeyframe(withRelativeStartTime: 0.7, relativeDuration: 0.3) {
          to.transform = .identity // then scales up
          to.frame = presentationFrame // and goes to a presentation frame
          container.setNeedsLayout()
        }
        UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 1) {
          from.frame = hiddenFrame // while the old screen slowly goes down
        }
      }
    case .sideToSide:
      let (presentationFrame, leftHiddenFrame, rightHiddenFrame) = sideToSideFrames(
        from: from,
        container: container
      )
      container.addSubview(to)
      to.frame = leftHiddenFrame
      return {
        UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.5) {
          to.transform = .identity
          from.transform = Style.fromTransform
        }

        UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 1) {
          to.frame = presentationFrame
          from.center = rightHiddenFrame.center
        }
      }
    }
  }

  private func overlayFrames(from: UIView, container: UIView) -> (
    presentationFrame: CGRect,
    hiddenFrame: CGRect,
    middleFrame: CGRect
  ) {
    let presentationFrame = from.frame // frame where main presented content should be
    let hiddenFrame = CGRect( // a frame where previous screen goes
      x: 0,
      y: container.bounds.height,
      width: presentationFrame.width,
      height: presentationFrame.height
    )
    let middleFrame = CGRect( // a middle frame so animation looks more natural
      x: 0,
      y: 0 + presentationFrame.height * Style.yFirstStep, // is has a little y offset
      width: presentationFrame.width,
      height: presentationFrame.height
    )
    return (presentationFrame, hiddenFrame, middleFrame)
  }

  private func sideToSideFrames(from: UIView, container: UIView) -> (
    presentationFrame: CGRect,
    leftHiddenFrame: CGRect,
    rightHiddenFrame: CGRect
  ) {
    let presentationFrame = from.frame
    let leftHiddenFrame = CGRect(
      x: -container.bounds.width - Style.spacing,
      y: presentationFrame.origin.y + Style.yOffset,
      width: presentationFrame.width,
      height: presentationFrame.height
    )
    let rightHiddenFrame = CGRect(
      x: container.bounds.width + Style.spacing,
      y: presentationFrame.origin.y + Style.yOffset,
      width: presentationFrame.width,
      height: presentationFrame.height
    )
    return (presentationFrame, leftHiddenFrame, rightHiddenFrame)
  }
}

extension CGRect {
  var center: CGPoint {
    CGPoint(
      x: origin.x + width / 2,
      y: origin.y + height / 2
    )
  }
}
