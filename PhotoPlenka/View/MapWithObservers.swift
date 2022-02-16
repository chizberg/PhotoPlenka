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
        for annotation in visibleAnnotations {
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
}
