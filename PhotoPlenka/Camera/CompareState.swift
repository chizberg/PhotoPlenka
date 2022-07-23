//
//  CompareState.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 08.04.2022.
//

import UIKit

enum CompareState {
  case sideBySide // старая фото рядом с превью
  case overlay // старая фото поверх превью
  case share // фото сделано, две фотографии рядом
}

extension CompareState {
  var icon: UIImage {
    let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
    switch self {
    case .sideBySide:
      return UIImage(systemName: "rectangle.grid.1x2", withConfiguration: config)!
    case .overlay:
      return UIImage(systemName: "rectangle.on.rectangle", withConfiguration: config)!
    case .share:
      return UIImage(systemName: "square.and.arrow.up", withConfiguration: config)!
    }
  }

  var takeButtonState: CameraTakeButtonState {
    switch self {
    case .sideBySide, .overlay:
      return .take
    case .share:
      return .redo
    }
  }
}
