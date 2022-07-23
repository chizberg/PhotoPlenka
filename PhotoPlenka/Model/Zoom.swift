//
//  Zoom.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 04.02.2022.
//

import MapKit

struct Zoom {
  private var zoomValue: Int = 0 {
    didSet {
      // на зуме больше 19 или меньше 3 API перестаёт что-то скидывать
      if zoomValue > 19 { zoomValue = 19 }; if zoomValue < 3 { zoomValue = 3 }
    }
  }

  private var delta: Double

  var z: Int {
    get {
      zoomValue
    }
    set {
      zoomValue = newValue
      delta = deltaFromZoom(zoom: zoomValue)
    }
  }

  var span: MKCoordinateSpan {
    get {
      MKCoordinateSpan(latitudeDelta: delta, longitudeDelta: delta)
    }
    set {
      delta = min(newValue.latitudeDelta, newValue.longitudeDelta)
      zoomValue = zoomFromDelta(delta: delta)
    }
  }

  init(span: MKCoordinateSpan) {
    delta = min(span.latitudeDelta, span.longitudeDelta)
    zoomValue = zoomFromDelta(delta: delta)
  }
}

extension Zoom {
  // откуда я взял эти формулы? - https://leafletjs.com/examples/zoom-levels/
  // я придумал только прибавить 2 к уровню зума, потому что иначе смотрится так себе
  private func zoomFromDelta(delta: Double) -> Int {
    Int(2 + log2(180 / delta))
  }

  private func deltaFromZoom(zoom _: Int) -> Double {
    180 / pow(2.0, Double(z - 2))
  }
}

extension MKMapView {
  // чтобы загружалось за пределами Safe Area, видимо
  // если использовать обычный region, то метки за бровью и по краям перестают загружаться
  // возможно, я где-то налажал, но так всё работает замечательно
  private enum Constants {
    static let extendedMultiplier: Double = 1.2
  }

  var extendedRegion: MKCoordinateRegion {
    let (latitudeDelta, longitudeDelta) = (
      region.span.latitudeDelta,
      region.span.longitudeDelta
    )
    let newSpan = MKCoordinateSpan(
      latitudeDelta: latitudeDelta * Constants.extendedMultiplier,
      longitudeDelta: longitudeDelta * Constants.extendedMultiplier
    )
    return MKCoordinateRegion(center: region.center, span: newSpan)
  }
}
