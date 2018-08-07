//
//  Constants.swift
//  Pixel-City
//
//  Created by Jamil Jalal on 8/7/18.
//  Copyright © 2018 Jamil Jalal. All rights reserved.
//

import Foundation

let apiKey = "d61dd1f9450149de2c6da4e80ba3b6bf"

func flickrUrl(forApikey key: String, withAnnotation annotation: DroppablePin, numberOfPhotos number: Int) -> String{
    return "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(apiKey)&lat=\(annotation.coordinate.latitude)&lon=\(annotation.coordinate.longitude)&radius=1&radius_units=mi&per_page=\(number)&format=json&nojsoncallback=1"
}



