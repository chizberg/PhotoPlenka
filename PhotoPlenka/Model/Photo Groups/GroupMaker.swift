//
//  GroupMaker.swift
//  PhotoPlenka
//
//  Created by Alexey Sherstnev on 24.07.2022.
//

import CoreLocation
import Foundation

final class GroupMaker {
  typealias Content = (photos: [Photo], groups: [PhotoGroup])
  private var singles: [Photo]
  private var groups: [PhotoGroup]

  var groupDiameter: Double

  init(groupDiameter: Double = 0) {
    self.groupDiameter = groupDiameter
    singles = []
    groups = []
  }

  func addData(newGroupDiameter: Double? = nil, photos: [Photo]) -> Content {
    groupDiameter = newGroupDiameter ?? groupDiameter
    singles.append(contentsOf: photos)
    updateGroups()
    return (singles, groups)
  }

  func clear(newGroupDiameter: Double? = nil) {
    groupDiameter = newGroupDiameter ?? groupDiameter
    singles = []
    groups = []
  }

  private func updateGroups() {
    checkExistingGroups()
    fillExistingGroups()
    makeNewGroups()
  }

  // checks if there's any photo in groups that is too far away
  private func checkExistingGroups() {
    var i = 0 // group index
    while i < groups.count {
      let center = groups[i].coordinate
      var j = 0 // photo index
      while j < groups[i].count {
        let photo = groups[i].photos[j]
        if photo.distanceTo(center) > groupDiameter {
          self.singles.append(photo)
          groups[i].photos.remove(at: j)
          continue
        }
        j += 1
      }
      // removing empty clusters
      if groups[i].photos.isEmpty {
        groups.remove(at: i)
        continue
      }
      i += 1
    }
  }

  // adds singles to nearby groups that already exist
  private func fillExistingGroups() {
    for i in 0..<groups.count {
      let center = groups[i].coordinate
      var j = 0
      while j < singles.count {
        if singles[j].distanceTo(center) <= groupDiameter {
          groups[i].append(singles[j])
          singles.remove(at: j)
          continue
        }
        j += 1
      }
    }
  }

  // makes new groups from close single photos
  private func makeNewGroups() {
    var i = 0
    while i < singles.count {
      let center = singles[i].coordinate
      let tempGroup = PhotoGroup(coordinate: center)
      var j = i + 1
      while j < singles.count {
        if singles[j].distanceTo(center) <= groupDiameter {
          tempGroup.append(singles[j])
          singles.remove(at: j)
          continue
        }
        j += 1
      }
      if tempGroup.count > 0 {
        tempGroup.append(singles[i])
        singles.remove(at: i)
        groups.append(tempGroup)
        continue
      }
      i += 1
    }
  }
}

extension CLLocationCoordinate2D {
  func distanceTo(_ other: CLLocationCoordinate2D) -> Double {
    let latDiff = self.latitude - other.latitude
    let longDiff = self.longitude - other.longitude
    return sqrt(latDiff * latDiff + longDiff * longDiff)
  }
}
