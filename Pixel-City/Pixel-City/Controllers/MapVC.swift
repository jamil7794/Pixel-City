//
//  ViewController.swift
//  Pixel-City
//
//  Created by Jamil Jalal on 8/1/18.
//  Copyright © 2018 Jamil Jalal. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import Alamofire
import AlamofireImage
import SwiftyJSON

class MapVC: UIViewController, UIGestureRecognizerDelegate {

    
    @IBOutlet weak var mapView: MKMapView!
    var locationManager = CLLocationManager()
    let authorizationStatus = CLLocationManager.authorizationStatus() // Keeps Track
    let regionRadius: Double = 1000
    @IBOutlet weak var mapViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var pullUpView: UIView!
    @IBOutlet weak var pullUpViewHeightConstraint: NSLayoutConstraint!
    var screenSize = UIScreen.main.bounds
    var spinner: UIActivityIndicatorView?
    var progressLbl: UILabel?
    var collectionView: UICollectionView?
    var flowLayout = UICollectionViewFlowLayout()
    var imageUrlArray = [String]()
    var imageArray = [UIImage]()
    var titlePic = [String]()
    var isFriendPic = [Int]()
    var pin: DroppablePin! = nil
   
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        locationManager.delegate = self
        configureLocationServices()
        addDoubleTap()
        
//        locationManager.desiredAccuracy = kCLLocationAccuracyBest
//        self.mapView.showsUserLocation = true
       
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: flowLayout)
        collectionView?.register(PhotoCell.self, forCellWithReuseIdentifier: "photoCell")
        collectionView?.delegate = self
        collectionView?.dataSource = self
        collectionView?.backgroundColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        pullUpView.addSubview(collectionView!)
        registerForPreviewing(with: self, sourceView: collectionView!)
    }
    
    func addDoubleTap(){
        let doubleTap = UILongPressGestureRecognizer(target: self, action: #selector(dropPin(sender:)))
       // doubleTap.numberOfTapsRequired = 2
        doubleTap.delegate = self
        mapView.addGestureRecognizer(doubleTap)
    }
    
    func animateViewUp(){
        pullUpViewHeightConstraint.constant = 300
        UIView.animate(withDuration: 0.3) {
             self.view.layoutIfNeeded() // Redraw the constraints
        }
    }
    
    func addSpinner(){
        spinner = UIActivityIndicatorView()
        spinner?.center = CGPoint(x: (screenSize.width/2) - ((spinner?.frame.width)! / 2), y: 150)
        spinner?.activityIndicatorViewStyle = .whiteLarge
        spinner?.color = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
        spinner?.startAnimating()
        collectionView?.addSubview(spinner!)
    }
    
    @objc func animateViewDown(){
        pullUpViewHeightConstraint.constant = 0
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded() // Redraw the constraints
        }
    }
    
    func removeSpinner(){
        if spinner != nil {
            spinner?.removeFromSuperview()
        }
    }
    
    func addProgressLbl(){
        progressLbl = UILabel()
        progressLbl?.frame = CGRect(x: (screenSize.width/2) - 120 , y: 175, width: 240, height: 40)
        progressLbl?.font = UIFont(name: "Avenir Next", size: 18)
        progressLbl?.textColor = #colorLiteral(red: 0.3266413212, green: 0.4215201139, blue: 0.7752227187, alpha: 1)
        progressLbl?.textAlignment = .center
        progressLbl?.text = "Hello"
        collectionView?.addSubview(progressLbl!)
    }
    
    func removeProgressLbl(){
        if progressLbl != nil {
            progressLbl?.removeFromSuperview()
        }
    }
    
    @IBAction func centerMapButtonWasPressed(_ sender: Any) {
        if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse{
            centerMapOnUserLocation()
        }
    }
    
    func addSwipe(){
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(animateViewDown))
        swipe.direction = .down
        pullUpView.addGestureRecognizer(swipe)
    }
    
