//
//  PhotoAnnotationView.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 03.02.2022.
//

import MapKit

final class PhotoAnnotationView: MKAnnotationView {
    lazy var roundLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.path = roundPath.cgPath
        return layer
    }()

    lazy var directionLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.path = directionPath.cgPath
        return layer
    }()

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = .none
        self.frame = CGRect(origin: .zero, size: CGSize(width: 10, height: 13))
        self.layer.addSublayer(roundLayer)
        self.layer.addSublayer(directionLayer)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func fillIn(annotation: Photo?) {
        guard let annotation = annotation else { return }

        let scale = CGAffineTransform(scaleX: 2, y: 2)
        setColor(.from(year: annotation.year))
        if let angle = annotation.dir?.angle {
            let rotate = CGAffineTransform(rotationAngle: angle)
            transform = rotate.concatenating(scale)
            directionLayer.isHidden = false
        } else {
            transform = scale
            directionLayer.isHidden = true
        }
    }

    private func setColor(_ color: UIColor) {
        roundLayer.fillColor = color.cgColor
        directionLayer.fillColor = color.cgColor
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
