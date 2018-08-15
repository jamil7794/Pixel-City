//
//  DroppablePin.swift
//  Pixel-City
//
//  Created by Jamil Jalal on 8/2/18.
//  Copyright © 2018 Jamil Jalal. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class DroppablePin: NSObject, MKAnnotation {
    dynamic var coordinate: CLLocationCoordinate2D
    var identifier: String!
    
    init(coordinate: CLLocationCoordinate2D, identifier: String) {
        self.coordinate = coordinate
        self.identifier = identifier
        super.init()
    }
    
}
