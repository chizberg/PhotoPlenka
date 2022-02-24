//
//  NetworkDetailedPhoto.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 22.02.2022.
//

import Foundation

// is received from API method giveForPage
struct NetworkDetailedPhoto {
    let cid: Int // unique photo id
    let file: String // local path to image
    let title: String
    let dir: String? // direction
    let geo: [Double] // location, has two values: latitude and longitude
    let year: Int // lower time boundary
    let year2: Int // upper time boundary

    let desc: String? // description of photo
    let source: String? // can contain url
    let address: String?
    let author: String?

    // inner JSON values
    let username: String // (user.disp) name of user that has uploaded the photo
}
