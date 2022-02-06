//
//  BottomSheetTransitionDelegate.swift
//  PhotoPlenka
//
//  Created by Dmitry Trifonov on 05.02.2022.
//

import Foundation
import UIKit

protocol BottomSheetFactory {
  func makePresentationController(presentedViewController: UIViewController,
                                  presenting: UIViewController?) -> UIPresentationController
}

final class BottomSheetTransitionDelegate: NSObject, UIViewControllerTransitioningDelegate {
  
  private let buttomSheetFactory: BottomSheetFactory
  
  init(buttomSheetFactory: BottomSheetFactory) {
    self.buttomSheetFactory = buttomSheetFactory
  }
  
  func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
    return buttomSheetFactory.makePresentationController(presentedViewController: presented, presenting: presenting ?? source)
  }
}
