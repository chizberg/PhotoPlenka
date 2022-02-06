//
//  MapWithObservers.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 14.02.2022.
//

import MapKit

final class MapWithObservers: MKMapView, MapPublisher {
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

    override func removeAnnotations(_ annotations: [MKAnnotation]) {
        super.removeAnnotations(annotations)
        annotationsDidChange()
    }

    override func removeAnnotation(_ annotation: MKAnnotation) {
        super.removeAnnotation(annotation)
        annotationsDidChange()
    }
}
