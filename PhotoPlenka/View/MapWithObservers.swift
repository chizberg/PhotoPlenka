//
//  MapWithObservers.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 14.02.2022.
//

import MapKit

final class MapWithObservers: MKMapView, MapPublisher {
  private enum Style {
    static let annotationAnimationDuration: TimeInterval = 0.2
    static let superSmallTransform = CGAffineTransform(scaleX: 0.01, y: 0.01)
  }

  // храним множество слабых ссылок
  private(set) var observers = NSHashTable<MapObserver>.weakObjects()

  // offsetFraction - то, насколько должна смещаться видимая область карты
  // значения от 0 до 1
  // нужен для правильного центрирования меток с учётом видимой области на карте
  private var verticalOffsetFraction: CGFloat = 0

  func addObserver(_ observer: MapObserver) {
    observers.add(observer)
  }

  var visibleAnnotations: [MKAnnotation] {
    Array(annotations(in: visibleMapRect)) as? [MKAnnotation] ?? []
  }

  private func annotationsDidChange() {
    // запускаем функцию у каждого подписчика
    let enumerator = observers.objectEnumerator()
    while let observer = enumerator.nextObject() as? MapObserver {
      observer.annotationsDidChange(annotations: annotations, visible: visibleAnnotations)
    }
  }

  override func addAnnotations(_ annotations: [MKAnnotation]) {
    super.addAnnotations(annotations)
    annotationsDidChange()
  }

  override func addAnnotation(_ annotation: MKAnnotation) {
    super.addAnnotation(annotation)
    annotationsDidChange()
  }

  // почему-то анимация не воспроизводится, если её перенести в MapController
  override func removeAnnotations(_ annotations: [MKAnnotation]) {
    let group = DispatchGroup()
    for annotation in annotations {
      guard let annotationView = view(for: annotation) else { continue }
      group.enter()
      DispatchQueue.main.async(group: group) {
        UIView.animate(withDuration: Style.annotationAnimationDuration, animations: {
          annotationView.transform = Style.superSmallTransform
        }, completion: { _ in group.leave() })
      }
    }
    group.notify(queue: .main) {
      super.removeAnnotations(annotations)
      self.annotationsDidChange()
    }
  }

  override func removeAnnotation(_ annotation: MKAnnotation) {
    super.removeAnnotation(annotation)
    annotationsDidChange()
  }

  // пусть map.centerCoordinate - абсолютный центр (посередине mapView вне зависимости от видимости)
  // newCenter - центр, который мы хотим расположить в центре видимой области
  // verticalOffsetFraction - часть, которая перекрыта bottomSheet
  // если у нас verticalOffsetFraction = 0.3, то мы сместим центр на 0.15, то есть в 2 раза меньше
  // эта функция получает абсолютный центр карты исходя из центра видимой области
  private func adjust(_ coordinate: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
    let latitudeDelta = region.span.latitudeDelta
    let newLatitude = coordinate.latitude - latitudeDelta * verticalOffsetFraction / 2
    return CLLocationCoordinate2D(latitude: newLatitude, longitude: coordinate.longitude)
  }

  // получает центр видимой области исходя из абсолютного центра карты
  private func deAdjust(_ coordinate: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
    let latitudeDelta = region.span.latitudeDelta
    let oldLatitude = coordinate.latitude + latitudeDelta * verticalOffsetFraction / 2
    return CLLocationCoordinate2D(latitude: oldLatitude, longitude: coordinate.longitude)
  }

  func setAdjustedCenter(_ coordinate: CLLocationCoordinate2D, animated: Bool) {
    self.setCenter(adjust(coordinate), animated: animated)
  }

  // получаем центр, обновляем offset, обновляем центр с новым offset
  func updateVerticalOffset(fraction: CGFloat, animated: Bool = false) {
    let oldCenter = deAdjust(centerCoordinate)
    verticalOffsetFraction = fraction
    setAdjustedCenter(oldCenter, animated: animated)
  }

  override func setRegion(_ region: MKCoordinateRegion, animated: Bool) {
    let adjustedCenter = adjust(region.center)
    let adjustedRegion = MKCoordinateRegion(center: adjustedCenter, span: region.span)
    super.setRegion(adjustedRegion, animated: animated)
  }
}
