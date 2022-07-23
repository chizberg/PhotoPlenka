//
//  NetworkCluster.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 02.02.2022.
//

import Foundation

// называю поля в соответствии с тем, как мы их получаем из API
struct NetworkCluster {
  let p: NetworkPhoto // titlePhoto
  let geo: [Double] // location, has two values: latitude and longitude
  let c: Int // contained images count
}
