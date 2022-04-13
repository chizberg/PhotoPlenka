//
//  BottomNavigationController.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 24.02.2022.
//

import UIKit

final class BottomNavigationController: UINavigationController {

    let coordinatorHelper = BottomTransitionCoordinator()

    weak var observer: NavigationControllerObserver? {
        get { coordinatorHelper.observer }
        set { coordinatorHelper.observer = newValue }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        isNavigationBarHidden = true
        setCustomTransitioning()
    }
}

extension BottomNavigationController {
    func setCustomTransitioning() {
        delegate = coordinatorHelper

        // пока что на виртуалке работает как-то так себе
        let edgeSwipe = UIScreenEdgePanGestureRecognizer(
            target: self,
            action: #selector(handleSwipe(_:))
        )
        edgeSwipe.edges = .left
        view.addGestureRecognizer(edgeSwipe)
    }

    @objc private func handleSwipe(_ gestureRecognizer: UIScreenEdgePanGestureRecognizer) {
        guard let swipeView = gestureRecognizer.view else {
            coordinatorHelper.interactionController = nil
            return
        }

        let percent = gestureRecognizer.translation(in: swipeView).x / swipeView.bounds.width
        switch gestureRecognizer.state {
        case .began:
            coordinatorHelper.interactionController = UIPercentDrivenInteractiveTransition()
            popViewController(animated: true)
        case .changed:
            coordinatorHelper.interactionController?.update(percent)
        case .ended:
            if percent > 0.5, gestureRecognizer.state != .cancelled {
                coordinatorHelper.interactionController?.finish()
            } else {
                coordinatorHelper.interactionController?.cancel()
            }
            coordinatorHelper.interactionController = nil
        default: break
        }
    }
}