//    func swipeAndDownWithTheView(){
//        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(MoveView))
//    }
//
//    @objc func MoveView(){
//
//    }
    
    
    
    @objc func dropPin(sender: UITapGestureRecognizer){
        removePin()
        removeSpinner()
        removeProgressLbl()
        cancelAllSessions()
        
        // make them empty
        imageUrlArray = []
        imageArray = []
        self.collectionView?.reloadData()
        
        animateViewUp()
        addSwipe()
        addSpinner()
        addProgressLbl()
        
        let touchPoint = sender.location(in: mapView)
        let touchCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        
        let annotation = DroppablePin(coordinate: touchCoordinate, identifier: "droppablePin")
        pin = annotation
        mapView.addAnnotation(annotation)
       // guard let popVC = storyboard?.instantiateViewController(withIdentifier: "PopVC") as? PopVC else {return}
        
        
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(touchCoordinate, regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
        
        retrieveUrls(forAnnotation: annotation) { (finished) in
            if finished { // When the first one is done, the second one starts
                self.retrieveImages(handler: { (finished) in
                    if finished{
                        self.spinner?.isHidden = true
                        self.removeProgressLbl()
                        self.collectionView?.reloadData()
                    }
                })
            }
        }
    }
    
    func removePin(){
        for annotation in mapView.annotations {
            mapView.removeAnnotation(annotation)
        }
    }
    
    func cancelAllSessions(){
        Alamofire.SessionManager.default.session.getTasksWithCompletionHandler { (sessionDataTask, uploadData, downloadedData) in
            sessionDataTask.forEach({ $0.cancel()}) // Instead of using for loop The sessionsDataTask from ALamofire will be canceled
            
            downloadedData.forEach({ $0.cancel()}) // Instead of using for loop The downloaded from ALamofire will be canceled
        }
    }
    
    func retrieveUrls(forAnnotation annotation: DroppablePin, handler: @escaping (_ status: Bool) ->()){
        Alamofire.request(flickrUrl(forApikey: apiKey, withAnnotation: annotation, numberOfPhotos: 40)).responseJSON { (response) in
            
                guard let json = response.result.value as? Dictionary<String, AnyObject> else {return}
                let photosDict = json["photos"] as! Dictionary<String, AnyObject>
                let photosDictArray = photosDict["photo"] as! [Dictionary<String, AnyObject>]
                for photo in photosDictArray{
                    let postUrl = "https://farm\(photo["farm"]!).staticflickr.com/\(photo["server"]!)/\(photo["id"]!)_\(photo["secret"]!)_h_d.jpg"
                    self.imageUrlArray.append(postUrl)
                    let title = photo["title"] as! String
                    let isfriend = photo["isfriend"] as! Int
                    self.titlePic.append(title)
                    self.isFriendPic.append(isfriend)
                    //print(postUrl)
                }
                handler(true)
        }
        
    }
    
    func retrieveImages(handler: @escaping (_ status: Bool)-> ()){
        for url in imageUrlArray {
            Alamofire.request(url).responseImage { (response) in
                guard let image = response.result.value else {return}
                self.imageArray.append(image)
                self.progressLbl?.text = "\(self.imageArray.count)/40 Images Downloaded"
                
                if self.imageArray.count == self.imageUrlArray.count {
                    handler(true)
                }
            }
        }
    }
    
}


extension MapVC: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // Customize the pin drop
        
        if annotation is MKUserLocation {
            return nil
        }
        let pinAnnotation = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "droppablePin")
        pinAnnotation.pinTintColor = #colorLiteral(red: 0.9771530032, green: 0.7062081099, blue: 0.1748393774, alpha: 1)
        pinAnnotation.animatesDrop = true
        return pinAnnotation
    }
    
    func centerMapOnUserLocation(){ // Center the coordinate on user location
        guard let coordinate = locationManager.location?.coordinate else {return}
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(coordinate, regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
}

extension MapVC: CLLocationManagerDelegate {
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

extension MapVC: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as? PhotoCell else { return UICollectionViewCell()}
        let imageFromIndex = imageArray[indexPath.row]
        let imageView = UIImageView(image: imageFromIndex)
        
        let friendIndex = isFriendPic[indexPath.row]
        let friends : UILabel?
        friends = UILabel()
        friends?.text = "\(friendIndex)"
        print(friendIndex)
        cell.addSubview(imageView)
        cell.addSubview(friends!)
        removeSpinner()
        return cell
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let popVC = storyboard?.instantiateViewController(withIdentifier: "PopVC") as? PopVC else {return}
        popVC.initData(forImage: imageArray[indexPath.row], title: titlePic[indexPath.row], annotation: pin)
        present(popVC, animated: true, completion: nil)
    }
}

extension MapVC: UIViewControllerPreviewingDelegate { //3D touch
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        // where are we pressing from
        guard let indexPath = collectionView?.indexPathForItem(at: location), let cell = collectionView?.cellForItem(at: indexPath) else {return nil} // 2 combined together
        guard let popVC = storyboard?.instantiateViewController(withIdentifier: "PopVC") as? PopVC else {return nil}
        popVC.initData(forImage: imageArray[indexPath.row], title: titlePic[indexPath.row], annotation: pin)
        previewingContext.sourceRect = cell.contentView.frame
        return popVC
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        show(viewControllerToCommit, sender: self)
    }
}
