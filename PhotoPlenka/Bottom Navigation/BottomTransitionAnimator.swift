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
        static let duration: TimeInterval = 0.6
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
        isPush ? container.addSubview(to) : container.insertSubview(to, at: 0)
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
        to.frame = hiddenFrame
        let animations: () -> ()
        switch isPush {
        case true: animations = {
            // push: an old screen should go behind (with a transform) and a new screen shold be shown over it
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.8){
                to.frame = middleFrame // it goes to a middle frame at first
            }
            UIView.addKeyframe(withRelativeStartTime: 0.8, relativeDuration: 0.2){
                to.frame = presentationFrame // and then smoothly goes to presentation frame
            }
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.5){
                from.frame = middleFrame // while the old screen smoothly goes back
                from.transform = Style.behindTransform // with a transform
                container.setNeedsLayout()
            }
            UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5){
                from.transform = .identity // and when it's behind a new screen, it rapidly hides away
                from.frame = hiddenFrame
                container.setNeedsLayout()
            }
        }
        case false: animations = {
            // pop: an new screen comes from behind while an old screen goes down
            // new = to, old = from, not to confuse
            let presentationCenter = from.center // we will need it later
            to.transform = Style.behindTransform // new screen has a transform
            container.setNeedsLayout()
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.7){
                // it moves to a place where content should be
                to.center.y = presentationCenter.y + presentationFrame.height * Style.yFirstStep
            }
            UIView.addKeyframe(withRelativeStartTime: 0.7, relativeDuration: 0.3){
                to.transform = .identity // then scales up
                to.frame = presentationFrame // and goes to a presentation frame
                container.setNeedsLayout()
            }
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 1){
                from.frame = hiddenFrame // while the old screen slowly goes down
            }
        }
        }

        UIView.animateKeyframes(
            withDuration: duration,
            delay: 0,
            animations: animations,
            completion: { _ in
                container.addSubview(to)
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        )
    }
}
