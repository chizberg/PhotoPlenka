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
    yearRange: ClosedRange<Int>,
    _ completion: @escaping CompletionType
  )
  func clear()
}

final class AnnotationProvider: AnnotationProviderProtocol {
  // images and clusters that are the same as on the map
  private var photos: Set<Photo>
  private var clusters: Set<Cluster>
  private var groupMaker: GroupMaker

  private let networkService: NetworkServiceProtocol

  init(
    networkService: NetworkServiceProtocol
  ) {
    self.networkService = networkService
    self.photos = Set<Photo>()
    self.clusters = Set<Cluster>()
    self.groupMaker = GroupMaker()
  }

  func loadNewAnnotations(
    z: Int,
    region: MKCoordinateRegion,
    yearRange: ClosedRange<Int>,
    _ completion: @escaping CompletionType
  ) {
    networkService
      .loadByBounds(z: z, region: region, yearRange: yearRange) { [weak self] result in
        guard let self = self else { return }
        assert(Thread.isMainThread)
        switch result {
        case let .success((networkPhotos, networkClusters)):
          let photoAnnotations = Set(networkPhotos.map { Photo(from: $0) })
          let clusterAnnotations = Set(networkClusters.map { Cluster(from: $0) })

          // new images that will be added to mapView
          let photoDiff = photoAnnotations.subtracting(self.photos)
          let clusterDiff = clusterAnnotations.subtracting(self.clusters)
          let (photos, groups) = self.updateGroups(
            delta: min(region.span.latitudeDelta, region.span.longitudeDelta),
            photoDiff: Array(photoDiff)
          )
          let combined = self.combineAnnotations(photos, groups, Array(clusterDiff))
          completion(.success(combined))

          self.photos = self.photos.union(photoAnnotations)
          self.clusters = self.clusters.union(clusterAnnotations)
        case let .failure(error):
          completion(.failure(error))
        }
      }
  }

  private func updateGroups(
    delta: Double,
    photoDiff: [Photo]
  ) -> (photos: [Photo], groups: [PhotoGroup]) {
    groupMaker.addData(newGroupDiameter: delta / 7, photos: photoDiff)
  }

  private func combineAnnotations(
    _ photos: [Photo],
    _ groups: [PhotoGroup],
    _ clusters: [Cluster]
  ) -> [MKAnnotation] {
    (photos as [MKAnnotation]) +
      (groups as [MKAnnotation]) +
      (clusters as [MKAnnotation])
  }

  // should be used when z is changed on the map
  func clear() {
    photos = Set<Photo>()
    clusters = Set<Cluster>()
    groupMaker.clear()
  }
}
