//
//  NetworkPhoto.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 02.02.2022.
//

import Foundation

// называю поля в соответствии с тем, как мы их получаем из API
struct NetworkPhoto {
  let cid: Int // unique photo id
  let file: String // local path to image
  let title: String
  let dir: String? // direction
  let geo: [Double] // location, has two values: latitude and longitude
  let year: Int // lower time boundary
  let year2: Int // upper time boundary
}
