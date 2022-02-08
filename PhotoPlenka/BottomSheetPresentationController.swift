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
    private let fractions: [Double]

    override var shouldPresentInFullscreen: Bool {
        false
    }

    override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerViewBounds = presentingViewController.view?.bounds,
              let firstFraction = fractions.first else {
            assertionFailure("Presenting view must exist")
            return .zero
        }

        let y = calculateYAxis(fraction: firstFraction)
        let height = calculateHeightBy(yAxisValue: y)

        return .init(
            x: 0,
            y: y,
            width: containerViewBounds.width,
            height: height
        )
    }

    init(
        fractions: [Double],
        presentedViewController: UIViewController,
        presenting presentingViewController: UIViewController?
    ) {
        guard !fractions.isEmpty else {
            fatalError("Must have at leat one element")
        }
        self.fractions = fractions.sorted(by: <)
        super.init(
            presentedViewController: presentedViewController,
            presenting: presentingViewController
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

// MARK: - Helpers

extension BottomSheetPresentationController {
    private func findMostCloseFraction(_ value: Double) -> Double {
        var minDistance = 1.0
        var closestFractionIndex = 0
        for (index, fraction) in fractions.enumerated() {
            if abs(fraction - value) < minDistance {
                minDistance = abs(fraction - value)
                closestFractionIndex = index
            }
        }
        return fractions[closestFractionIndex]
    }

    private func calculateYAxis(fraction: Double) -> Double {
        let presentingBounds = self.presentingViewController.view.bounds
        return presentingBounds.height - presentingBounds.height * fraction
    }

    private func calculateHeightBy(yAxisValue: Double) -> Double {
        presentingViewController.view.bounds.height - yAxisValue
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

            UIView.animate(withDuration: 0.2, animations: {
                let closestFraction = self.findMostCloseFraction(progressLocation)

                let presentingBounds = self.presentingViewController.view.bounds
                let targetY = self.calculateYAxis(fraction: closestFraction)
                let targetHeight = self.calculateHeightBy(yAxisValue: targetY)

                self.containerView?.frame = CGRect(
                    x: 0,
                    y: targetY,
                    width: presentingBounds.width,
                    height: targetHeight
                )
                self.containerView?.layoutIfNeeded()
            })
        }
    }
}
