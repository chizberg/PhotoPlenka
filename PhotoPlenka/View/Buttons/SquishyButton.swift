//
//  SquishyButton.swift
//  SquishyButton
//
//  Created by Алексей Шерстнёв on 19.02.2022.
//

import UIKit

internal class SquishyButton: UIButton {
    private enum Style {
        static let labelFont: UIFont = UIFont.systemFont(ofSize: 17, weight: .regular)
        static let cornerRadius: CGFloat = 13
        static let padding: CGFloat = 10
        static let spacing: CGFloat = 5
        static let activatedLabelColor: UIColor = .systemBackground
        static let stockActivatedBackgroundColor: UIColor = .secondarySystemBackground
        static let animationTransform = CGAffineTransform(scaleX: 0.9, y: 0.9)
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
    let animator = UIViewPropertyAnimator()
    
    convenience init(iconSystemName: String, title: String, color: UIColor?) {
        self.init(icon: UIImage(systemName: iconSystemName)!, title: title, color: color)
    }
    
    init(icon: UIImage, title: String, color: UIColor?){
        self.accentColor = color
        super.init(frame: .zero)
        
        label.text = title
        iconView.image = icon
        
        backgroundColor = Style.backgroundColor
        updateColors(isSelected: false)
        layer.cornerRadius = Style.cornerRadius
        
        stack.addArrangedSubview(iconView)
        stack.addArrangedSubview(label)
        addSubview(stack)
        applyConstraints()
        activateAnimation()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateContent(newIcon: UIImage? = nil, newTitle: String? = nil, newColor: UIColor? = nil){
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
    
    private func applyConstraints(){
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Style.padding),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Style.padding),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: Style.padding),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Style.padding)
        ])
        
        NSLayoutConstraint.activate([
            iconView.heightAnchor.constraint(equalTo: stack.heightAnchor)
        ])
    }
    
    private func activateAnimation(){
        addTarget(self, action: #selector(touchDown), for: .touchDown)
        addTarget(self, action: #selector(touchUp), for: .touchUpInside)
        addTarget(self, action: #selector(touchUp), for: .touchUpOutside)
    }
    
    private func updateColors(isSelected: Bool){
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
    
    @objc func touchDown(){
        if animator.isRunning {animator.stopAnimation(true)}
        animator.addAnimations { [weak self] in
            guard let self = self else { return }
            self.transform = Style.animationTransform
            self.updateColors(isSelected: true)
        }
        animator.startAnimation()
    }
    
    @objc func touchUp(){
        if animator.isRunning {animator.stopAnimation(true)}
        animator.addAnimations { [weak self] in
            guard let self = self else { return }
            self.transform = .identity
            self.updateColors(isSelected: false)
        }
        animator.startAnimation()
    }
}
