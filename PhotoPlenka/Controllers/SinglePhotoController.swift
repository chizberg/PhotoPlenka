//
//  SinglePhotoController.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 23.02.2022.
//

import UIKit

final class SinglePhotoController: UIViewController {
    private enum Style {
        static let sideInset: CGFloat = 16
        static let bottomScrollPadding: CGFloat = 50
        static let loadingAnimationDuration: TimeInterval = 0.5
        static let imageAnimationDuration: TimeInterval = 0.3
        static let loadingImageAspectRatio: CGFloat = 21 / 9
    }

    private let factory = SinglePhotoFactory()
    private var photoData: DetailedPhoto?
    private var cid: Int
    private let detailsProvider: PhotoDetailsProviderProtocol

    private let likeButton = LikeButton()
    private let backButton = ActionButton(
        iconSystemName: "chevron.left",
        title: "Назад",
        color: .link
    )
    private let downloadButton = ActionButton(
        iconSystemName: "arrow.down.to.line",
        title: "Загрузить",
        color: nil
    )
    private let sourceButton = ActionButton(
        iconSystemName: "globe.europe.africa.fill",
        title: "Источник",
        color: nil
    )
    private let compareButton = ActionButton(
        iconSystemName: "camera.viewfinder",
        title: "Сравнить",
        color: .systemPurple
    )
    private lazy var topButtonStack = factory.stackFromButtons(buttons: [backButton, likeButton])
    private lazy var bottomButtonStack = factory
        .stackFromButtons(buttons: [downloadButton, sourceButton, compareButton])

    private lazy var titleLabel = factory.makeLabel(fontType: .titleLabel)
    private lazy var yearLabel = factory.makeLabel(fontType: .yearLabel)
    private lazy var descriptionLabel = factory.makeLabel(fontType: .description)
    private lazy var authorStack = factory.makePropertyStack(type: .author)
    private lazy var uploadedByStack = factory.makePropertyStack(type: .uploadedBy)
    private lazy var authorLabel = factory.makeLabel(fontType: .propertyLabel)
    private lazy var uploadedByLabel = factory.makeLabel(fontType: .propertyLabel)
    private lazy var properties = factory.makeHorizontalPropertiesStack()
    private lazy var details = factory.makeDetailsStack()
    private lazy var contentStack = factory.makeContentStack()
    private lazy var scrollView = factory.makeScrollView()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private lazy var imageView = factory.makeImageView()
    private lazy var imageAspectRatioConstraint = imageView.widthAnchor.constraint(
        equalTo: imageView.heightAnchor,
        multiplier: Style.loadingImageAspectRatio
    )

    init(cid: Int, detailsProvider: PhotoDetailsProviderProtocol) {
        self.cid = cid
        self.detailsProvider = detailsProvider
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = nil
        setLoading(true)
        addSubviews()
        activateConstraints()
        addButtonTargets()
        detailsProvider.loadDetails(cid: cid) { result in
            switch result {
            case let .success(photo):
                self.fillIn(photo: photo)
                self.setLoading(false)
            case let .failure(error):
                print(error.localizedDescription)
            }
        }
    }

    override func viewDidLayoutSubviews() {
        loadingIndicator.center.x = view.bounds.width / 2
        loadingIndicator.center.y = view.bounds.height / 2
    }

    private func addSubviews() {
        details.addArrangedSubview(titleLabel)
        details.addArrangedSubview(yearLabel)
        details.addArrangedSubview(descriptionLabel)
        authorStack.addArrangedSubview(authorLabel)
        uploadedByStack.addArrangedSubview(uploadedByLabel)
        properties.addArrangedSubview(uploadedByStack)
        if photoData?.author != nil { properties.addArrangedSubview(authorStack) }
        details.addArrangedSubview(properties)
        contentStack.addArrangedSubview(topButtonStack)
        contentStack.addArrangedSubview(imageView)
        contentStack.addArrangedSubview(details)
        contentStack.addArrangedSubview(bottomButtonStack)
        scrollView.addSubview(contentStack)
        view.addSubview(scrollView)
        view.addSubview(loadingIndicator)
    }

    private func activateConstraints() {
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: Style.sideInset
            ),
            scrollView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -Style.sideInset
            ),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: Style.sideInset),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        NSLayoutConstraint.activate([
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentStack.bottomAnchor.constraint(
                equalTo: scrollView.bottomAnchor,
                constant: -Style.bottomScrollPadding
            ),
            contentStack.widthAnchor.constraint(
                equalTo: view.widthAnchor,
                constant: -Style.sideInset * 2
            ),
        ])

        imageAspectRatioConstraint.isActive = true
    }

    private func loadImage(file: String) {
        ImageFetcher.shared
            .fetchHighestQuality(filePath: file, quality: .medium) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case let .success(image):
                    self.imageView.image = image
                    self.newAspectRatio(from: image)
                case let .failure(error):
                    print(error.localizedDescription)
                }
            }
    }

    private func newAspectRatio(from image: UIImage) {
        let aspectRatio = image.size.width / image.size.height
        imageAspectRatioConstraint.isActive = false
        imageAspectRatioConstraint = imageView.widthAnchor.constraint(
            equalTo: imageView.heightAnchor,
            multiplier: aspectRatio
        )
        imageAspectRatioConstraint.isActive = true
        UIView.animate(withDuration: Style.imageAnimationDuration) {
            self.view.layoutIfNeeded()
        }
    }

    private func addButtonTargets() {
        backButton.addTarget(self, action: #selector(back), for: .touchUpInside)
        likeButton.addTarget(self, action: #selector(like), for: .touchUpInside)
    }

    private func setLoading(_ isLoading: Bool) {
        isLoading ? loadingIndicator.startAnimating() : loadingIndicator.stopAnimating()
        UIView.animate(withDuration: Style.loadingAnimationDuration) { [unowned self] in
            scrollView.isHidden = isLoading
            loadingIndicator.isHidden = !isLoading
        }
    }

    private func fillIn(photo: DetailedPhoto) {
        self.photoData = photo
        yearLabel.textColor = UIColor.from(year: photo.year)
        titleLabel.text = photo.name
        yearLabel.text = "\(photo.year)"
        descriptionLabel.attributedText = photo.description
        authorLabel.text = photo.author
        uploadedByLabel.text = photo.username
        loadImage(file: photo.file)
    }

    @objc private func back() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func like() {
        likeButton.isLiked = !likeButton.isLiked
    }
}
