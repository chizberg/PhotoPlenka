//
//  BottomNavigationController.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 24.02.2022.
//

import UIKit

// TODO: Proper default implementations
@objc protocol NavigationControllerObserver: AnyObject {
  func didPush(vc: UIViewController)
  func willPop(vc: UIViewController)
  func didPop(newLast: UIViewController)
}

final class BottomNavigationController: UINavigationController {
  let coordinatorHelper = BottomTransitionCoordinator()

  // храним множество слабых ссылок
  private(set) var observers = NSHashTable<NavigationControllerObserver>.weakObjects()

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

extension BottomNavigationController {
  func addObserver(_ obs: NavigationControllerObserver) {
    observers.add(obs)
  }

  private func notifyAllObservers(
    _ notification: @escaping (NavigationControllerObserver)
      -> Void
  ) {
    let enumerator = observers.objectEnumerator()
    while let observer = enumerator.nextObject() as? NavigationControllerObserver {
      notification(observer)
    }
  }

  private func didPush(_ vc: UIViewController) {
    notifyAllObservers { obs in
      obs.didPush(vc: vc)
    }
  }

  private func didPop(_ newLast: UIViewController) {
    notifyAllObservers { obs in
      obs.didPop(newLast: newLast)
    }
  }

  private func willPop(_ vc: UIViewController) {
    notifyAllObservers { obs in
      obs.willPop(vc: vc)
    }
  }

  override func pushViewController(_ viewController: UIViewController, animated: Bool) {
    super.pushViewController(viewController, animated: animated)
    didPush(viewController)
  }

  @discardableResult
  override func popViewController(animated: Bool) -> UIViewController? {
    if let last = viewControllers.last { willPop(last) }
    let popped = super.popViewController(animated: animated)
    if let last = viewControllers.last { didPop(last) }
    return popped
  }
}
