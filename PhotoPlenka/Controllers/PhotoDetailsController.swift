//
//  PhotoDetailsController.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 23.02.2022.
//

import UIKit

final class PhotoDetailsController: UIViewController, ScrollableViewController {
    var header: UIView {
        closeButton
    }

    var scrollView: UIScrollView {
        scroll
    }

    private enum Style {
        static let sideInset: CGFloat = 16
        static let bottomScrollPadding: CGFloat = 50
        static let loadingAnimationDuration: TimeInterval = 0.5
        static let imageAnimationDuration: TimeInterval = 0.3
        static let loadingImageAspectRatio: CGFloat = 21 / 9
        static let closeButtonSize: CGSize = .init(width: 40, height: 40)
        static let controllerCornerRadius: CGFloat = 29
    }

    private let factory = PhotoDetailsFactory()
    private var photoData: DetailedPhoto?
    private var cid: Int
    private let detailsProvider: PhotoDetailsProviderProtocol

    private let likeButton = LikeButton()
    private let shareButton = ActionButton(
        iconSystemName: "square.and.arrow.up",
        title: "Поделиться",
        color: nil
    )
    private let webButton = ActionButton(
        iconSystemName: "globe.europe.africa.fill",
        title: "На сайте",
        color: nil
    )
    private let compareButton = ActionButton(
        iconSystemName: "camera.viewfinder",
        title: "Сравнить",
        color: .systemPurple
    )
    private let mapsButton = ActionButton(
        iconSystemName: "map",
        title: "Маршрут",
        color: .systemGreen
    )

