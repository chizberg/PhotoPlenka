//
//  PhotoAnnotationView.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 03.02.2022.
//

import MapKit

final class PhotoAnnotationView: MKAnnotationView {
    private enum Constants {
        static let scaleValue: CGFloat = 2
        static let clusteringIdentifier: String = "photoClusteringID"
    }

    lazy var iconLayer = CAShapeLayer()

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        bounds = CGRect(origin: .zero, size: CGSize(width: 10, height: 13))
        backgroundColor = .none
        layer.addSublayer(iconLayer)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForDisplay() {
        super.prepareForDisplay()
        guard let photo = annotation as? Photo else { return }
        setColor(.from(year: photo.year))
        iconLayer.path = iconPath(direction: photo.dir).cgPath
    }

    override var annotation: MKAnnotation? {
        willSet {
            clusteringIdentifier = Constants.clusteringIdentifier
            displayPriority = .required
        }
    }

    private func setColor(_ color: UIColor) {
        iconLayer.fillColor = color.cgColor
    }

    // эта функция берёт bezierPath, при необходимости добавляет направление и применяет transform
    private func iconPath(direction: Direction?) -> UIBezierPath {
        let icon = UIBezierPath()
        icon.append(roundPath)
        if let angle = direction?.angle {
            icon.append(directionPath)
            icon.apply(CGAffineTransform(rotationAngle: angle))
        }
        icon.apply(CGAffineTransform(scaleX: Constants.scaleValue, y: Constants.scaleValue))
        return icon
    }
}

// Эти UIBezierPath я получил из SVG иконки, которая в фигме
// Получил их при помощи программы PaintCode
fileprivate let roundPath: UIBezierPath = {
    let ovalPath = UIBezierPath(ovalIn: CGRect(x: 0, y: 2.71, width: 10, height: 10))
    return ovalPath
}()

fileprivate let directionPath: UIBezierPath = {
    let bezierPath = UIBezierPath()
    bezierPath.move(to: CGPoint(x: 4.13, y: 0.5))
    bezierPath.addCurve(
        to: CGPoint(x: 5.87, y: 0.5),
        controlPoint1: CGPoint(x: 4.52, y: -0.17),
        controlPoint2: CGPoint(x: 5.48, y: -0.17)
    )
    bezierPath.addLine(to: CGPoint(x: 8.46, y: 5))
    bezierPath.addCurve(
        to: CGPoint(x: 7.6, y: 6.5),
        controlPoint1: CGPoint(x: 8.85, y: 5.67),
        controlPoint2: CGPoint(x: 8.37, y: 6.5)
    )
    bezierPath.addLine(to: CGPoint(x: 2.4, y: 6.5))
    bezierPath.addCurve(
        to: CGPoint(x: 1.54, y: 5),
        controlPoint1: CGPoint(x: 1.63, y: 6.5),
        controlPoint2: CGPoint(x: 1.15, y: 5.67)
    )
    bezierPath.addLine(to: CGPoint(x: 4.13, y: 0.5))
    bezierPath.close()
    return bezierPath
}()
