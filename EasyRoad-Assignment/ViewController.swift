//
//  ViewController.swift
//  EasyRoad-Assignment
//
//  Created by Holachef on 16/04/18.
//  Copyright © 2018 Vinod. All rights reserved.
//

import UIKit
import GoogleMaps
import Alamofire
import SwiftyJSON

class ViewController: UIViewController {

    var mapView : GMSMapView!
    var locationManager =   CLLocationManager()
    
    @IBOutlet weak var searchSideTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var searchIndicatorImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchSideTrailingConstraint.constant   =   -245
        
        let camera = GMSCameraPosition.camera(withLatitude: -33.86, longitude: 151.20, zoom: 6.0)
        mapView = GMSMapView.map(withFrame: self.view.bounds, camera: camera)
        mapView.isMyLocationEnabled =   true
        view.addSubview(mapView)
        
        
        locationManager.delegate    =   self
        locationManager.startUpdatingLocation()
        
        self.view.sendSubview(toBack: mapView)
    }
    
    
    @IBAction func searchTapped(_ sender: UIButton) {
        
        if searchSideTrailingConstraint.constant == 0 {
            searchIndicatorImageView.transform  =   CGAffineTransform(rotationAngle: 0)
            searchSideTrailingConstraint.constant   =   -245
        }
        else {
            searchIndicatorImageView.transform  =   CGAffineTransform(rotationAngle: CGFloat(Double.pi))
            
            searchSideTrailingConstraint.constant   =   0
        }
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: self.view.layoutIfNeeded, completion: nil)
        
    }
    
    
    func drawMarker(_ location: CLLocation, isCurrent: Bool) {
        
        // Creates a marker in the center of the map.
        
        let marker = GMSMarker()
        marker.position = location.coordinate
        marker.title = isCurrent ? "Your Location" : nil
        marker.map = mapView

        
    }
    
    
    
    // MARK: - Search API
    
    func searchRequest() {
        
        let autocompleteURL = String(format: "https://maps.googleapis.com/maps/api/place/autocomplete/json?components=country:IN&input=%@&key=%@", keyword, Utilities.GlobalConstants.GOOGLE_PLACES_API_KEY)
        
        self.locSearchRequest = APIManager.sharedInstance().requestGooglePlaceApi(with: autocompleteURL!, webService: .placeAutocomplete, success: { (isSuccess, data) in
            
            if isSuccess {
                
                if let places = data as? [[String: AnyObject]] {
                    
                    print(places)
                    
                    // set places array the data
                    
                    searchResultVC.results = places
                    
                }
                else {
                    // set empty places array
                    
                    searchResultVC.results = []
                }
                
                
            }
            else {
                
                
//                if let message = data as? String {
//                    HolaAlert.showAlert(withTitle: "Holachef", msgBody: message, onVC: self)
//                }
                
                searchResultVC.results = []
                
                
            }
            
            
        }, failure: { (error) in
            
//            let error1 = error as NSError
            
//            if error1.code != NSURLErrorCancelled {
//                HolaNotification.failureOverlay(String.HolaMessage.ServerNotResponding, viewCtr: self)
//            }
            
        })
        
    }
    

}

// MARK: CLLocationManager Delegate

extension ViewController : CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let location = locations.last
        
        let camera = GMSCameraPosition.camera(withTarget: location!.coordinate, zoom: 6)
        self.mapView.animate(to: camera)
        
        drawMarker(location!, isCurrent: true)
        
        self.locationManager.stopUpdatingLocation()
        
    }
}

