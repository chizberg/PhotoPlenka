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

    //storing gesture recognizers
    var scrollPan: UIGestureRecognizer? { get set }
    var headerPan: UIGestureRecognizer? { get set }
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
    private weak var scrollView: UIScrollView? {
        didSet {
            updateScrollViewInsets()
        }
    }
    private weak var headerView: UIView?
    private var mode: Mode = .collapsed
    private var scrollPanGesture: UIPanGestureRecognizer {
        let pan = UIPanGestureRecognizer(
            target: self,
            action: #selector(scrollGestureHandler(_:))
        )
        pan.delegate = self
        return pan
    }
    private var headerPanGesture: UIPanGestureRecognizer {
        UIPanGestureRecognizer(
            target: self,
            action: #selector(headerGestureHandler)
        )
    }
    private var scrollViewOffset: CGFloat = 0
    private unowned var contentViewController: UIViewController

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
        guard let containerViewBounds = presentingViewController.view?.bounds,
              let firstFraction = fractions.first else {
            assertionFailure("Presenting view must exist")
            return .zero
        }

        let y = calculateYAxis(fraction: firstFraction)

        return .init(
            x: 0,
            y: y,
            width: containerViewBounds.width,
            height: containerViewBounds.height
        )
    }

    init(
        fractions: [Double],
        presentedViewController: UIViewController,
        presenting presentingViewController: UIViewController?,
        contentViewController: UIViewController
    ) {
        guard !fractions.isEmpty else {
            fatalError("Must have at leat one element")
        }
        self.fractions = fractions.sorted(by: <)
        self.contentViewController = contentViewController
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
    private func calculateYAxis(fraction: Double) -> Double {
        let presentingBounds = self.presentingViewController.view.bounds
        return presentingBounds.height - presentingBounds.height * fraction
    }

    private func calculateVisibleHeightBy(yAxisValue: Double) -> Double {
        presentingViewController.view.bounds.height - yAxisValue
    }

    private func fraction(from height: Double) -> Double {
        let presentingBounds = self.presentingViewController.view.bounds
        return height / presentingBounds.height
    }

    private var currentFraction: Double {
        1.0 - (containerView!.frame.minY / presentingViewController.view.bounds.height)
    }

    private var visibleHeight: Double {
        presentingViewController.view.bounds.height - containerView!.frame.minY
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
        let newHeight = max(initialFrame.height, initialFrame.height - offset)
        view.frame = .init(
            x: 0,
            y: initialFrame.minY + offset,
            width: initialFrame.width,
            height: newHeight
        )
        heightDidChange(newHeight: visibleHeight)
    }

    private func panEndedHandler(_ gesture: UIPanGestureRecognizer) {
        // Calculate how much spaces container view takes
        var closestFraction = findClosestValue(currentFraction, from: fractions)

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
        let presentingBounds = presentingViewController.view.bounds
        let targetY = calculateYAxis(fraction: value)
        let targetHeight = calculateVisibleHeightBy(yAxisValue: targetY)
        heightWillChange(newHeight: targetHeight, in: duration)

        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut) {
            self.containerView?.frame = CGRect(
                x: 0,
                y: targetY,
                width: presentingBounds.width,
                height: max(presentingBounds.height, targetHeight)
            )
            self.containerView?.layoutIfNeeded()
        }
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

    private func updateScrollViewInsets(newHeight: Double? = nil){
        let height = newHeight ?? visibleHeight
        let inset = presentingViewController.view.bounds.height - height
        scrollView?.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: inset, right: 0)
    }
}

extension BottomSheetPresentationController {
    func heightDidChange(newHeight: CGFloat) {
        heightObserver?.heightDidChange(newHeight: newHeight)
    }
    func heightWillChange(newHeight: CGFloat, in duration: Double) {
        heightObserver?.heightWillChange(newHeight: newHeight, in: duration)
        updateScrollViewInsets(newHeight: newHeight)
        popDetailsIfNeeded(newHeight: newHeight)
    }
}

extension BottomSheetPresentationController: NavigationControllerObserver {
    func didPush(vc: UIViewController) {
        guard var vc = vc as? ScrollableViewController else {return}
        vc.scrollPan = scrollPanGesture
        vc.headerPan = headerPanGesture
        scrollView = vc.scrollView
        headerView = vc.header
        expandIfNeeded(animated: true)
    }

    func willPop(vc: UIViewController) {}

    func didPop(newLast: UIViewController) {
        guard let vc = newLast as? ScrollableViewController else { return }
        scrollView = vc.scrollView
        headerView = vc.header
    }
}

// MARK: - expansion and popping
extension BottomSheetPresentationController {
    // A minimal fraction that pushed viewController (i.e. PhotoDetailsController) should be presented with
    // If the fraction is smaller, the screen gets dismissed
    private var minPresentingFraction: Double {
        guard fractions.count > 1 else {fatalError("fractions are empty")}
        return fractions[1]
    }

    // Is used when new screen is pushed in navigation controller
    // Automatically expands to a minPresentingFraction
    private func expandIfNeeded(animated: Bool){
        if currentFraction < minPresentingFraction {
            heightShouldBeAt(fraction: minPresentingFraction, animated: animated)
        }
    }

    // Photo Details should pop when minimized
    private func popDetailsIfNeeded(newHeight: Double){ // works only with UINavigationController in bottom sheet
        guard let navigation = presentedViewController as? BottomNavigationController else { return }
        guard fraction(from: newHeight) < minPresentingFraction else { return }
        if navigation.viewControllers.last is PhotoDetailsController {
            navigation.popViewController(animated: true)
        }
    }
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