    private lazy var bottomButtonStack = factory
        .stackFromButtons(buttons: [likeButton, shareButton, webButton, compareButton, mapsButton])
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
    private lazy var scroll = factory.makeScrollView()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private lazy var imageView = factory.makeImageView()
    private let imageContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    let backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))

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
        view.clipsToBounds = true
        view.layer.cornerRadius = Style.controllerCornerRadius
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
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
        backgroundView.frame = view.bounds
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
        scroll.addSubview(imageContainer)
        scroll.addSubview(imageView)
        scroll.addSubview(contentStack)
        view.addSubview(scroll)
        view.addSubview(loadingIndicator)
        view.addSubview(closeButton)
        view.insertSubview(backgroundView, at: 0)
    }

    private func activateConstraints() {
        NSLayoutConstraint.activate([
            closeButton.widthAnchor.constraint(equalToConstant: Style.closeButtonSize.width),
            closeButton.heightAnchor.constraint(equalToConstant: Style.closeButtonSize.height),
            closeButton.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -Style.sideInset
            ),
            closeButton.topAnchor.constraint(equalTo: view.topAnchor, constant: Style.sideInset),
        ])

        NSLayoutConstraint.activate([
            scroll.leadingAnchor.constraint(
                equalTo: view.leadingAnchor
            ),
            scroll.trailingAnchor.constraint(
                equalTo: view.trailingAnchor
            ),
            scroll.topAnchor.constraint(equalTo: view.topAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        let topConstraint = imageView.topAnchor.constraint(equalTo: view.topAnchor)
        topConstraint.priority = .defaultHigh

        let heightConstraint = imageView.heightAnchor
            .constraint(greaterThanOrEqualTo: imageContainer.heightAnchor)
        heightConstraint.priority = .required

        let positionConstraint = imageView.topAnchor.constraint(equalTo: imageContainer.topAnchor)
        positionConstraint.priority = .defaultLow

        NSLayoutConstraint.activate([
            topConstraint, heightConstraint, positionConstraint,
            imageView.leadingAnchor.constraint(equalTo: imageContainer.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: imageContainer.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: imageContainer.bottomAnchor),
        ])

        NSLayoutConstraint.activate([
            imageContainer.leadingAnchor.constraint(equalTo: scroll.leadingAnchor),
            imageContainer.trailingAnchor.constraint(equalTo: scroll.trailingAnchor),
            imageContainer.topAnchor.constraint(equalTo: scroll.topAnchor),
            imageContainer.widthAnchor.constraint(equalTo: view.widthAnchor),
        ])

        NSLayoutConstraint.activate([
            contentStack.leadingAnchor.constraint(
                equalTo: scroll.leadingAnchor,
                constant: Style.sideInset
            ),
            contentStack.trailingAnchor.constraint(
                equalTo: scroll.trailingAnchor,
                constant: -Style.sideInset
            ),
            contentStack.topAnchor.constraint(
                equalTo: imageContainer.bottomAnchor,
                constant: Style.sideInset
            ),
            contentStack.bottomAnchor.constraint(
                equalTo: scroll.bottomAnchor,
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
            .fetchHighestQuality(filePath: file, quality: .high) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case let .success(image):
                    self.imageView.image = image
                    self.newAspectRatio(from: image)
                    self.makeImageClickable()
                case let .failure(error):
                    print(error.localizedDescription)
                }
            }
    }

    private func makeImageClickable() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(imageClicked(_:)))
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(tapGesture)
    }

    @objc private func imageClicked(_: UITapGestureRecognizer) {
        guard let image = imageView.image else { return }
        let focusController = PhotoZoomController(image: image)
        focusController.modalTransitionStyle = .coverVertical
        focusController.modalPresentationStyle = .fullScreen
        self.present(focusController, animated: true, completion: nil)
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
        compareButton.addTarget(self, action: #selector(compare), for: .touchUpInside)
        shareButton.addTarget(self, action: #selector(share), for: .touchUpInside)
        webButton.addTarget(self, action: #selector(openWeb), for: .touchUpInside)
        mapsButton.addTarget(self, action: #selector(openMap), for: .touchUpInside)
    }

    private func setLoading(_ isLoading: Bool) {
        isLoading ? loadingIndicator.startAnimating() : loadingIndicator.stopAnimating()
        UIView.animate(withDuration: Style.loadingAnimationDuration) { [unowned self] in
            scroll.isHidden = isLoading
            loadingIndicator.isHidden = !isLoading
        }
    }

    private func fillIn(photo: DetailedPhoto) {
        self.photoData = photo
        fillYear(year1: photo.year, year2: photo.year2)
        titleLabel.text = photo.name
        descriptionLabel.attributedText = photo.description
        authorLabel.text = photo.author
        uploadedByLabel.text = photo.username
        loadImage(file: photo.file)
    }

    private func fillYear(year1: Int, year2: Int) {
        if year1 == year2 {
            yearLabel.text = "\(year1) г."
        } else { yearLabel.text = "\(year1)-\(year2) гг." }
        yearLabel.textColor = UIColor.from(year: year1)
    }

    @objc private func back() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func like() {
        likeButton.isLiked = !likeButton.isLiked
    }

    @objc private func share(){
        guard let image = imageView.image, let photoData = photoData else { return }
        let imagesToShare: [Any] = [image, photoData.shareDescription]
        let shareSheet = UIActivityViewController(activityItems: imagesToShare, applicationActivities: nil)
        shareSheet.popoverPresentationController?.sourceView = shareButton
        present(shareSheet, animated: true, completion: nil)
    }

    @objc private func openWeb(){
        guard let photoData = photoData, let url = photoData.url else { return }
        UIApplication.shared.open(url)
    }

    @objc private func compare() {
        guard let photoData = photoData else { return }
        ImageFetcher.shared.fetchHighestQuality(filePath: photoData.file, quality: .high, completion: { [weak self] result in
            guard let self = self else { return }
            switch result {
            case let .success(image):
                let compareController = CameraCompareController(
                    oldImage: image,
                    year1: photoData.year,
                    year2: self.nowYear()
                )
                compareController.modalTransitionStyle = .coverVertical
                compareController.modalPresentationStyle = .fullScreen
                self.present(compareController, animated: true)
            case let .failure(error):
                print(error.localizedDescription)
            }
        })
    }

    @objc private func openMap(){
        guard let point = photoData?.coordinate else { return }
        let mapSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let yandexMaps = UIAlertAction(title: "Яндекс Карты", style: .default) { _ in
            MapApps.yandex.open(point: point)
        }
        let googleMaps = UIAlertAction(title: "Google Карты", style: .default) { _ in
            MapApps.google.open(point: point)
        }
        let doubleGis = UIAlertAction(title: "2ГИС", style: .default) { _ in
            MapApps.doubleGis.open(point: point)
        }
        let appleMaps = UIAlertAction(title: "Apple Карты", style: .default) { _ in
            MapApps.apple.open(point: point)
        }
        let cancel = UIAlertAction(title: "Отмена", style: .cancel)
        mapSheet.addAction(yandexMaps)
        mapSheet.addAction(googleMaps)
        mapSheet.addAction(doubleGis)
        mapSheet.addAction(appleMaps)
        mapSheet.addAction(cancel)
        present(mapSheet, animated: true)
    }

    private func nowYear() -> Int {
        let now = Date()
        let calendar = Calendar.current
        return calendar.component(.year, from: now)
    }
}
