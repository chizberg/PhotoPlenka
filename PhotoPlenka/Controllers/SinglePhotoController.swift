//
//  SinglePhotoController.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 23.02.2022.
//

import UIKit

final class SinglePhotoController: UIViewController {
    private let factory = SinglePhotoFactory()
    
    private var photo: DetailedPhoto
    
    private let downloadButton = SquishyButton(iconSystemName: "arrow.down.to.line", title: "Загрузить", color: nil)
    private let compareButton = SquishyButton(iconSystemName: "camera.viewfinder", title: "Сравнить", color: .systemBlue)
    private let likeButton = LikeButton()
    private let sourceButton = SquishyButton(iconSystemName: "globe.europe.africa.fill", title: "Источник", color: nil)
    private let oneMore = SquishyButton(iconSystemName: "ellipsis", title: "Ещё кнопка", color: .systemGreen)
    private lazy var buttonsStack = factory.stackFromButtons(buttons: [downloadButton, sourceButton, likeButton, compareButton, oneMore])
    
    private lazy var titleLabel = factory.makeLabel(fontType: .titleLabel)
    private lazy var yearLabel = factory.makeLabel(fontType: .yearLabel)
    private lazy var descriptionLabel = factory.makeLabel(fontType: .description)
    private lazy var authorStack = factory.makePropertyStack(type: .author)
    private lazy var uploadedByStack = factory.makePropertyStack(type: .uploadedBy)
    private lazy var authorLabel = factory.makeLabel(fontType: .propertyLabel)
    private lazy var uploadedByLabel = factory.makeLabel(fontType: .propertyLabel)
    private lazy var properties = factory.makeHorizontalPropertiesStack()
    private lazy var details = factory.makeDetailsStack()
    
    private let contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.spacing = 10
        stack.alignment = .fill
        stack.distribution = .equalSpacing
        return stack
    }()
    
    init(photo: DetailedPhoto){
        self.photo = photo
        super.init(nibName: nil, bundle: nil)
        fillIn()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fillIn()
        addSubviews()
        
        NSLayoutConstraint.activate([
            contentStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            contentStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 50)
        ])
        view.backgroundColor = nil
        view.clipsToBounds = true
        view.layer.cornerRadius = 30
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        likeButton.addTarget(self, action: #selector(like), for: .touchUpInside)
    }
    
    private func addSubviews(){
        details.addArrangedSubview(titleLabel)
        details.addArrangedSubview(yearLabel)
        details.addArrangedSubview(descriptionLabel)
        authorStack.addArrangedSubview(authorLabel)
        uploadedByStack.addArrangedSubview(uploadedByLabel)
        properties.addArrangedSubview(uploadedByStack)
        if photo.author != nil {properties.addArrangedSubview(authorStack)}
        details.addArrangedSubview(properties)
        contentStack.addArrangedSubview(details)
        contentStack.addArrangedSubview(buttonsStack)
        view.addSubview(contentStack)
    }
    
    private func fillIn(){
        yearLabel.textColor = UIColor.from(year: photo.year)
        titleLabel.text = photo.name
        yearLabel.text = "\(photo.year)"
        descriptionLabel.attributedText = photo.description
        authorLabel.text = photo.author
        uploadedByLabel.text = photo.username
    }
    
    @objc private func like(){
        likeButton.isLiked = !likeButton.isLiked
    }
}
