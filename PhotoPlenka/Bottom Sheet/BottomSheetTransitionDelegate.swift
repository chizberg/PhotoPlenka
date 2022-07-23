//
//  BottomSheetTransitionDelegate.swift
//  PhotoPlenka
//
//  Created by Dmitry Trifonov on 05.02.2022.
//

import Foundation
import UIKit

protocol BottomSheetFactory {
  func makePresentationController(
    presentedViewController: UIViewController,
    presenting: UIViewController?
  ) -> UIPresentationController
}

final class BottomSheetTransitionDelegate: NSObject, UIViewControllerTransitioningDelegate {
  private let bottomSheetFactory: BottomSheetFactory

  init(bottomSheetFactory: BottomSheetFactory) {
    self.bottomSheetFactory = bottomSheetFactory
  }

  func presentationController(
    forPresented presented: UIViewController,
    presenting: UIViewController?,
    source: UIViewController
  ) -> UIPresentationController? {
    bottomSheetFactory.makePresentationController(
      presentedViewController: presented,
      presenting: presenting ?? source
    )
  }
}
