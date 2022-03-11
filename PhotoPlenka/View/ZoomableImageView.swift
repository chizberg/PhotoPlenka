//
//  ZoomableImageView.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 12.03.2022.
//

import UIKit

final class ZoomableImageView: UIScrollView {
    private enum Constants {
        static let minZoom: CGFloat = 1
        static let maxZoom: CGFloat = 3
    }

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        addSubview(imageView)
        //сейчас проблема в том, что imageView растягивается на размер всего scrollView, и поэтому можно увеличиваться на пустые области
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalTo: widthAnchor),
            imageView.heightAnchor.constraint(equalTo: heightAnchor),
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        minimumZoomScale = Constants.minZoom
        maximumZoomScale = Constants.maxZoom
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        delegate = self

        configureDoubleTap()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var image: UIImage? {
        get { imageView.image }
        set {
            imageView.image = newValue
        }
    }

    private func configureDoubleTap(){
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTap))
        doubleTap.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTap)
    }
}

extension ZoomableImageView: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }

    @objc private func doubleTap(){
        guard zoomScale == 1 else {
            setZoomScale(1, animated: true)
            return
        }
        setZoomScale(2, animated: true)
    }
}
