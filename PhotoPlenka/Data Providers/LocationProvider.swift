//
//  LocationProvider.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 13.03.2022.
//

import CoreLocation

protocol LocationObserverDelegate: AnyObject {
  func didUpdateLocation(location: CLLocation)
  func didFail()
}

final class LocationProvider: NSObject {
  private let manager = CLLocationManager()
  weak var delegate: LocationObserverDelegate?

  func start() {
    manager.requestWhenInUseAuthorization()
    manager.desiredAccuracy = kCLLocationAccuracyBest
    manager.distanceFilter = kCLHeadingFilterNone
    manager.startUpdatingLocation()
    manager.delegate = self
  }
}

extension LocationProvider: CLLocationManagerDelegate {
  func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    delegate?.didUpdateLocation(location: locations[0])
  }

  func locationManager(_: CLLocationManager, didFailWithError _: Error) {
    delegate?.didFail()
  }
}
