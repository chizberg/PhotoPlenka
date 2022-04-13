//
//  CameraViewFactory.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 08.04.2022.
//

import UIKit

final class CameraViewFactory {
    private enum Style {
        static let yearSpacing: CGFloat = 5
        static let firstYearColor: UIColor = .white
        static let secondYearColor: UIColor = .yellow
        static let upArrow: UIImage = UIImage(systemName: "arrowtriangle.up.fill")!
        static let downArrow: UIImage = UIImage(systemName: "arrowtriangle.down.fill")!
        static let yearFont: UIFont = UIFont(name: "Menlo-Bold", size: 13)!
        static let yearMargins: UIEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        static let backIcon: UIImage = UIImage(systemName: "chevron.left")!
        static let buttonMargins = UIEdgeInsets(top: 0, left: 40, bottom: 20, right: 40)
        static let modeButtonSize = CGSize(width: 40, height: 40)
        static let sliderTint: UIColor = .darkGray
    }

    func makeNewImagePreview() -> CameraPreview {
        let preview = CameraPreview()
        preview.translatesAutoresizingMaskIntoConstraints = false
        return preview
    }

    func makeRotatingImage(image: UIImageView = UIImageView()) -> RotatingContainer {
        image.contentMode = .scaleAspectFill
        let container = RotatingContainer(innerView: image)
        container.translatesAutoresizingMaskIntoConstraints = false
        return container
    }

    func makeOldImageOverlay() -> RotatingContainer {
        let image = ZoomableImageView()
        let container = RotatingContainer(innerView: image)
        container.translatesAutoresizingMaskIntoConstraints = false
        return container
    }

    func makeCompareStack() -> UIStackView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.distribution = .fill
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }

    private func makeSingleYear(alignment: NSTextAlignment, icon: UIImage?, text: String?, color: UIColor) -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fill
        stack.alignment = .center
        stack.spacing = Style.yearSpacing
        stack.translatesAutoresizingMaskIntoConstraints = false

        let imageView = UIImageView(image: icon)
        imageView.widthAnchor.constraint(equalToConstant: 13).isActive = true
        imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor).isActive = true
        imageView.tintColor = color

        let label = UILabel()
        label.text = text
        label.font = Style.yearFont
        label.textColor = color
        label.textAlignment = alignment

        if alignment == .left {
            stack.addArrangedSubview(imageView)
            stack.addArrangedSubview(label)
        } else {
            stack.addArrangedSubview(label)
            stack.addArrangedSubview(imageView)
        }
        return stack
    }

    func makeYearStack(leftYear: Int, rightYear: Int) -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.layoutMargins = Style.yearMargins
        stack.isLayoutMarginsRelativeArrangement = true
        let leftYearStack = makeSingleYear(
            alignment: .left,
            icon: Style.upArrow,
            text: "\(rightYear)",
            color: Style.secondYearColor
        )
        let rightYearStack = makeSingleYear(
            alignment: .right,
            icon: Style.downArrow,
            text: "\(leftYear)",
            color: Style.firstYearColor
        )
        stack.addArrangedSubview(leftYearStack)
        stack.addArrangedSubview(rightYearStack)
        return stack
    }

    func makeAlphaSlider() -> UISlider {
        let slider = UISlider()
        slider.value = 0.5
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.tintColor = Style.sliderTint
        return slider
    }

    func makeCameraButton() -> CameraTakeButton{
        CameraTakeButton()
    }

    func makeButtonsStack() -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .equalCentering
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.layoutMargins = Style.buttonMargins
        stack.isLayoutMarginsRelativeArrangement = true
        return stack
    }

    func makeBackButton() -> RoundButton {
        let button = RoundButton(type: .back)
        return button
    }

    func makeModeButton() -> RoundButton {
        let mode = RoundButton(type: .mode)
        return mode
    }

    func contain(button: UIButton) -> RotatingContainer {
        let container = button.contained
        container.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalToConstant: Style.modeButtonSize.width),
            container.heightAnchor.constraint(equalToConstant: Style.modeButtonSize.height)
        ])
        return container
    }
}
