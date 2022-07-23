//
//  Cluster.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 02.02.2022.
//

import MapKit

final class Cluster: NSObject, MKAnnotation {
  var coordinate: CLLocationCoordinate2D
  let photo: Photo
  let count: Int

  init(from nc: NetworkCluster) {
    coordinate = CLLocationCoordinate2D(latitude: nc.geo[0], longitude: nc.geo[1])
    photo = Photo(from: nc.p)
    count = nc.c
  }
}

extension Cluster {
  override var hash: Int {
    photo.cid
  }

  override func isEqual(_ object: Any?) -> Bool {
    if let other = object as? Cluster {
      return photo.cid == other.photo.cid && count == other.count && coordinate == other
        .coordinate
    }
    return false
  }
}

extension CLLocationCoordinate2D: Equatable {
  public static func ==(lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
    lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
  }
}
