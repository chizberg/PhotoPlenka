//
//  AnnotationProvider.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 05.02.2022.
//

import MapKit

protocol AnnotationProviderProtocol {
    typealias CompletionType =
        (Result<[MKAnnotation], NetworkError>) -> Void
    func loadNewAnnotations(
        z: Int,
        region: MKCoordinateRegion,
        _ completion: @escaping CompletionType
    )
    func clear()
}

final class AnnotationProvider: AnnotationProviderProtocol {
    // images and clusters that are the same as on the map
    private var photos: Set<Photo>
    private var clusters: Set<Cluster>

    private var networkService: NetworkServiceProtocol

    init(
        networkService: NetworkServiceProtocol
    ) {
        self.networkService = networkService
        self.photos = Set<Photo>()
        self.clusters = Set<Cluster>()
    }

    func loadNewAnnotations(
        z: Int,
        region: MKCoordinateRegion,
        _ completion: @escaping CompletionType
    ) {
        networkService.loadByBounds(z: z, region: region) { [weak self] result in
            guard let self = self else { return }
            assert(Thread.isMainThread)
            switch result {
            case let .success((networkPhotos, networkClusters)):
                let photoAnnotations = Set(networkPhotos.map { Photo(from: $0) })
                let clusterAnnotations = Set(networkClusters.map { Cluster(from: $0) })

                // new images that will be added to mapView
                let photoDiff = photoAnnotations.subtracting(self.photos)
                let clusterDiff = clusterAnnotations.subtracting(self.clusters)
                completion(.success(self.annotationsFromSets(photoDiff, clusterDiff)))

                self.photos = self.photos.union(photoAnnotations)
                self.clusters = self.clusters.union(clusterAnnotations)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    private func annotationsFromSets(
        _ photoSet: Set<Photo>,
        _ clusterSet: Set<Cluster>
    ) -> [MKAnnotation] {
        let photoArray = Array(photoSet) as [MKAnnotation]
        let clusterArray = Array(clusterSet) as [MKAnnotation]
        return photoArray + clusterArray
    }

    // should be used when z is changed on the map
    func clear() {
        photos = Set<Photo>()
        clusters = Set<Cluster>()
    }
}
