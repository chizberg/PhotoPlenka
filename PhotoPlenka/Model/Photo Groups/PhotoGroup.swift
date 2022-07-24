//
//  LocalCluster.swift
//  PhotoPlenka
//
//  Created by Alexey Sherstnev on 24.07.2022.
//

import MapKit

// Basically it's a cluster made locally
// But calling it a cluster could be confusing
// So I'll stick with PhotoGroup
final class PhotoGroup: NSObject, MKAnnotation {
  var coordinate: CLLocationCoordinate2D
  var photos: [Photo]

  init(coordinate: CLLocationCoordinate2D) {
    self.coordinate = coordinate
    self.photos = []
  }
}

extension PhotoGroup {
  var count: Int {
    photos.count
  }

  func append(_ photo: Photo) {
    photos.append(photo)
  }
}
