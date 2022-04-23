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
        static let selectedTransform = CGAffineTransform(scaleX: 2, y: 2)
        static let biggestTransfrorm = CGAffineTransform(scaleX: 3, y: 3)

        static let sideInset: CGFloat = 16
        static let buttonSize: CGSize = .init(width: 40, height: 40)
        static let mapDelay: Double = 0.15
    }

    //data
    private let networkService: NetworkServiceProtocol = NetworkService()
    private lazy var photoDetailsProvider: PhotoDetailsProviderProtocol =
        PhotoDetailsProvider(networkService: networkService)
    private lazy var annotationProvider: AnnotationProviderProtocol =
        AnnotationProvider(networkService: networkService)
    private let locationProvider = LocationProvider()
    private var timer = Timer() // is used for request cancellation

    //views
    private let map = MapWithObservers()
    private weak var bottomSheetDelegate: BottomSheetDelegate?
    private let locationButton: RoundButton = {
        let button = RoundButton(type: .location)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    private let favouritesButton: RoundButton = {
        let button = RoundButton(type: .favourites)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    //bottom stuff
    private lazy var transitionDelegate = BottomSheetTransitionDelegate(bottomSheetFactory: self)
    private lazy var nearbyListController = NearbyListController(
        mapController: self,
        detailsProvider: photoDetailsProvider
    )
    private lazy var bottomNavigation =
        BottomNavigationController(rootViewController: nearbyListController)


    //other
    private var zoom = Zoom(span: Constants.defaultRegion.span)
    private var yearRange = Constants.initialYearRange

    //мы получаем геопозицию не сразу, а через LocationProviderDelegate
    //но в delegate есть только locationDidChange, а нужно центрировать геопозицию только на запуске
    //поэтому делаю флажок, который при инициализации = true, а при центрировании или ошибке получения локации становится false
    //если от true - то при каждом изменении локации будет центрировать локацию
    private var waitingForLocation = true

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(map)
        view.addSubview(locationButton)
        view.addSubview(favouritesButton)
        configureButtons()
        map.setRegion(Constants.defaultRegion, animated: false)
        map.delegate = self
        map.isRotateEnabled = false
        map.showsUserLocation = true
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
        locationProvider.start()
        locationProvider.delegate = self

        bottomNavigation.addObserver(self)
        bottomNavigation.isNavigationBarHidden = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let bottomSheetVC = bottomNavigation
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
}

//MARK: - free funcs
extension MapController {
    private func clearMapAndProvider() {
        let annotationsToRemove = map.annotations.filter {!($0 is MKUserLocation)}
        map.removeAnnotations(annotationsToRemove)
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

    func centerUserLocation(animated: Bool){
        guard let coordinate = map.userLocation.location?.coordinate else { return }
        var region = map.region
        region.center = coordinate
        map.setRegion(region, animated: animated)
    }
}

//MARK: - view config funcs
extension MapController {
    func configureButtons(){
        //location button
        NSLayoutConstraint.activate([
            locationButton.heightAnchor.constraint(equalToConstant: Constants.buttonSize.height),
            locationButton.widthAnchor.constraint(equalToConstant: Constants.buttonSize.width),
            locationButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -Constants.sideInset),
            locationButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Constants.sideInset)
        ])
        locationButton.addTarget(self, action: #selector(locationButtonTapped), for: .touchUpInside)

        //favourites button
        NSLayoutConstraint.activate([
            favouritesButton.heightAnchor.constraint(equalToConstant: Constants.buttonSize.height),
            favouritesButton.widthAnchor.constraint(equalToConstant: Constants.buttonSize.width),
            favouritesButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: Constants.sideInset),
            favouritesButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Constants.sideInset)
        ])
        favouritesButton.addTarget(self, action: #selector(favsButtonTapped), for: .touchUpInside)
    }

    //MARK: button funcs
    @objc func locationButtonTapped(){
        centerUserLocation(animated: true)
    }

    @objc func favsButtonTapped(){
        let favController = PhotoListController()
        bottomNavigation.pushViewController(favController, animated: true)
    }
}



//MARK: - BottomSheetFactory
extension MapController: BottomSheetFactory {
    func makePresentationController(
        presentedViewController: UIViewController,
        presenting: UIViewController?
    ) -> UIPresentationController {
        guard let navigationController = presentedViewController as? UINavigationController,
              let topController = navigationController.topViewController else {
            fatalError("Incorrect view controllers")
        }
        let controller = BottomSheetPresentationController(
            fractions: [0.15, 0.65, 0.85],
            presentedViewController: presentedViewController,
            presenting: presenting,
            contentViewController: topController
        )
        bottomNavigation.addObserver(controller)
        bottomSheetDelegate = controller
        controller.heightObserver = self
        return controller
    }
}

//MARK: - Bottom sheet height
extension MapController: BottomSheetHeightObserver {
    func heightDidChange(newHeight: CGFloat) {
        let safeHeight = view.bounds.height - view.safeAreaInsets.top - view.safeAreaInsets.bottom
        let fraction = newHeight / safeHeight
        map.updateVerticalOffset(fraction: fraction)
        cancelAllUpdateRequests()
    }

