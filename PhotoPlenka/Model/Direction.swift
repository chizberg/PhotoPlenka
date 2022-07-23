//
//  Direction.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 02.02.2022.
//

import UIKit

// скорее всего, значений больше
// TODO: Найти все возможные значения
enum Direction: String {
  case n
  case e
  case s
  case w
  case ne
  case nw
  case se
  case sw

  case aero
}

extension Direction {
  var angle: CGFloat? {
    switch self {
    case .n: return 0
    case .e: return .pi / 2
    case .s: return .pi
    case .w: return -.pi / 2
    case .ne: return .pi / 4
    case .nw: return -.pi / 4
    case .se: return .pi / 4 * 3
    case .sw: return -.pi / 4 * 3
    case .aero: return nil
    }
  }
}
