//
//  MapObserver.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 14.02.2022.
//

import MapKit

@objc protocol MapObserver: AnyObject {
  func annotationsDidChange(annotations: [MKAnnotation], visible: [MKAnnotation])
}

protocol MapPublisher {
  func addObserver(_ observer: MapObserver)
}
