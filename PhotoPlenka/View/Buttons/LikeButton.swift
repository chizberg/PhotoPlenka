//
//  LikeButton.swift
//  SquishyButton
//
//  Created by Алексей Шерстнёв on 21.02.2022.
//

import UIKit

final class LikeButton: SquishyButton {
    private enum Constants {
        static let activeIcon: UIImage = UIImage(systemName: "heart.fill")!
        static let passiveIcon: UIImage = UIImage(systemName: "heart")!
        static let title: String = "Избранное"
        static let color: UIColor = .systemRed
    }
    
    var isLiked: Bool {
        didSet {
            updateImage(isActive: isLiked)
        }
    }
    
    init(isLiked: Bool = false){
        self.isLiked = isLiked
        super.init(icon: Constants.passiveIcon, title: Constants.title, color: Constants.color)
        updateImage(isActive: isLiked)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func updateImage(isActive: Bool){
        let newIcon = isActive ? Constants.activeIcon : Constants.passiveIcon
        updateContent(newIcon: newIcon)
    }
}
