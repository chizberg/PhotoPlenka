//
//  MapController.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 02.02.2022.
//

import MapKit
import UIKit

final class MapController: UIViewController {
    private enum Constants {
        static let defaultRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 56.329707, longitude: 44.009087),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        static let photoReuseID = String(describing: PhotoAnnotationView.self)
        static let clusterReuseID = String(describing: ClusterAnnotationView.self)
    }

    private let networkService: NetworkServiceProtocol = NetworkService()
    private lazy var annotationProvider: AnnotationProviderProtocol =
        AnnotationProvider(networkService: networkService)
    private let map = MKMapView()
    private var zoom = Zoom(span: Constants.defaultRegion.span)
    private lazy var transitionDelegate = BottomSheetTransitionDelegate(buttomSheetFactory: self)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(map)
        map.setRegion(Constants.defaultRegion, animated: false)
        map.delegate = self
        map.isRotateEnabled = false
        map.register(
            PhotoAnnotationView.self,
            forAnnotationViewWithReuseIdentifier: Constants.photoReuseID
        )
        map.register(
            ClusterAnnotationView.self,
            forAnnotationViewWithReuseIdentifier: Constants.clusterReuseID
        )
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        let bottomSheetVC = DetailAnnotationViewController()
        bottomSheetVC.modalPresentationStyle = .custom
        bottomSheetVC.transitioningDelegate = transitionDelegate
        present(bottomSheetVC, animated: false)
    }

    override func viewDidLayoutSubviews() {
        map.frame = view.bounds
    }
}

extension MapController: BottomSheetFactory {
    func makePresentationController(
        presentedViewController: UIViewController,
        presenting: UIViewController?
    ) -> UIPresentationController {
        BottomSheetPresentationController(
            presentedViewController: presentedViewController,
            presenting: presenting
        )
    }
}

// TODO: Z stuff
extension MapController {
    private func clearMapAndProvider() {
        map.removeAnnotations(map.annotations)
        annotationProvider.clear()
    }

    var z: Int {
        get {
            let oldValue = zoom.z
            zoom.span = map.region.span
            if zoom.z != oldValue { clearMapAndProvider() }
            return zoom.z
        }
        set {
            if newValue != zoom.z { clearMapAndProvider() }
            zoom.z = newValue
        }
    }
}

extension MapController: MKMapViewDelegate {
    @objc func loadNewAnnotations() {
        annotationProvider
            .loadNewAnnotations(z: z, region: map.extendedRegion) { [weak self] result in
                guard let self = self else { return }
                assert(Thread.isMainThread)
                switch result {
                case let .success(newAnnotations):
                    self.map.addAnnotations(newAnnotations)
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
        self.perform(#selector(loadNewAnnotations), with: nil, afterDelay: 0.15)
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let cluster = view as? ClusterAnnotationView {
            if z ==
                16 { z = 19
            } // z = 17,18 показывают одно и то же, поэтому сразу на 19, чтобы иконки не сливались (но в идеале нужно просто нормально обрабатывать слившиеся метки)
            else { z += 1 }
            guard let coordinate = cluster.coordinate else { return }
            let newRegion = MKCoordinateRegion(center: coordinate, span: zoom.span)
            mapView.setRegion(newRegion, animated: true)
        }
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let photoAnnotation = annotation as? Photo {
            guard let photoView = mapView.dequeueReusableAnnotationView(
                withIdentifier: Constants.photoReuseID,
                for: annotation
            ) as? PhotoAnnotationView else { return nil }
            photoView.fillIn(annotation: photoAnnotation)
            return photoView
        }
        if let clusterAnnotation = annotation as? Cluster {
            guard let clusterView = mapView.dequeueReusableAnnotationView(
                withIdentifier: Constants.clusterReuseID,
                for: annotation
            ) as? ClusterAnnotationView else { return nil }
            clusterView.fillIn(annotation: clusterAnnotation)
            return clusterView
        }
        return nil
    }

    // replace icons with dots
//    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
//        let dot = MKAnnotationView()
//        dot.backgroundColor = .blue
//        dot.frame = CGRect(origin: .zero, size: CGSize(width: 4, height: 4))
//        dot.layer.cornerRadius = 2
//        return dot
//    }
}
