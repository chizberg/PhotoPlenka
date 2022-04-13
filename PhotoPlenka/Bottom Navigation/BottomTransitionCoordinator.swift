//
//  BottomTransitionCoordinator.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 24.02.2022.
//

import UIKit

protocol NavigationControllerObserver: AnyObject {
    func didLeaveSinglePhoto()
}

final class BottomTransitionCoordinator: NSObject, UINavigationControllerDelegate {
    var interactionController: UIPercentDrivenInteractiveTransition? // меняем его в BottomNavigationController
    weak var observer: NavigationControllerObserver?

    func navigationController(
        _: UINavigationController,
        animationControllerFor operation: UINavigationController.Operation,
        from _: UIViewController,
        to _: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        BottomTransitionAnimator(operation)
    }

    func navigationController(
        _: UINavigationController,
        interactionControllerFor _: UIViewControllerAnimatedTransitioning
    ) -> UIViewControllerInteractiveTransitioning? {
        interactionController
    }

    func navigationController(
        _ navigationController: UINavigationController,
        willShow _: UIViewController,
        animated _: Bool
    ) {
        guard navigationController.viewControllers.last is PhotoDetailsController else {
            observer?.didLeaveSinglePhoto()
            return
        }
    }
}
