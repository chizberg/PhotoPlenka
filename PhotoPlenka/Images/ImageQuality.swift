//
//  ImageQuality.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 13.02.2022.
//

import Foundation

enum ImageQuality: Int, CaseIterable {
  // rawValue используется в качестве приоритета
  // выше качество - выше приоритет
  case preview = 1
  case medium
  case high
}

extension ImageQuality {
  var priority: Int { // чтобы в других кусках кода было более понятно
    self.rawValue
  }

  var linkLetter: String { // используется при создании URL
    switch self {
    case .high: return "a"
    case .medium: return "d"
    case .preview: return "s"
    }
  }

  static let maxPriority = ImageQuality.allCases.count
}
