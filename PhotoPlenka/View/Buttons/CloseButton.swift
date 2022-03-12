//
//  CloseButton.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 07.03.2022.
//

import UIKit

final class CloseButton: SquishyButton {
    private enum Constants {
        static let tintColor: UIColor = .label
        static let blurStyle: UIBlurEffect.Style = .systemThinMaterial
        static let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
        static let icon: UIImage = UIImage(systemName: "xmark", withConfiguration: config)!
    }

    let blur = UIVisualEffectView(effect: UIBlurEffect(style: Constants.blurStyle))

    init() {
        super.init(frame: .zero)
        setTitle(nil, for: .normal)
        backgroundColor = .clear
        setImage(Constants.icon, for: .normal)
        tintColor = Constants.tintColor
        blur.isUserInteractionEnabled = false
        blur.layer.masksToBounds = true
        self.insertSubview(blur, at: 0)
        if let imageView = imageView {
            bringSubviewToFront(imageView)
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        blur.frame = bounds
        blur.layer.cornerRadius = blur.frame.width / 2
    }
}
