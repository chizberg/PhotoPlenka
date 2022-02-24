//
//  BottomNavigationController.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 24.02.2022.
//

import UIKit

final class BottomNavigationController: UINavigationController {
    private enum Constants {
        static let cornerRadius: CGFloat = 29
        static let maskedCorners: CACornerMask = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    }
    
    let backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
    let coordinatorHelper = BottomTransitionCoordinator()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.layer.cornerRadius = Constants.cornerRadius
        view.layer.maskedCorners = Constants.maskedCorners
        view.clipsToBounds = true
        view.insertSubview(backgroundView, at: 0)
    }
    
    override func viewDidLayoutSubviews() {
        backgroundView.frame = view.bounds
    }
}

extension BottomNavigationController {
    func setCustomTransitioning(){
        delegate = coordinatorHelper
        
    }
    
    @objc private func handleSwipe(_ gestureRecognizer: UIScreenEdgePanGestureRecognizer){
        guard let swipeView = gestureRecognizer.view else {
            coordinatorHelper.interactionController = nil
            return
        }
        
        let percent = gestureRecognizer.translation(in: <#T##UIView?#>)
    }
}
