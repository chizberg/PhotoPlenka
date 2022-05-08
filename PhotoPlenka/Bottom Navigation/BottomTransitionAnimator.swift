//
//  TransitionAnimator.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 24.02.2022.
//

import UIKit

final class BottomTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    private enum Style {
        static let yFirstStep: CGFloat = 0.2
        static let behindScale: CGFloat = 0.8
        static let behindTransform = CGAffineTransform(scaleX: behindScale, y: behindScale)
        static let duration: TimeInterval = 0.5
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
        let animation: NavigationAnimation = .sideToSide
        let keyframes = animation.keyframes(isPush: isPush, from: from, to: to, container: container)

        UIView.animateKeyframes(
            withDuration: duration,
            delay: 0,
            options: .calculationModeCubicPaced,
            animations: keyframes,
            completion: { _ in
                container.addSubview(to)
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        )
    }
}
