//
//  ActionButton.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 25.02.2022.
//

import UIKit

internal class ActionButton: SquishyButton {
    private enum Style {
        static let labelFont: UIFont = UIFont.systemFont(ofSize: 17, weight: .regular)
        static let cornerRadius: CGFloat = 13
        static let padding: CGFloat = 10
        static let spacing: CGFloat = 5
        static let activatedLabelColor: UIColor = .systemBackground
        static let stockActivatedBackgroundColor: UIColor = .secondarySystemBackground
        static let backgroundColor: UIColor = .systemBackground
    }

    private var accentColor: UIColor?
    private let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor).isActive = true
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    let label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = Style.labelFont
        return label
    }()

    let stack: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.isUserInteractionEnabled = false
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .fill
        stack.spacing = Style.spacing
        return stack
    }()

    convenience init(iconSystemName: String, title: String, color: UIColor?) {
        self.init(icon: UIImage(systemName: iconSystemName)!, title: title, color: color)
    }

    init(icon: UIImage, title: String, color: UIColor?) {
        self.accentColor = color
        super.init(frame: .zero)

        label.text = title
        iconView.image = icon

        backgroundColor = Style.backgroundColor
        updateLayout(isSelected: false)
        layer.cornerRadius = Style.cornerRadius

        stack.addArrangedSubview(iconView)
        stack.addArrangedSubview(label)
        addSubview(stack)
        applyConstraints()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateContent(newIcon: UIImage? = nil, newTitle: String? = nil, newColor: UIColor? = nil) {
        if let newIcon = newIcon {
            iconView.image = newIcon
        }
        if let newTitle = newTitle {
            label.text = newTitle
        }
        if let newColor = newColor {
            accentColor = newColor
        }
    }

    private func applyConstraints() {
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Style.padding),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Style.padding),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: Style.padding),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Style.padding),
        ])

        NSLayoutConstraint.activate([
            iconView.heightAnchor.constraint(equalTo: stack.heightAnchor),
        ])
    }

    override func updateLayout(isSelected: Bool) {
        switch isSelected {
        case true:
            guard let accentColor = accentColor else {
                backgroundColor = Style.stockActivatedBackgroundColor
                return
            }
            label.textColor = Style.activatedLabelColor
            iconView.tintColor = Style.activatedLabelColor
            backgroundColor = accentColor
        case false:
            let accent = accentColor ?? .label
            label.textColor = accent
            iconView.tintColor = accent
            backgroundColor = Style.backgroundColor
        }
    }
}
