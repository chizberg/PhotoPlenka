//
//  PreviewCell.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 14.02.2022.
//

import UIKit

final class PreviewCell: UITableViewCell {
    private enum Style {
        static var backgroundColor: UIColor = .systemBackground
        static var imageBackground: UIColor = .systemBackground
        static var highlightedBackground: UIColor = .secondarySystemBackground
        static var cornerRadius: CGFloat = 13
        static var titleFont: UIFont = UIFont.systemFont(ofSize: 20, weight: .regular)
        static var subtitleFont: UIFont = UIFont.systemFont(ofSize: 17, weight: .bold)
        static var imageAspectRatio: CGFloat = 4 / 3 // w/h

        static var textInsets = UIEdgeInsets(top: 7, left: 10, bottom: -10, right: -10)
        static var cardMarginInsets = UIEdgeInsets(top: 5, left: 0, bottom: -5, right: 0)
        static let selectionTransform = CGAffineTransform(scaleX: 0.9, y: 0.9)
    }

    private var animator = UIViewPropertyAnimator(duration: 3, dampingRatio: 10, animations: nil)

    private var card = UIView()
    private var titleLabel: UILabel = {
        let label = UILabel()
        label.font = Style.titleFont
        label.textAlignment = .left
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentHuggingPriority(.defaultHigh, for: .vertical)
        return label
    }()

    private var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = Style.subtitleFont
        label.textAlignment = .left
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private var previewImage: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = Style.imageBackground
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        card.translatesAutoresizingMaskIntoConstraints = false
        card.clipsToBounds = true
        card.layer.cornerRadius = Style.cornerRadius
        card.backgroundColor = .systemBackground
        card.addSubview(previewImage)
        card.addSubview(titleLabel)
        card.addSubview(subtitleLabel)
        contentView.addSubview(card)
        setConstraints()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.frame = contentView.frame.inset(by: Style.cardMarginInsets)
    }

    private func setConstraints() {
        // card
        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor,
                constant: Style.cardMarginInsets.left
            ),
            card.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor,
                constant: Style.cardMarginInsets.right
            ),
            card.topAnchor.constraint(
                equalTo: contentView.topAnchor,
                constant: Style.cardMarginInsets.top
            ),
            card.bottomAnchor.constraint(
                equalTo: contentView.bottomAnchor,
                constant: Style.cardMarginInsets.bottom
            ),
        ])

        // imageView
        NSLayoutConstraint.activate([
            previewImage.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            previewImage.widthAnchor.constraint(equalTo: card.widthAnchor),
            previewImage.topAnchor.constraint(equalTo: card.topAnchor),
            previewImage.widthAnchor.constraint(
                equalTo: previewImage.heightAnchor,
                multiplier: Style.imageAspectRatio
            ),
        ])

        // titleLabel
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(
                equalTo: card.leadingAnchor,
                constant: Style.textInsets.left
            ),
            titleLabel.trailingAnchor.constraint(
                equalTo: card.trailingAnchor,
                constant: Style.textInsets.right
            ),
            titleLabel.topAnchor.constraint(
                equalTo: previewImage.bottomAnchor,
                constant: Style.textInsets.top
            ),
        ])

        // subtitleLabel
        NSLayoutConstraint.activate([
            subtitleLabel.leadingAnchor.constraint(
                equalTo: card.leadingAnchor,
                constant: Style.textInsets.left
            ),
            subtitleLabel.trailingAnchor.constraint(
                equalTo: card.trailingAnchor,
                constant: Style.textInsets.right
            ),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor),
            subtitleLabel.bottomAnchor.constraint(
                equalTo: card.bottomAnchor,
                constant: Style.textInsets.bottom
            ),
        ])
    }

    func fillIn(_ photo: Photo) {
        previewImage.image = nil
        titleLabel.text = photo.name
        fillYear(year1: photo.year, year2: photo.year2)
        ImageFetcher.shared.fetchHighestQuality(
            filePath: photo.file,
            quality: .medium
        ) { [weak self] result in
            guard let self = self else { return }
            assert(Thread.isMainThread)
            switch result {
            case let .success(image): self.previewImage.image = image
            case let .failure(error): print(error.localizedDescription)
            }
        }
    }

    private func fillYear(year1: Int, year2: Int) {
        if year1 == year2 {
            subtitleLabel.text = "\(year1) г."
        } else { subtitleLabel.text = "\(year1)-\(year2) гг." }
        subtitleLabel.textColor = UIColor.from(year: year1)
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        switch highlighted {
        case true: card.backgroundColor = Style.highlightedBackground
        case false: card.backgroundColor = Style.backgroundColor
        }
    }
}
