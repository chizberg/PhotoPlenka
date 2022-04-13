//
//  PresentationController.swift
//  PhotoPlenka
//
//  Created by Dmitry Trifonov on 05.02.2022.
//

import Foundation
import UIKit

protocol BottomSheetHeightObserver: AnyObject {
    func heightDidChange(newHeight: CGFloat)
    func heightWillChange(newHeight: CGFloat, in duration: Double)
}

protocol BottomSheetDelegate: AnyObject {
    func heightShouldBeAt(fraction: CGFloat, animated: Bool)
}

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

    private var initialFrame: CGRect = .zero
    private let fractions: [Double]
    weak var heightObserver: BottomSheetHeightObserver?
    private weak var scrollView: UIScrollView?
    private weak var headerView: UIView?
    private var mode: Mode = .collapsed
    private var scrollPanGesture: UIPanGestureRecognizer!
    private var headerPanGesture: UIPanGestureRecognizer!
    private var scrollViewOffset: CGFloat = 0
    private unowned var contentViewController: UIViewController

    //is used to check bounds of mapController, not presentingController
    private unowned var fullScreenController: UIViewController

    func gestureRecognizer(
        _: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith _: UIGestureRecognizer
    ) -> Bool {
        true
    }

    override var shouldPresentInFullscreen: Bool {
        false
    }

    override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerViewBounds = fullScreenController.view?.bounds,
              let firstFraction = fractions.first else {
            assertionFailure("Presenting view must exist")
            return .zero
        }

        let height = calculateHeightBy(fraction: firstFraction)
        let y = calculateYAxis(height: height)

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
        presenting presentingViewController: UIViewController?,
        contentViewController: UIViewController,
        parentController: UIViewController
    ) {
        guard !fractions.isEmpty else {
            fatalError("Must have at least one element")
        }
        self.fractions = fractions.sorted(by: <)
        self.contentViewController = contentViewController
        self.fullScreenController = parentController
        super.init(
            presentedViewController: presentedViewController,
            presenting: presentingViewController
        )
    }
}

extension BottomSheetPresentationController: BottomSheetDelegate {
    func heightShouldBeAt(fraction: CGFloat, animated: Bool) {
        let closestFraction = findClosestValue(fraction, from: fractions)
        updateModeIfNeeded(currentFraction: closestFraction, fractions: fractions)
        enableScrollIfNeeded(mode: mode)
        animateView(toFraction: closestFraction, duration: animated ? 0.4 : 0.0)
    }
}

// MARK: - Configure methods

extension BottomSheetPresentationController {
    private func configurePanGesture() {
        scrollPanGesture = UIPanGestureRecognizer(
            target: self,
            action: #selector(scrollGestureHandler(_:))
        )
        scrollPanGesture.delegate = self
        headerPanGesture = UIPanGestureRecognizer(
            target: self,
            action: #selector(headerGestureHandler)
        )
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
            panChangedHandler(
                offset: transition,
                view: containerView!,
                initialFrame: initialFrame
            )
        } else if gesture.state == .ended || gesture.state == .cancelled {
            panEndedHandler(gesture)
        }
    }
}

// MARK: - Helpers

extension BottomSheetPresentationController {
    private func calculateYAxis(height: Double) -> Double {
        let presentingBounds = presentingViewController.view.bounds
        return presentingBounds.height - height
    }

    private func calculateHeightBy(fraction: Double) -> Double {
        let fullScreen = fullScreenController.view.bounds
        return fullScreen.height * fraction
//        fullScreenController.view.bounds.height - yAxisValue
    }
}

// MARK: - Presentation Controller methods

