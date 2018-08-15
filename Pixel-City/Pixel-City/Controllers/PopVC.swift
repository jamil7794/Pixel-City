//
//  PopVC.swift
//  Pixel-City
//
//  Created by Jamil Jalal on 8/10/18.
//  Copyright © 2018 Jamil Jalal. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class PopVC: UIViewController, UIGestureRecognizerDelegate {
   

    @IBOutlet weak var titleLbl: UILabel?
    @IBOutlet weak var popImageView: UIImageView!
    var passedImage:  UIImage!
    var locationManager = CLLocationManager()
    let authorizationStatus = CLLocationManager.authorizationStatus() // Keeps Track
    var tittle: String!
    var pin : DroppablePin! = nil

   
    @IBOutlet weak var mapView: MKMapView!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        locationManager.delegate = self
        configureLocationServices()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.mapView.showsUserLocation = true
        popImageView.image = passedImage
        titleLbl?.text = tittle
        titleLbl?.textColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        mapView.addAnnotation(pin)
        addDoubleTap()
        centerMapOnUserLocation()
        addSwipe()
    }

    func initData(forImage image: UIImage, title: String!, annotation: DroppablePin){
        self.passedImage = image
        self.tittle = title
        self.pin = annotation
    }
    
    func addDoubleTap(){
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(screenWasDoubleTaped))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.delegate = self
        view.addGestureRecognizer(doubleTap)
    }
    
    @objc func screenWasDoubleTaped(){
        dismiss(animated: true, completion: nil)
    }
    
    func addAnnotation(annotation: DroppablePin){
        let annatation = annotation
        mapView.addAnnotation(annatation)
    }
    
    func addSwipe(){
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(DismissView))
        swipeRight.direction = .right
        self.view.addGestureRecognizer(swipeRight)
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(DismissView))
        swipeDown.direction = .down
        self.view.addGestureRecognizer(swipeDown)
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(DismissView))
        swipeLeft.direction = .left
        self.view.addGestureRecognizer(swipeLeft)
        
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(DismissView))
        swipeUp.direction = .up
        self.view.addGestureRecognizer(swipeUp)
    }
    
    @objc func DismissView(){
        self.dismiss(animated: true, completion: nil)
    }
}

extension PopVC: MKMapViewDelegate {
    
    func centerMapOnUserLocation(){ // Center the coordinate on user location
        guard let coordinate = pin?.coordinate else {return}
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(coordinate, 100, 100)
        mapView.setRegion(coordinateRegion, animated: true)
    }
}

extension PopVC: CLLocationManagerDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // Customize the pin drop
        
        if annotation is MKUserLocation {
            return nil
        }
        let pinAnnotation = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "droppablePin")
        pinAnnotation.pinTintColor = #colorLiteral(red: 0.7450980544, green: 0.1568627506, blue: 0.07450980693, alpha: 1)
        pinAnnotation.animatesDrop = true
        return pinAnnotation
    }
    
    func configureLocationServices(){ // are we authorized to access the location
        if authorizationStatus == .notDetermined {
            locationManager.requestAlwaysAuthorization() // Whether the app is closed or open we are always going to request location
        }else{
            return
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        //Where to call that to center the map on user location. Anytime the map view change authozation. Everytime we aproove we center the user.
        centerMapOnUserLocation()
    }
}

