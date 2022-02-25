//
//  TransitionAnimator.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 24.02.2022.
//

import UIKit

final class BottomTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    private let operation: UINavigationController.Operation
    private var isPush: Bool { operation == .push } //push или pop

    init(_ operation: UINavigationController.Operation) {
        self.operation = operation
    }

    func transitionDuration(using _: UIViewControllerContextTransitioning?) -> TimeInterval {
        0.4
    }

    //анимация перехода: добавим сбоку from, также анимируем alpha
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let from = transitionContext.view(forKey: .from) else { return }
        guard let to = transitionContext.view(forKey: .to) else { return }
        let duration = transitionDuration(using: transitionContext)
        let container = transitionContext.containerView
        container.addSubview(to)
        let visibleFrame = to.frame
        let newToOriginX = isPush ? to.frame.width : -to.frame.width
        let newFromOriginX = isPush ? -from.frame.width : from.frame.width
        to.frame = CGRect(
            origin: CGPoint(x: newToOriginX, y: to.frame.origin.y),
            size: to.frame.size
        )

        let animations = { [unowned self] in
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.5) {
                to.alpha = 1
                if self.isPush { from.alpha = 0 }
            }

            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 1) {
                to.frame = visibleFrame
                from.frame = CGRect(
                    origin: CGPoint(x: newFromOriginX, y: from.frame.origin.y),
                    size: from.frame.size
                )
                if !self.isPush { from.alpha = 0 }
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
