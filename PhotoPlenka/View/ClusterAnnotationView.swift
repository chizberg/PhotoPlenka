//
//  ClusterAnnotationView.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 04.02.2022.
//

import MapKit
import UIKit

final class ClusterAnnotationView: MKAnnotationView {
    private enum Constants {
        static let borderWidth: CGFloat = 3
        static let width: CGFloat = 60
        static let annotationSize: CGSize = .init(width: width, height: width)
        static let radius = width / 2
        static let labelColor: UIColor = .white
        static let labelFont: UIFont = UIFont.systemFont(ofSize: 15, weight: .bold)
        static let labelInsetValue: CGFloat = 3
    }

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.borderWidth = Constants.borderWidth
        imageView.clipsToBounds = true
        return imageView
    }()

    private let countView = UIView()

    private let countLabel: UILabel = {
        let label = UILabel()
        label.textColor = Constants.labelColor
        label.font = Constants.labelFont
        return label
    }()

    var coordinate: CLLocationCoordinate2D?

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        imageView.image = nil
        frame = CGRect(origin: .zero, size: Constants.annotationSize)
        imageView.layer.cornerRadius = Constants.radius
        addSubview(imageView)
        addSubview(countView)
        countView.addSubview(countLabel)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
        conficureCountView()
    }

    func fillIn(annotation: Cluster) {
        setColor(.from(year: annotation.photo.year))
        imageView.loadImage(from: annotation.photo.imageLink(quality: .preview))
        countLabel.text = "\(annotation.count)"
        coordinate = annotation.coordinate
        setNeedsLayout()
    }

    private func setColor(_ color: UIColor) {
        imageView.layer.borderColor = color.cgColor
        imageView.backgroundColor = color
        countView.backgroundColor = color
    }

    private func conficureCountView() {
        let labelSize = countLabel.intrinsicContentSize
        let viewSize = CGSize(
            width: labelSize.width + Constants.labelInsetValue * 2,
            height: labelSize.height + Constants.labelInsetValue * 2
        )
        countView.isHidden = viewSize.width > frame.width
        if countView.isHidden { return }
        let origin = CGPoint(x: bounds.width - viewSize.width, y: bounds.height - viewSize.height)
        countView.frame = CGRect(origin: origin, size: viewSize)
        countLabel.frame = CGRect(
            origin: CGPoint(x: Constants.labelInsetValue, y: Constants.labelInsetValue),
            size: labelSize
        )
        countView.layer.cornerRadius = min(labelSize.height, labelSize.width) / 2
    }
}

// TODO: - replace with image cache class
extension UIImageView {
    func loadImage(from url: URL?) {
        guard let url = url else { return }
        URLSession.shared.dataTask(with: url, completionHandler: { [weak self] data, _, error in
            guard let self = self else { return }
            guard let data = data, error == nil else { return }
            DispatchQueue.main.async {
                assert(Thread.isMainThread)
                self.image = UIImage(data: data)
            }
        }).resume()
    }
}
