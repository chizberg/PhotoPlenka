//
//  LocationProvider.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 13.03.2022.
//

import CoreLocation

final class LocationProvider: NSObject {
    private let manager = CLLocationManager()

    func start(_ completion: @escaping () -> Void){
        manager.requestWhenInUseAuthorization()
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = kCLHeadingFilterNone
        manager.startUpdatingLocation()
        manager.delegate = self
        completion()
    }
}

extension LocationProvider: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print(locations[0])
    }
}
