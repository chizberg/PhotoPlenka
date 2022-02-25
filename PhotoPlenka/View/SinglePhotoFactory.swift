//
//  SinglePhotoFactory.swift
//  SquishyButton
//
//  Created by Алексей Шерстнёв on 21.02.2022.
//

import UIKit

final class SinglePhotoFactory {
    private enum Style {
        static let buttonVerticalSpacing: CGFloat = 10
        static let buttonHorizontalSpacing: CGFloat = buttonVerticalSpacing
        static let buttonRowHeight: CGFloat = 50

        static let detailsSpacing: CGFloat = 5
        static let propertyVerticalSpacing: CGFloat = 0
        static let propertyHorizontalSpacing: CGFloat = 5
        static let captionColor: UIColor = .secondaryLabel

        static let detailsPadding: UIEdgeInsets = .init(top: 10, left: 10, bottom: 10, right: 10)
        static let detailsBackground: UIColor = .systemBackground
        static let detailsCornerRadius: CGFloat = 13

        static let contentStackSpacing: CGFloat = buttonVerticalSpacing
        static let scrollRadiusMask: CACornerMask = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    }

    enum FontType {
        case titleLabel
        case yearLabel
        case propertyLabel
        case description
        case caption
    }

    enum HorizontalPropertyType {
        case author
        case uploadedBy
    }

    func stackFromButtons(buttons: [UIButton], rowCapacity: Int = 2) -> UIStackView {
        let verticalStack = makeButtonStack(axis: .vertical)
        let groups = stride(from: 0, to: buttons.count, by: rowCapacity)
            .map { (i: Int) -> [UIButton] in
                var output = [UIButton]()
                output.reserveCapacity(rowCapacity)
                for j in i..<i + rowCapacity {
                    if j < buttons.count { output.append(buttons[j]) }
                }
                return output
            }
        for group in groups {
            let horizontalStack = makeButtonStack(axis: .horizontal)
            for button in group {
                horizontalStack.addArrangedSubview(button)
            }
            verticalStack.addArrangedSubview(horizontalStack)
        }
        return verticalStack
    }

    private func makeButtonStack(axis: NSLayoutConstraint.Axis) -> UIStackView {
        let stack = UIStackView()
        stack.axis = axis
        stack.alignment = .fill
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        switch axis {
        case .horizontal:
            stack.spacing = Style.buttonHorizontalSpacing
            stack.heightAnchor.constraint(equalToConstant: Style.buttonRowHeight).isActive = true
        case .vertical:
            stack.spacing = Style.buttonVerticalSpacing
        @unknown default:
            break
        }
        return stack
    }

    func makeLabel(fontType: FontType) -> UILabel {
        let label = UILabel()
        label.font = fontType.font
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }

    func makeDetailsStack() -> UIStackView {
        let stack = UIStackView()
        stack.spacing = Style.detailsSpacing
        stack.axis = .vertical
        stack.alignment = .fill
        stack.distribution = .equalSpacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.backgroundColor = Style.detailsBackground
        stack.layer.cornerRadius = Style.detailsCornerRadius
        stack.layoutMargins = Style.detailsPadding
        stack.isLayoutMarginsRelativeArrangement = true
        return stack
    }

    func makePropertyStack(type: HorizontalPropertyType) -> UIStackView {
        let stack = UIStackView()
        stack.spacing = Style.propertyVerticalSpacing
        stack.axis = .vertical
        stack.alignment = .fill
        stack.distribution = .equalSpacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        let captionLabel = makeLabel(fontType: .caption)
        captionLabel.text = type.labelText
        captionLabel.textColor = Style.captionColor
        stack.addArrangedSubview(captionLabel)
        return stack
    }

    func makeHorizontalPropertiesStack() -> UIStackView {
        let stack = UIStackView()
        stack.spacing = Style.propertyHorizontalSpacing
        stack.axis = .horizontal
        stack.alignment = .top
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }

    func makeContentStack() -> UIStackView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.spacing = Style.contentStackSpacing
        stack.alignment = .fill
        stack.distribution = .equalSpacing
        return stack
    }

    func makeScrollView() -> UIScrollView {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.layer.cornerRadius = Style.detailsCornerRadius
        scroll.layer.maskedCorners = Style.scrollRadiusMask
        scroll.clipsToBounds = true
        scroll.delaysContentTouches = false
        scroll.showsVerticalScrollIndicator = false
        return scroll
    }

    func makeImageView() -> UIImageView {
        let imageView = LoadingImageView()
        imageView.layer.cornerRadius = Style.detailsCornerRadius
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }
}

extension SinglePhotoFactory.FontType {
    var font: UIFont {
        switch self {
        case .titleLabel: return UIFont.systemFont(ofSize: 25, weight: .bold)
        case .yearLabel: return UIFont.systemFont(ofSize: 25, weight: .semibold)
        case .propertyLabel: return UIFont.systemFont(ofSize: 17, weight: .regular)
        case .description: return UIFont.systemFont(ofSize: 17, weight: .regular)
        case .caption: return UIFont.systemFont(ofSize: 12, weight: .semibold)
        }
    }
}

extension SinglePhotoFactory.HorizontalPropertyType {
    var labelText: String {
        switch self {
        case .author: return "Автор".uppercased()
        case .uploadedBy: return "Uploaded by".uppercased()
        }
    }
}
