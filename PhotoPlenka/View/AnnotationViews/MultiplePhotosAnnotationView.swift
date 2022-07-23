//
//  MultiplePhotosAnnotationView.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 07.02.2022.
//

import MapKit

final class MultiplePhotosAnnotationView: MKAnnotationView {
  private enum Style {
    static let font: UIFont = .systemFont(ofSize: 17, weight: .bold)
    static let labelColor: UIColor = .white
    static let horizontalPaddingValue: CGFloat = 7
    static let verticalPaddingValue: CGFloat = 5
    static let relativeCornerRadius: CGFloat = 0.5
  }

  private let label = UILabel()

  override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
    super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
    label.textAlignment = .center
    label.font = Style.font
    label.textColor = Style.labelColor
    addSubview(label)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    let labelSize = label.intrinsicContentSize
    bounds = CGRect(
      origin: .zero, size: CGSize(
        width: labelSize.width + Style.horizontalPaddingValue * 2,
        height: labelSize.height + Style.verticalPaddingValue * 2
      )
    )
    label.frame = CGRect(
      origin: CGPoint(x: Style.horizontalPaddingValue, y: Style.verticalPaddingValue),
      size: labelSize
    )
    layer.cornerRadius = min(bounds.width, bounds.height) * Style.relativeCornerRadius
  }

  override func prepareForDisplay() {
    super.prepareForDisplay()
    guard let cluster = annotation as? MKClusterAnnotation else { return }
    guard let photos = cluster.memberAnnotations as? [Photo], photos.count > 0 else { return }
    label.text = "\(photos.count)"
    backgroundColor = .from(year: photos[0].year)
    setNeedsLayout()
  }
}
