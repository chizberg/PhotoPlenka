//
//  LoadingImageView.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 25.02.2022.
//

import UIKit

// imageView with loading indicator
final class LoadingImageView: UIImageView {
    private enum Style {
        static let backgroundColor: UIColor = .systemBackground
    }

    private let loadingIndicator = UIActivityIndicatorView(style: .medium)

    init() {
        super.init(frame: .zero)
        addSubview(loadingIndicator)

        backgroundColor = Style.backgroundColor
        contentMode = .scaleAspectFill
        clipsToBounds = true
        isLoading = true
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        loadingIndicator.center.x = bounds.width / 2
        loadingIndicator.center.y = bounds.height / 2
    }

    override var image: UIImage? {
        didSet {
            isLoading = false
        }
    }

    var isLoading: Bool {
        get { loadingIndicator.isAnimating }
        set {
            loadingIndicator.isHidden = !newValue
            newValue ? loadingIndicator.startAnimating() : loadingIndicator.stopAnimating()
        }
    }
}
