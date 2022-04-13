//
//  BottomNavigation.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 13.04.2022.
//

import UIKit

protocol BottomNavigatorDelegate: AnyObject {
    func didPush()
    func didPop()
}

protocol BottomNavigatorProtocol: AnyObject {
    func present(_ vc: UIViewController, animated: Bool)
    func dismiss(_ vc: UIViewController, animated: Bool)
}

protocol BottomNavigatable: AnyObject {
    var navigator: BottomNavigatorProtocol? { get set }
}

/// This class for tracking bottom sheet controllers hierarchy and manipulating with it
/// As far as I know, a view controller can present only one other view controller at a time
/// So with bottom navigator we can easily present a new view controller from the last presented one
final class BottomNavigator: BottomNavigatorProtocol {
    private(set) var viewControllers: [UIViewController] = []
    weak var navigationDelegate: BottomNavigatorDelegate?
    weak var heightObserver: BottomSheetHeightObserver?
    weak var presenting: UIViewController?
    private weak var bottomSheetDelegate: BottomSheetDelegate?
//    private lazy var transitionDelegate = BottomSheetTransitionDelegate(bottomSheetFactory: self)
//    var transitionDelegate: BottomSheetTransitionDelegate {
//        BottomSheetTransitionDelegate(bottomSheetFactory: self)
//    }
    private var delegates = [UIViewController: BottomSheetTransitionDelegate]()

    func delegate(for vc: UIViewController) -> BottomSheetTransitionDelegate {
        guard let delegate = delegates[vc] else {
            delegates[vc] = BottomSheetTransitionDelegate(bottomSheetFactory: self)
            return delegates[vc]!
        }
        return delegate
    }

    var first: UIViewController {
        guard !viewControllers.isEmpty else {
            fatalError("viewControllers are empty")
        }
        return viewControllers[0]
    }

    var last: UIViewController {
        guard !viewControllers.isEmpty else {
            fatalError("viewControllers are empty")
        }
        return viewControllers.last!
    }

    init(initialViewController: UIViewController, presenting: UIViewController){
        self.viewControllers = []
        self.presenting = presenting
        initialViewController.modalPresentationStyle = .custom
        initialViewController.transitioningDelegate = delegate(for: initialViewController)
        self.viewControllers.append(initialViewController)
        if let bn = initialViewController as? BottomNavigatable {
            bn.navigator = self
        }
    }

    func present(_ vc: UIViewController, animated: Bool){
        if let details = viewControllers.last as? PhotoDetailsController {
            dismiss(details, animated: animated)
        }
        guard !viewControllers.isEmpty else {
            fatalError("nothing to present from")
        }
        if let bn = vc as? BottomNavigatable {
            bn.navigator = self
        }
        vc.modalPresentationStyle = .custom
        vc.transitioningDelegate = delegate(for: vc)
//        collapse(last)
        last.present(vc, animated: false)
        viewControllers.append(vc)
        navigationDelegate?.didPush()
    }

    func dismiss(_ vc: UIViewController, animated: Bool) {
        guard let index = viewControllers.firstIndex(of: vc) else {
            fatalError("the navigator does not contain viewController")
        }
        vc.dismiss(animated: true)
        viewControllers = Array(viewControllers[..<index])
        navigationDelegate?.didPop()
    }

    private func collapse(_ vc: UIViewController){
        guard let presentingBounds = presenting?.view.bounds else { return }
//        DispatchQueue.main.async {
//            UIView.animate(withDuration: 0.25){
//
//            }
//        }
        vc.view.frame = CGRect(
            x: 0,
            y: 100,
            width: vc.view.bounds.width,
            height: vc.view.bounds.height
        )
        vc.view.layoutIfNeeded()
//        vc.view.isHidden = true
    }
}

extension BottomNavigator: BottomSheetFactory {
    func makePresentationController(presentedViewController: UIViewController, presenting: UIViewController?) -> UIPresentationController {
        guard !viewControllers.isEmpty, let presenting = presenting else {
            fatalError("nothing to show")
        }
        let controller = BottomSheetPresentationController(
            fractions: [0.15, 0.65, 0.85],
            presentedViewController: presentedViewController,
            presenting: presenting,
            contentViewController: presentedViewController,
            parentController: heightObserver as! MapController
        )
        bottomSheetDelegate = controller
        controller.heightObserver = heightObserver
        return controller
    }
}
