//
//  MapLinks.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 17.04.2022.
//

import CoreLocation
import UIKit

enum MapApps {
  case yandex
  case doubleGis
  case google
  case apple
}

extension MapApps {
  private var downloadAppLink: URL? {
    switch self {
    case .yandex:
      return URL(string: "https://apps.apple.com/ru/app/id313877526")
    case .doubleGis:
      return URL(string: "https://itunes.apple.com/ru/app/id481627348?mt=8")
    case .google:
      return URL(string: "https://apps.apple.com/ru/app/id585027354")
    case .apple:
      return nil
    }
  }

  private func coordinateLink(latitude: Double, longitude: Double) -> URL? {
    switch self {
    case .yandex:
      return URL(string: "yandexmaps://yandex.ru/maps/?rtext=~\(latitude)%2C\(longitude)")
    case .doubleGis:
      return URL(
        string: "dgis://2gis.ru/routeSearch/rsType/pedestrian/to/\(longitude),\(latitude)"
      )
    case .google:
      return URL(string: "comgooglemaps://?daddr=\(latitude),\(longitude)")
    case .apple:
      return URL(string: "http://maps.apple.com/?daddr=\(latitude),\(longitude)")
    }
  }

  func open(latitude: Double, longitude: Double) {
    guard let coordinateLink = coordinateLink(latitude: latitude, longitude: longitude)
    else { return }
    guard UIApplication.shared.canOpenURL(coordinateLink) else {
      if let appLink = downloadAppLink {
        UIApplication.shared.open(appLink)
      }
      return
    }
    UIApplication.shared.open(coordinateLink)
  }

  func open(point: CLLocationCoordinate2D) {
    open(latitude: point.latitude, longitude: point.longitude)
  }
}