    func heightWillChange(newHeight: CGFloat, in duration: Double) {
        let safeHeight = view.bounds.height - view.safeAreaInsets.top - view.safeAreaInsets.bottom
        let fraction = newHeight / safeHeight
        map.updateVerticalOffset(fraction: fraction, animated: true)
        cancelAllUpdateRequests(for: duration)
    }


    // отменяем запросы подгрузки новых изображений
    // это нужно для того, чтобы список фотографий не перезагружался при его открытии
    // а запросы отправляются потому что регион карты меняется
    private func cancelAllUpdateRequests(){
        NSObject.cancelPreviousPerformRequests(
            withTarget: self,
            selector: #selector(loadNewAnnotations),
            object: nil
        )
    }

    private func cancelAllUpdateRequests(for duration: TimeInterval){
        let start = Date()
        timer = Timer.scheduledTimer(withTimeInterval: Constants.mapDelay/2, repeats: true, block: { [weak self] _ in
            self?.cancelAllUpdateRequests()
            if start.distance(to: Date()) > duration { self?.timer.invalidate() }
        })
    }
}

//MARK: - Nav controller observer
extension MapController: NavigationControllerObserver {
    func didPush(vc: UIViewController) {}
    func didPop(newLast: UIViewController) {}
    func willPop(vc: UIViewController) {
        guard vc is PhotoDetailsController else { return }
        map.selectedAnnotations.forEach {
            map.deselectAnnotation($0, animated: true)
        }
    }
}

//MARK: MKMapView delegate
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
        cancelAllUpdateRequests()
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
            return
        }
        if let photo = view.annotation as? Photo {
            map.setAdjustedCenter(photo.coordinate, animated: true)
            showSinglePhotoDetails(photo: photo)
            for selectedAnn in map.selectedAnnotations {
                guard let selectedPhoto = selectedAnn as? Photo else { continue }
                guard selectedPhoto.cid != photo.cid else { continue }
                map.deselectAnnotation(selectedAnn, animated: true)
            }
            return
        }
        if let localCluster = view as? MultiplePhotosAnnotationView {
            guard let annotation = localCluster.annotation as? MKClusterAnnotation else { return }
            map.setAdjustedCenter(annotation.coordinate, animated: true)
            let photos = annotation.memberAnnotations.compactMap { $0 as? Photo }
            guard !photos.isEmpty else {return}
            showMultiplePhotosList(photos: photos)
            map.deselectAnnotation(annotation, animated: true)
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

    func mapView(_: MKMapView, didAdd views: [MKAnnotationView]) {
        showWithAnimation(views)
    }
}

//MARK: yearSelection
extension MapController: YearSelectorDelegate {
    func rangeDidChange(newRange: ClosedRange<Int>) {
        yearRange = newRange
        NSObject.cancelPreviousPerformRequests(
            withTarget: self,
            selector: #selector(clearAndLoadNewAnnotations),
            object: nil
        )
        self.perform(#selector(clearAndLoadNewAnnotations), with: nil, afterDelay: Constants.mapDelay)
    }
}

//MARK: MapPublisher
extension MapController: MapPublisher {
    func addObserver(_ observer: MapObserver) {
        map.addObserver(observer)
    }
}

// MARK: - animating annotations
extension MapController {
    // у меня пока что не получается закинуть анимацию появления в MKMapView override куда-нибудь
    // на тот момент ещё нет view(for: annotation)
    private func showWithAnimation(_ views: [MKAnnotationView]) {
        for view in views {
            let initialTransform = view.transform
            view.transform = Constants.superSmallTransform
            UIView.animate(withDuration: Constants.annotationAnimationDuration, animations: {
                view.transform = initialTransform
            })
        }
    }

    private func animateSelection(
        _ view: MKAnnotationView,
        isSelected: Bool,
        animated: Bool = true
    ) {
        let transform = isSelected ? Constants.selectedTransform : Constants.biggestTransfrorm
        guard animated else {
            view.transform = transform
            return
        }
        DispatchQueue.main.async {
            UIView.animate(withDuration: Constants.annotationAnimationDuration) {
                view.transform = transform
            }
        }
    }

    func showSinglePhotoDetails(photo: Photo) {
        let singleController = PhotoDetailsController(
            cid: photo.cid,
            detailsProvider: photoDetailsProvider
        )
        self.bottomNavigation.pushViewController(singleController, animated: true)
        let count = bottomNavigation.viewControllers.count
        if count > 1,
           bottomNavigation.viewControllers[count - 2] as? PhotoDetailsController != nil {
            bottomNavigation.viewControllers[count - 2].removeFromParent()
        }
    }

    func showMultiplePhotosList(photos: [Photo]) {
        let list = PhotoListController(photos: photos)
        self.bottomNavigation.pushViewController(list, animated: true)
        let count = bottomNavigation.viewControllers.count
        if count > 1,
           let prevList = bottomNavigation.viewControllers[count - 2] as? PhotoListController,
           prevList.type == .localCluster {
            bottomNavigation.viewControllers[count - 2].removeFromParent()
        }
    }
}

extension MapController: LocationObserverDelegate {
    func didUpdateLocation(location: CLLocation) {
        if waitingForLocation {
            map.setAdjustedCenter(location.coordinate, animated: false)
            waitingForLocation = false
        }
    }

    func didFail() {
        waitingForLocation = false
    }
}
