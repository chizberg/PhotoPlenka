//
//  PresentationController.swift
//  PhotoPlenka
//
//  Created by Dmitry Trifonov on 05.02.2022.
//

import Foundation
import UIKit

protocol ScrollableViewController {
    var scrollView: UIScrollView { get }
    var header: UIView { get }
}

final class BottomSheetPresentationController: UIPresentationController,
                                               UIGestureRecognizerDelegate,
                                               UIScrollViewDelegate {
    enum Mode {
        case opened
        case collapsed
    }
    private weak var scrollView: UIScrollView?
    private weak var headerView: UIView?
    private let fractions: [Double]
    private var mode: Mode = .collapsed
    private var initialFrame: CGRect = .zero
    private var scrollPanGesture: UIPanGestureRecognizer!
    private var headerPanGesture: UIPanGestureRecognizer!
    private var scrollViewOffset: CGFloat = 0

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

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
        scrollPanGesture = UIPanGestureRecognizer(target: self, action: #selector(scrollGestureHandler(_:)))
        scrollPanGesture.delegate = self
        headerPanGesture = UIPanGestureRecognizer(target: self, action: #selector(headerGestureHandler))
        headerView?.addGestureRecognizer(headerPanGesture)
        scrollView?.addGestureRecognizer(scrollPanGesture)
    }

    @objc
    func headerGestureHandler(_ gesture: UIPanGestureRecognizer) {
        if gesture.state == .began {
            scrollViewOffset = scrollView!.contentOffset.y
            initialFrame = containerView!.frame
            scrollView?.isScrollEnabled = false
        } else if gesture.state == .changed {
            scrollView?.setContentOffset(.init(x: 0, y: scrollViewOffset), animated: false)

            let transition = gesture.translation(in: presentedView).y
            panChangedHandler(offset: transition,
                              view: containerView!,
                              initialFrame: initialFrame)
        } else if gesture.state == .ended || gesture.state == .cancelled {
            panEndedHandler(gesture)
        }
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
        if let navigationController = presentedViewController as? UINavigationController,
           let scrollable = navigationController.topViewController as? ScrollableViewController {
            scrollView = scrollable.scrollView
            headerView = scrollable.header
            scrollView?.delegate = self
            scrollView?.isScrollEnabled = false
        }
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
    func scrollGestureHandler(_ gesture: UIPanGestureRecognizer) {
        guard scrollView!.contentOffset.y <= 0 || mode == .collapsed else { return }
        guard let containerFrame = containerView?.frame else {
            return
        }

        if gesture.state == .began {
            initialFrame = containerFrame
        } else if gesture.state == .changed {
            scrollView?.isScrollEnabled = false
            let transition = gesture.translation(in: presentedView).y
            panChangedHandler(offset: transition,
                              view: containerView!,
                              initialFrame: initialFrame)
        } else if gesture.state == .ended || gesture.state == .cancelled {
            panEndedHandler(gesture)
        }
    }

    private func panChangedHandler(offset: CGFloat, view: UIView, initialFrame: CGRect) {
        view.frame = .init(
            x: 0,
            y: initialFrame.minY + offset,
            width: initialFrame.width,
            height: initialFrame.height - offset
        )
    }

    private func panEndedHandler(_ gesture: UIPanGestureRecognizer) {
        let progressLocation = 1 -
        (containerView!.frame.minY / presentingViewController.view.bounds.height)
        var closestFraction = self.findMostCloseFraction(progressLocation)

        let indexWhere = fractions.firstIndex(of: closestFraction)!
        if gesture.velocity(in: presentedView).y <= -Self.verticalVelocityThreashold {
            let indexAfter = fractions.index(after: indexWhere)
            if indexAfter < fractions.count {
                closestFraction = fractions[indexAfter]
            }
        } else if gesture.velocity(in: presentedView).y >= Self.verticalVelocityThreashold {
            let indexBefore = fractions.index(before: indexWhere)
            if indexBefore >= 0 {
                closestFraction = fractions[indexBefore]
            }
        }

        scrollView?.isScrollEnabled = closestFraction == fractions.last!
        mode = closestFraction == fractions.last! ? .opened : .collapsed
        let presentingBounds = self.presentingViewController.view.bounds
        let targetY = self.calculateYAxis(fraction: closestFraction)
        let targetHeight = self.calculateHeightBy(yAxisValue: targetY)

        UIView.animate(withDuration: 0.2, animations: {
            self.containerView?.frame = CGRect(
                x: 0,
                y: targetY,
                width: presentingBounds.width,
                height: targetHeight
            )
            self.containerView?.layoutIfNeeded()
        })
    }

    static let verticalVelocityThreashold: CGFloat = 1000
}