extension BottomSheetPresentationController {
    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        if let scrollable = contentViewController as? ScrollableViewController {
            scrollView = scrollable.scrollView
            headerView = scrollable.header
            scrollView?.multicastingDelegate.addDelegate(self)
            scrollView?.isScrollEnabled = false
        }
        animatePresent(toFraction: fractions[0], duration: 0.4)
    }

    override func presentationTransitionDidEnd(_ completed: Bool) {
        super.presentationTransitionDidEnd(completed)
        configurePanGesture()
    }

    // These methods are not used now, but will be used in the future
    override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()
        animateDismiss(duration: 5)
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
        guard let containerFrame = containerView?.frame else { return }

        if gesture.state == .began {
            initialFrame = containerFrame
        } else if gesture.state == .changed {
            scrollView?.isScrollEnabled = false
            let transition = gesture.translation(in: presentedView).y
            panChangedHandler(
                offset: transition,
                view: containerView!,
                initialFrame: initialFrame
            )
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
        self.heightObserver?.heightDidChange(newHeight: self.containerView?.frame.height ?? 0)
    }

    private func panEndedHandler(_ gesture: UIPanGestureRecognizer) {
        // Calculate how much spaces container view takes
        let progressValue = 1 -
            (containerView!.frame.minY / fullScreenController.view.bounds.height)
        var closestFraction = findClosestValue(progressValue, from: fractions)

        updateClosestFractionIfNeeded(
            velocityByY: gesture.velocity(in: presentedView).y,
            closestValue: &closestFraction,
            fractions: fractions
        )
        updateModeIfNeeded(currentFraction: closestFraction, fractions: fractions)
        enableScrollIfNeeded(mode: mode)
        animateView(toFraction: closestFraction, duration: 0.35)
    }

    private func animateView(toFraction value: CGFloat, duration: CGFloat) {
        let presentingBounds = fullScreenController.view.bounds
        let targetHeight = calculateHeightBy(fraction: value)
        let targetY = calculateYAxis(height: targetHeight)
        heightObserver?.heightWillChange(newHeight: targetHeight, in: duration)

        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut) {
            self.containerView?.frame = CGRect(
                x: 0,
                y: targetY,
                width: presentingBounds.width,
                height: targetHeight
            )
            self.containerView?.layoutIfNeeded()
        }
    }

    private func animatePresent(toFraction value: CGFloat, duration: CGFloat) {
        let presentingBounds = fullScreenController.view.bounds
        let targetHeight = calculateHeightBy(fraction: value)
        let targetY = calculateYAxis(height: targetHeight)

        self.containerView?.frame = CGRect(
            x: 0,
            y: presentingBounds.height,
            width: presentingBounds.width,
            height: 0
        )

        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut) {
            self.containerView?.frame = CGRect(
                x: 0,
                y: targetY,
                width: presentingBounds.width,
                height: targetHeight
            )
            self.containerView?.layoutIfNeeded()
        }
    }

    private func animateDismiss(duration: CGFloat) {
        heightShouldBeAt(fraction: 0, animated: true)
    }


    private func updateModeIfNeeded(currentFraction: CGFloat, fractions: [Double]) {
        mode = currentFraction == fractions.last! ? .opened : .collapsed
    }

    private func enableScrollIfNeeded(mode: Mode) {
        scrollView?.isScrollEnabled = mode == .opened
    }

    // If velocity value is too high,
    // the distanse between first and last touches doesn't matter
    // we can just skip to the next mode
    private func updateClosestFractionIfNeeded(
        velocityByY value: CGFloat,
        closestValue: inout Double,
        fractions: [Double]
    ) {
        guard let indexWhere = fractions.firstIndex(of: closestValue) else {
            fatalError("Incorrect fractions")
        }

        if value <= -Self.verticalVelocityThreashold {
            let indexAfter = fractions.index(after: indexWhere)
            if indexAfter < fractions.count {
                closestValue = fractions[indexAfter]
            }
        } else if value >= Self.verticalVelocityThreashold {
            let indexBefore = fractions.index(before: indexWhere)
            if indexBefore >= 0 {
                closestValue = fractions[indexBefore]
            }
        }
    }

    static let verticalVelocityThreashold: CGFloat = 1000
}

fileprivate func findClosestValue(_ value: Double, from values: [Double]) -> Double {
    var minDistance = 1.0
    var closestFractionIndex = 0
    for (index, fraction) in values.enumerated() {
        if abs(fraction - value) < minDistance {
            minDistance = abs(fraction - value)
            closestFractionIndex = index
        }
    }
    return values[closestFractionIndex]
}

extension UIScrollView {
    private static var transitionKey: UInt8 = 0

    public var multicastingDelegate: UIControlMulticastDelegate {
        if let object = objc_getAssociatedObject(
            self,
            &Self.transitionKey
        ) as? UIControlMulticastDelegate {
            return object
        }

        let object = UIControlMulticastDelegate(
            target: self,
            delegateGetter: #selector(getter: delegate),
            delegateSetter: #selector(setter: delegate)
        )
        objc_setAssociatedObject(
            self,
            &Self.transitionKey,
            object,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
        return object
    }
}
