//
//  CoreDataProvider.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 12.04.2022.
//

import CoreData
import UIKit

protocol FavouritesProviderProtocol: AnyObject {
    var favourites: [Photo]? { get set }
    func isFav(cid: Int) -> Bool
    func set(photo: Photo, isFav: Bool)
}

final class FavouritesProvider: FavouritesProviderProtocol {
    static let shared = FavouritesProvider()

    private let context: NSManagedObjectContext
    private init(){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let container = delegate.persistentContainer
        self.context = container.viewContext
    }

    //MARK: - manipulation
    var favourites: [Photo]? {
        get {
            guard let cdPhotos = try? fetch() else { return nil }
            return cdPhotos.compactMap { Photo(from: $0) }
        }
        set {
            guard let newValue = newValue else { return }
            try? save(newValue)
        }
    }

    func isFav(cid: Int) -> Bool {
        guard let cdPhotos = try? fetch() else { return false }
        return cdPhotos.contains(where: { $0.cid == Int32(cid) })
    }

    func set(photo: Photo, isFav: Bool){
        //adding to favs
        guard isFav == false else {
            try? save(photo)
            return
        }

        //removing from favs
        let request = CDPhoto.fetchRequest()
        let predicate = NSPredicate(format: "cid == %ld", Int32(photo.cid))
        request.predicate = predicate
        guard let results = try? context.fetch(request) else { return }
        for result in results {
            context.delete(result)
        }
        try? context.save()
    }

    //MARK: - private methods
    private func fetch() throws -> [CDPhoto] {
        try context.fetch(CDPhoto.fetchRequest())
    }

    private func clear() throws {
        let objects = try fetch()
        for object in objects {
            context.delete(object)
        }
        try context.save()
    }

    private func save(_ photo: Photo) throws {
        let object = CDPhoto(context: context)
        object.cid = Int32(photo.cid)
        object.name = photo.name
        object.dir = photo.dir?.rawValue
        object.year = Int16(photo.year)
        object.year2 = Int16(photo.year2)
        object.file = photo.file
        object.latitude = photo.coordinate.latitude
        object.longitude = photo.coordinate.longitude
        try context.save()
    }

    private func save(_ photos: [Photo]) throws {
        try clear()
        for photo in photos {
            try save(photo)
        }
    }
}
