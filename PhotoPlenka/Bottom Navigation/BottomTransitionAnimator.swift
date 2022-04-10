//
//  TransitionAnimator.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 24.02.2022.
//

import UIKit

final class BottomTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    private enum Style {
        static let spacing: CGFloat = 100 //horizontal spacing between new and old screens
        static let yOffset: CGFloat = 100 //'from' screen goes down by offset
        static let fromTransform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        static let duration: TimeInterval = 0.4
    }
    private let operation: UINavigationController.Operation
    private var isPush: Bool { operation == .push } // push или pop

    init(_ operation: UINavigationController.Operation) {
        self.operation = operation
    }

    func transitionDuration(using _: UIViewControllerContextTransitioning?) -> TimeInterval {
        Style.duration
    }

    // анимация перехода: добавим сбоку from, также анимируем alpha
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let from = transitionContext.view(forKey: .from) else { return }
        guard let to = transitionContext.view(forKey: .to) else { return }
        let duration = transitionDuration(using: transitionContext)
        let container = transitionContext.containerView
        container.addSubview(to)
        let visibleFrame = to.frame
        let newToOriginX = isPush ? to.frame.width + Style.spacing : -to.frame.width - Style.spacing
        let newFromOriginX = isPush ? -from.frame.width - Style.spacing : from.frame.width + Style.spacing
        to.frame = CGRect(
            origin: CGPoint(x: newToOriginX, y: to.frame.origin.y + Style.yOffset),
            size: to.frame.size
        )

        let animations = {
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.5) {
                to.transform = .identity
                from.transform = Style.fromTransform
            }

            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 1) {
                to.frame = visibleFrame
                from.frame = CGRect(
                    origin: CGPoint(x: newFromOriginX, y: from.frame.origin.y + Style.yOffset),
                    size: from.frame.size
                )
            }
        }

        UIView.animateKeyframes(
            withDuration: duration,
            delay: 0,
            options: .calculationModeCubicPaced,
            animations: animations,
            completion: { _ in
                container.addSubview(to)
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        )
    }
}
