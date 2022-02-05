//
//  Photo.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 02.02.2022.
//

import MapKit

final class Photo: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    let cid: Int
    let name: String
    let dir: Direction?
    let year: Int
    let year2: Int
    let file: String
    private var image: UIImage?

    init(from np: NetworkPhoto) {
        self.cid = np.cid
        self.name = np.title
        if let dirString = np.dir, let dir = Direction(rawValue: dirString) {
            self.dir = dir
        } else if let dirString = np.dir, !dirString.isEmpty {
            assertionFailure("unknown direction: \(dirString)") // если встретим неизвестный direction
            self.dir = nil
        } else {
            self.dir = nil
        }
        self.coordinate = CLLocationCoordinate2D(latitude: np.geo[0], longitude: np.geo[1])
        self.year = np.year
        self.year2 = np.year2
        self.file = np.file
    }
}

enum ImageQuality: String { // RawValue is used in URL path
    case high = "a"
    case medium = "d"
    case preview = "s"
}

extension Photo {
    func imageLink(quality: ImageQuality) -> URL? {
        URL(string: "https://pastvu.com/_p/\(quality.rawValue)/\(file)")
    }
}

extension Photo {
    override var hash: Int {
        cid
    }

    override func isEqual(_ object: Any?) -> Bool {
        if let other = object as? Photo {
            return cid == other.cid
        }
        return false
    }
}
