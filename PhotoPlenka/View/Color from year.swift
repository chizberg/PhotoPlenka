//
//  Color from year.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 02.02.2022.
//

import UIKit

extension UIColor {
    static func from(year: Int) -> UIColor {
        let doubleYear = Double(year)
        guard doubleYear >= Constants.lowerBoundYear,
              doubleYear <= Constants.upperBoundYear else { return .systemBackground }
        let percent = percentage(
            upperBound: Constants.upperBoundYear,
            lowerBound: Constants.lowerBoundYear,
            value: doubleYear
        )
        if let color = Constants.gradientColors[percent] { return color }
        let keys = Constants.gradientColors.keys.sorted()
        let closestBigger = keys.firstIndex(where: { $0 > percent })!
        let closestSmaller = closestBigger - 1
        let (leftKey, rightKey) = (keys[closestBigger], keys[closestSmaller])
        return linear(
            lhs: Constants.gradientColors[leftKey],
            rhs: Constants.gradientColors[rightKey],
            percent: percent
        )
    }
}

fileprivate enum Constants {
    static let lowerBoundYear: Double = 1826
    static let upperBoundYear: Double = 2000
    // градиент и его значения взял из CSS на pastvu.com
    static let gradientColors: [Double: UIColor] = [
        0: UIColor(red: 0, green: 0, blue: 102 / 255.0, alpha: 1),
        30: UIColor(red: 0, green: 0, blue: 171 / 255.0, alpha: 1),
        36: UIColor(red: 57 / 255.0, green: 0, blue: 171 / 255.0, alpha: 1),
        42: UIColor(red: 114 / 255.0, green: 0, blue: 171 / 255.0, alpha: 1),
        48: UIColor(red: 171 / 255.0, green: 0, blue: 171 / 255.0, alpha: 1),
        53: UIColor(red: 171 / 255.0, green: 0, blue: 114 / 255.0, alpha: 1),
        59: UIColor(red: 171 / 255.0, green: 0, blue: 57 / 255.0, alpha: 1),
        65: UIColor(red: 171 / 255.0, green: 0, blue: 0, alpha: 1),
        71: UIColor(red: 171 / 255.0, green: 57 / 255.0, blue: 0, alpha: 1),
        76: UIColor(red: 171 / 255.0, green: 114 / 255.0, blue: 0, alpha: 1),
        82: UIColor(red: 171 / 255.0, green: 171 / 255.0, blue: 0, alpha: 1),
        88: UIColor(red: 114 / 255.0, green: 171 / 255.0, blue: 0, alpha: 1),
        94: UIColor(red: 57 / 255.0, green: 171 / 255.0, blue: 0, alpha: 1),
        100: UIColor(red: 0, green: 171 / 255.0, blue: 0, alpha: 1),
    ]
}

fileprivate func linear(
    x1: Double = 0,
    y1: Double,
    x2: Double = 100,
    y2: Double,
    x: Double
) -> Double {
    y2 + (y1 - y2) / (x1 - x2) * (x - x2)
}

fileprivate func percentage(
    upperBound upB: Double,
    lowerBound lowB: Double,
    value: Double
) -> Double {
    (value - lowB) / (upB - lowB) * 100
}

fileprivate func linear(lhs: UIColor?, rhs: UIColor?, percent: Double) -> UIColor {
    guard let lhs = lhs, let rhs = rhs else { return .systemBackground }
    var lhsRed: CGFloat = 0, lhsGreen: CGFloat = 0, lhsBlue: CGFloat = 0, lhsAlpha: CGFloat = 0,
        rhsRed: CGFloat = 0, rhsGreen: CGFloat = 0, rhsBlue: CGFloat = 0, rhsAlpha: CGFloat = 0
    lhs.getRed(&lhsRed, green: &lhsGreen, blue: &lhsBlue, alpha: &lhsAlpha)
    rhs.getRed(&rhsRed, green: &rhsGreen, blue: &rhsBlue, alpha: &rhsAlpha)
    return UIColor(
        red: linear(y1: lhsRed, y2: rhsRed, x: percent),
        green: linear(y1: lhsGreen, y2: rhsGreen, x: percent),
        blue: linear(y1: lhsBlue, y2: rhsBlue, x: percent),
        alpha: 1
    )
}
