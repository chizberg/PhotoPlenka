//
//  CameraTakeButton.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 08.04.2022.
//

import UIKit

enum CameraTakeButtonState {
    case take
    case redo
}

final class CameraTakeButton: UIButton {
    private enum Style {
        static let borderColor: UIColor = .white
        static let borderWidth: CGFloat = 3.5
        static let separatorWidth: CGFloat = 2.5
        static let innerMargin: CGFloat = borderWidth + separatorWidth
        static let buttonSize: CGSize = .init(width: 72, height: 72)
    }

    private let inner: InnerButton
    private let background = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialDark))

    init() {
        let innerSize = shrink(size: Style.buttonSize, by: Style.innerMargin)
        inner = InnerButton(frame: CGRect(origin: .zero, size: innerSize))
        super.init(frame: .zero)
        clipsToBounds = true
        addSubview(background)
        addSubview(inner)
        layer.borderWidth = Style.borderWidth
        layer.borderColor = Style.borderColor.cgColor
        translatesAutoresizingMaskIntoConstraints = false
        applySizeConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        background.frame = bounds
        layer.cornerRadius = bounds.height/2
        inner.center = CGPoint(x: bounds.width/2, y: bounds.height/2)
    }

    override func addTarget(_ target: Any?, action: Selector, for controlEvents: UIControl.Event) {
        inner.addTarget(target, action: action, for: controlEvents)
    }

    func set(state: CameraTakeButtonState){
        inner.set(state: state)
    }

    func applySizeConstraints(){
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: Style.buttonSize.width),
            heightAnchor.constraint(equalToConstant: Style.buttonSize.height)
        ])
    }
}

fileprivate final class InnerButton: SquishyButton {
    private enum Style {
        static let backgroundColor: UIColor = .white
        static let selectedColor: UIColor = .gray
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = Style.backgroundColor
    }

    override func updateLayout(isSelected: Bool) {
        let color = isSelected ? Style.selectedColor : Style.backgroundColor
        backgroundColor = color
    }

    override func layoutSubviews() {
        layer.cornerRadius = bounds.height/2
    }

    func set(state: CameraTakeButtonState){
        setImage(state.icon, for: .normal)
    }
}

fileprivate func shrink(size: CGSize, by diff: CGFloat) -> CGSize {
    let newWidth = size.width - diff * 2
    let newHeight = size.height - diff * 2
    return CGSize(width: newWidth, height: newHeight)
}

extension CameraTakeButtonState {
    var icon: UIImage? {
        switch self {
        case .take:
            return nil
        case .redo:
            let config = UIImage.SymbolConfiguration(pointSize: 30, weight: .regular)
            return UIImage(systemName: "arrow.clockwise", withConfiguration: config)
        }
    }
}
