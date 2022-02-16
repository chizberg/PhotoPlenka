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
        static let multiPhotoReuseID = String(describing: MultiplePhotosAnnotationView.self)
        static let initialYearRange: ClosedRange<Int> = 1826...2000
        static let annotationAnimationDuration: TimeInterval = 0.2
        static let superSmallTransform = CGAffineTransform(scaleX: 0, y: 0)
    }

    private let networkService: NetworkServiceProtocol = NetworkService()
    private lazy var photoDetailsProvider: PhotoDetailsProviderProtocol =
        PhotoDetailsProvider(networkService: networkService)
    private lazy var annotationProvider: AnnotationProviderProtocol =
        AnnotationProvider(networkService: networkService)
    private let map = MapWithObservers()
    private var zoom = Zoom(span: Constants.defaultRegion.span)
    private var yearRange = Constants.initialYearRange
    private lazy var transitionDelegate = BottomSheetTransitionDelegate(bottomSheetFactory: self)
    private lazy var nearbyListController = NearbyListController(
        mapController: self,
        detailsProvider: photoDetailsProvider
    )
    private lazy var bottomNavigation =
        BottomNavigationController(rootViewController: nearbyListController)

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
        map.register(
            MultiplePhotosAnnotationView.self,
            forAnnotationViewWithReuseIdentifier: Constants.multiPhotoReuseID
        )
        map.addObserver(nearbyListController)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        let bottomSheetVC = bottomNavigation
        bottomNavigation.isNavigationBarHidden = true
        bottomSheetVC.modalPresentationStyle = .custom
        bottomSheetVC.transitioningDelegate = transitionDelegate
        present(bottomSheetVC, animated: false)
    }

    override func viewDidLayoutSubviews() {
        map.frame = view.bounds
    }

    override func didReceiveMemoryWarning() {
        ImageFetcher.shared.clear()
    }

    func showSinglePhotoDetails(photo: Photo) {
        let singleController = SinglePhotoController(
            cid: photo.cid,
            detailsProvider: photoDetailsProvider
        )
        self.bottomNavigation.pushViewController(singleController, animated: true)
    }
}

extension MapController: BottomSheetFactory {
    func makePresentationController(
        presentedViewController: UIViewController,
        presenting: UIViewController?
    ) -> UIPresentationController {
        BottomSheetPresentationController(
            fractions: [0.20, 0.50, 0.60, 0.90],
            presentedViewController: presentedViewController,
            presenting: presenting
        )
    }
}

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
    @objc private func loadNewAnnotations() {
        annotationProvider
            .loadNewAnnotations(
                z: z,
                region: map.extendedRegion,
                yearRange: yearRange
            ) { [weak self] result in
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

    @objc private func clearAndLoadNewAnnotations() {
        clearMapAndProvider()
        loadNewAnnotations()
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
        if let photo = view.annotation as? Photo {
            showSinglePhotoDetails(photo: photo)
        }
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let photoCluster = annotation as? MKClusterAnnotation {
            return mapView.dequeueReusableAnnotationView(
                withIdentifier: Constants.multiPhotoReuseID,
                for: photoCluster
            ) as? MultiplePhotosAnnotationView
        }
        if let photoAnnotation = annotation as? Photo {
            return mapView.dequeueReusableAnnotationView(
                withIdentifier: Constants.photoReuseID,
                for: photoAnnotation
            ) as? PhotoAnnotationView
        }
        if let clusterAnnotation = annotation as? Cluster {
            return mapView.dequeueReusableAnnotationView(
                withIdentifier: Constants.clusterReuseID,
                for: clusterAnnotation
            ) as? ClusterAnnotationView
        }
        return nil
    }
<<<<<<< HEAD

    func mapView(_: MKMapView, didAdd views: [MKAnnotationView]) {
=======
    
    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
>>>>>>> 3e666fd (basic annimations)
        showWithAnimation(views)
    }
}

extension MapController: YearSelectorDelegate {
    func rangeDidChange(newRange: ClosedRange<Int>) {
        yearRange = newRange
        NSObject.cancelPreviousPerformRequests(
            withTarget: self,
            selector: #selector(clearAndLoadNewAnnotations),
            object: nil
        )
        self.perform(#selector(clearAndLoadNewAnnotations), with: nil, afterDelay: 0.15)
    }
}

extension MapController: MapPublisher {
    func addObserver(_ observer: MapObserver) {
        map.addObserver(observer)
    }
}

<<<<<<< HEAD
// animating annotations
extension MapController {
    // у меня пока что не получается закинуть анимацию появления в MKMapView override куда-нибудь
    // на тот момент ещё нет view(for: annotation)
=======
//animating annotations
extension MapController {
    //у меня пока что не получается закинуть анимацию появления в MKMapView override куда-нибудь
    //на тот момент ещё нет view(for: annotation)
>>>>>>> 3e666fd (basic annimations)
    private func showWithAnimation(_ views: [MKAnnotationView]) {
        for view in views {
            let initialTransform = view.transform
            view.transform = Constants.superSmallTransform
            UIView.animate(withDuration: Constants.annotationAnimationDuration, animations: {
                view.transform = initialTransform
            })
        }
    }
}
