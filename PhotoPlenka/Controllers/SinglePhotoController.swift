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
        static let closeButtonSize: CGSize = .init(width: 40, height: 40)
    }

    private let factory = SinglePhotoFactory()
    private var photoData: DetailedPhoto?
    private var cid: Int
    private let detailsProvider: PhotoDetailsProviderProtocol

    private let likeButton = LikeButton()
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

    private lazy var bottomButtonStack = factory
        .stackFromButtons(buttons: [likeButton, downloadButton, sourceButton, compareButton])

    private lazy var closeButton = factory.makeCloseButton()
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
    private let imageContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    private lazy var imageAspectRatioConstraint = imageContainer.widthAnchor.constraint(
        equalTo: imageContainer.heightAnchor,
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
        contentStack.addArrangedSubview(details)
        contentStack.addArrangedSubview(bottomButtonStack)
        scrollView.addSubview(imageContainer)
        scrollView.addSubview(imageView)
        scrollView.addSubview(contentStack)
        view.addSubview(scrollView)
        view.addSubview(loadingIndicator)
        view.addSubview(closeButton)
    }

    private func activateConstraints() {
        NSLayoutConstraint.activate([
            closeButton.widthAnchor.constraint(equalToConstant: Style.closeButtonSize.width),
            closeButton.heightAnchor.constraint(equalToConstant: Style.closeButtonSize.height),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Style.sideInset),
            closeButton.topAnchor.constraint(equalTo: view.topAnchor, constant: Style.sideInset)
        ])

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor
            ),
            scrollView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor
            ),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        let topConstraint = imageView.topAnchor.constraint(equalTo: view.topAnchor)
        topConstraint.priority = .defaultHigh

        let heightConstraint = imageView.heightAnchor.constraint(greaterThanOrEqualTo: imageContainer.heightAnchor)
        heightConstraint.priority = .required

        let positionConstraint = imageView.topAnchor.constraint(equalTo: imageContainer.topAnchor)
        positionConstraint.priority = .defaultLow

        NSLayoutConstraint.activate([
            topConstraint, heightConstraint, positionConstraint,
            imageView.leadingAnchor.constraint(equalTo: imageContainer.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: imageContainer.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: imageContainer.bottomAnchor)
        ])

        NSLayoutConstraint.activate([
            imageContainer.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            imageContainer.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            imageContainer.topAnchor.constraint(equalTo: scrollView.topAnchor),
            imageContainer.widthAnchor.constraint(equalTo: view.widthAnchor)
        ])

        NSLayoutConstraint.activate([
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: Style.sideInset),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -Style.sideInset),
            contentStack.topAnchor.constraint(equalTo: imageContainer.bottomAnchor, constant: Style.sideInset),
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
        imageAspectRatioConstraint = imageContainer.widthAnchor.constraint(
            equalTo: imageContainer.heightAnchor,
            multiplier: aspectRatio
        )
        imageAspectRatioConstraint.isActive = true
        UIView.animate(withDuration: Style.imageAnimationDuration) {
            self.view.layoutIfNeeded()
        }
    }

    private func addButtonTargets() {
        closeButton.addTarget(self, action: #selector(back), for: .touchUpInside)
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
