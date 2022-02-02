//
//  ViewController.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 02.02.2022.
//

import MapKit
import UIKit

final class ViewController: UIViewController {
    private enum Constants {
        static let defaultRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 56.329707, longitude: 44.009087),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    }

    private let networkService: NetworkServiceProtocol = NetworkService()

    private let map = MKMapView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(map)
        map.setRegion(Constants.defaultRegion, animated: false)
        map.delegate = self
        map.isRotateEnabled = false
        // Do any additional setup after loading the view.
    }

    override func viewDidLayoutSubviews() {
        map.frame = view.bounds
    }
}

// TODO: Z stuff
extension ViewController {
    var z: Int {
        16
    }
}

extension ViewController: MKMapViewDelegate {
    @objc func loadNewAnnotations() {
        networkService.loadByBounds(z: z, region: map.region) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case let .success((photos, clusters)):
                let photoAnnotations = photos.map { Photo(from: $0) }
                self.map.addAnnotations(photoAnnotations)
                let clusterAnnotations = clusters.map { Cluster(from: $0) }
                self.map.addAnnotations(clusterAnnotations)
                print(self.map.annotations.count)
            case let .failure(error):
                print(error.localizedDescription)
            }
        }
    }

    // trying to load it with delay, but it would be better done with operations, i guess
    // still better than nothing
    func mapViewDidChangeVisibleRegion(_: MKMapView) {
        NSObject.cancelPreviousPerformRequests(
            withTarget: self,
            selector: #selector(loadNewAnnotations),
            object: nil
        )
        self.perform(#selector(loadNewAnnotations), with: nil, afterDelay: 0.5)
    }

    func mapView(_: MKMapView, didSelect _: MKAnnotationView) {}

    func mapView(_: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let view = MKAnnotationView()
        if let photoAnnotation = annotation as? Photo {
            view.frame = CGRect(origin: .zero, size: CGSize(width: 10, height: 10))
            view.backgroundColor = UIColor.from(year: photoAnnotation.year)
            view.layer.cornerRadius = 5
            return view
        }
        if let clusterAnnotation = annotation as? Cluster {
            view.frame = CGRect(origin: .zero, size: CGSize(width: 30, height: 30))
            view.backgroundColor = UIColor.from(year: clusterAnnotation.photo.year)
            view.layer.cornerRadius = 15
            return view
        }
        return nil
    }
}
