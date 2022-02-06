//
//  PresentationController.swift
//  PhotoPlenka
//
//  Created by Dmitry Trifonov on 05.02.2022.
//

import Foundation
import UIKit

final class BottomSheetPresentationController: UIPresentationController {
    private var initialFrame: CGRect = .zero

    override var shouldPresentInFullscreen: Bool {
        false
    }

    override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerViewBounds = presentingViewController.view?.bounds else {
            assertionFailure("Presenting view must be existed")
            return .zero
        }
        let halfHeight = containerViewBounds.height / Consts.collapsedDelimiter
        let y = containerViewBounds.height - halfHeight

        return .init(
            x: 0,
            y: y,
            width: containerViewBounds.width,
            height: halfHeight
        )
    }
}

// MARK: - Configure methods

extension BottomSheetPresentationController {
    private func configurePanGesture() {
        let swipeGesture = UIPanGestureRecognizer(target: self, action: #selector(swipeGesture(_:)))
        presentedViewController.view?.addGestureRecognizer(swipeGesture)
    }
}

// MARK: - Presentation Controller methods

extension BottomSheetPresentationController {
    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        containerView?.frame = frameOfPresentedViewInContainerView
    }

    override func presentationTransitionDidEnd(_ completed: Bool) {
        super.presentationTransitionDidEnd(completed)
        configurePanGesture()
    }

    // These methods are not used now, but will be used in the future
    override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()
    }

    override func dismissalTransitionDidEnd(_ completed: Bool) {
        super.dismissalTransitionDidEnd(completed)
    }

    override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()
        presentedView?.frame = containerView?.bounds ?? .zero
    }
}

// MARK: - Gestures

extension BottomSheetPresentationController {
    @objc
    func swipeGesture(_ gesture: UIPanGestureRecognizer) {
        guard let containerFrame = containerView?.frame else {
            return
        }

        if gesture.state == .began {
            initialFrame = containerFrame
        } else if gesture.state == .changed {
            let transition = gesture.translation(in: presentedView).y
            containerView?.frame = .init(
                x: 0,
                y: initialFrame.minY + transition,
                width: initialFrame.width,
                height: initialFrame.height - transition
            )

        } else if gesture.state == .ended {
            let progressLocation = 1 -
                (containerFrame.minY / presentingViewController.view.bounds.height)
            UIView.animate(withDuration: 0.15, animations: {
                if progressLocation <= Consts.collapsedThreshold {
                    self.containerView?.frame = self.frameOfPresentedViewInContainerView
                } else if progressLocation >= Consts.fullThreshold {
                    let presentingViewBounds = self.presentingViewController.view.bounds
                    let targetContainerViewHeight = presentingViewBounds.height - Consts.topMargin
                    let targetContainerViewY = Consts.topMargin
                    self.containerView?.frame = .init(
                        x: 0,
                        y: targetContainerViewY,
                        width: presentingViewBounds.width,
                        height: targetContainerViewHeight
                    )
                } else {
                    let presentingViewBounds = self.presentingViewController.view.bounds
                    let targetContainerViewHeight = presentingViewBounds.height / Consts
                        .openedDelimiter
                    let targetContainerViewY = presentingViewBounds
                        .height - targetContainerViewHeight

                    self.containerView?.frame = .init(
                        x: 0,
                        y: targetContainerViewY,
                        width: presentingViewBounds.width,
                        height: targetContainerViewY
                    )
                }
                self.containerView?.layoutIfNeeded()
            })
        }
    }
}

extension BottomSheetPresentationController {
    enum Consts {
        static let collapsedThreshold: CGFloat = 0.3
        static let fullThreshold: CGFloat = 0.7
        static let topMargin: CGFloat = 100
        static let collapsedDelimiter: CGFloat = 10
        static let openedDelimiter: CGFloat = 2.0
    }
}
