//
//  PhotoFocusController.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 12.03.2022.
//

import UIKit

final class PhotoZoomController: UIViewController {
    private enum Style {
        static let backgroundColor: UIColor = .black
        static let buttonColor: UIColor = .white
        static let sideInset: CGFloat = 16
        static let buttonSize: CGSize = .init(width: 40, height: 40)
        static let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
        static let closeIcon: UIImage = .init(systemName: "xmark", withConfiguration: config)!
<<<<<<< HEAD
        static let shareIcon: UIImage = .init(
            systemName: "square.and.arrow.up",
            withConfiguration: config
        )!
=======
        static let shareIcon: UIImage = .init(systemName: "square.and.arrow.up", withConfiguration: config)!
>>>>>>> 266f05e (focus screen)
        static let animationDuration: TimeInterval = 0.25
    }

    private let image: UIImage

    private let closeButton = RoundButton(type: .close)
    private let shareButton = RoundButton(type: .share)
<<<<<<< HEAD
    private let imageView: ZoomableImageView = .init()

    init(image: UIImage) {
=======
    private let imageView: ZoomableImageView = ZoomableImageView()

    init(image: UIImage){
>>>>>>> 266f05e (focus screen)
        self.image = image
        super.init(nibName: nil, bundle: nil)
    }

<<<<<<< HEAD
    @available(*, unavailable)
    required init?(coder _: NSCoder) {
=======
    required init?(coder: NSCoder) {
>>>>>>> 266f05e (focus screen)
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Style.backgroundColor
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = image
        view.addSubview(imageView)
        view.addSubview(closeButton)
        view.addSubview(shareButton)
        applyConstraints()

        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        shareButton.addTarget(self, action: #selector(share), for: .touchUpInside)

        let tap = UITapGestureRecognizer(target: self, action: #selector(changeControls))
        imageView.addGestureRecognizer(tap)
    }

    override func viewDidLayoutSubviews() {
        imageView.frame = view.bounds
<<<<<<< HEAD
<<<<<<< HEAD
        imageView.resetScale()
    }

    override var prefersStatusBarHidden: Bool {
        true
    }

    private func applyConstraints() {
        NSLayoutConstraint.activate([
            closeButton.widthAnchor.constraint(equalToConstant: Style.buttonSize.width),
            closeButton.heightAnchor.constraint(equalToConstant: Style.buttonSize.height),
            closeButton.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor,
                constant: Style.sideInset
            ),
            closeButton.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                constant: -Style.sideInset
            ),
=======
=======
        imageView.resetScale()
>>>>>>> 27f8168 (photoZoomFix)
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    private func applyConstraints(){
        NSLayoutConstraint.activate([
            closeButton.widthAnchor.constraint(equalToConstant: Style.buttonSize.width),
            closeButton.heightAnchor.constraint(equalToConstant: Style.buttonSize.height),
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Style.sideInset),
            closeButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -Style.sideInset)
>>>>>>> 266f05e (focus screen)
        ])

        NSLayoutConstraint.activate([
            shareButton.widthAnchor.constraint(equalToConstant: Style.buttonSize.width),
            shareButton.heightAnchor.constraint(equalToConstant: Style.buttonSize.height),
<<<<<<< HEAD
            shareButton.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor,
                constant: Style.sideInset
            ),
            shareButton.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                constant: Style.sideInset
            ),
        ])
    }

    @objc private func close() {
        self.dismiss(animated: true, completion: nil)
    }

    @objc private func share() {
        let imagesToShare = [image]
        let shareSheet = UIActivityViewController(
            activityItems: imagesToShare,
            applicationActivities: nil
        )
=======
            shareButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Style.sideInset),
            shareButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: Style.sideInset)
        ])
    }

    @objc private func close(){
        self.dismiss(animated: true, completion: nil)
    }

    @objc private func share(){
        let imagesToShare = [image]
        let shareSheet = UIActivityViewController(activityItems: imagesToShare, applicationActivities: nil)
>>>>>>> 266f05e (focus screen)
        shareSheet.popoverPresentationController?.sourceView = shareButton
        present(shareSheet, animated: true, completion: nil)
    }

<<<<<<< HEAD
    @objc private func changeControls() {
=======
    @objc private func changeControls(){
>>>>>>> 266f05e (focus screen)
        let isHidden = shareButton.isHidden
        setControlState(isHidden: !isHidden, animated: true)
    }

<<<<<<< HEAD
    func setControlState(isHidden: Bool, animated: Bool) {
=======
    func setControlState(isHidden: Bool, animated: Bool){
>>>>>>> 266f05e (focus screen)
        guard animated else {
            shareButton.isHidden = isHidden
            closeButton.isHidden = isHidden
            return
        }
        switch isHidden {
        case true:
            shareButton.alpha = 1
            closeButton.alpha = 1
            UIView.animate(withDuration: Style.animationDuration, animations: { [unowned self] in
                shareButton.alpha = 0
                closeButton.alpha = 0
            }, completion: { [unowned self] _ in
                shareButton.isHidden = true
                closeButton.isHidden = true
            })
        case false:
            shareButton.alpha = 0
            closeButton.alpha = 0
            shareButton.isHidden = false
            closeButton.isHidden = false
            UIView.animate(withDuration: Style.animationDuration) { [unowned self] in
                shareButton.alpha = 1
                closeButton.alpha = 1
            }
        }
    }
}
