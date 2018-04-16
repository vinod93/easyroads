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
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    var currentLocation : CLLocation? {
        didSet {
            drawMarker(currentLocation!, isCurrent: true)
        }
    }
    
    var destinationLocation: CLLocation? {
        didSet {
            drawMarker(destinationLocation!, isCurrent: false)
        }
    }
    
    var destinationMarker : GMSMarker?
    var polyline = GMSPolyline()
    
    var locations : [[String:Any]] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchSideTrailingConstraint.constant   =   -255
        
        let camera = GMSCameraPosition.camera(withLatitude: -33.86, longitude: 151.20, zoom: 6.0)
        mapView = GMSMapView.map(withFrame: self.view.bounds, camera: camera)
        mapView.isMyLocationEnabled =   true
        view.addSubview(mapView)
        
        
        locationManager.delegate    =   self
        locationManager.startUpdatingLocation()
        
        self.view.sendSubview(toBack: mapView)
        
        
        searchBar.delegate  =   self
    }
    
    
    @IBAction func searchTapped(_ sender: UIButton) {
        
        toggleSidePanel()
        
    }
    
    func toggleSidePanel() {
        
        if searchSideTrailingConstraint.constant == 0 {
            searchIndicatorImageView.transform  =   CGAffineTransform(rotationAngle: 0)
            searchSideTrailingConstraint.constant   =   -255
        }
        else {
            searchIndicatorImageView.transform  =   CGAffineTransform(rotationAngle: CGFloat(Double.pi))
            
            searchSideTrailingConstraint.constant   =   0
        }
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: self.view.layoutIfNeeded, completion: nil)
        
    }
    
    
    func drawMarker(_ location: CLLocation, isCurrent: Bool) {
        
        // Creates a marker in the center of the map.
        
        
        if isCurrent {
            let marker  =   GMSMarker()
            marker.position = location.coordinate
            marker.title = isCurrent ? "Your Location" : nil
            marker.map = mapView
        }
        else {
            destinationMarker = destinationMarker == nil ? GMSMarker() : destinationMarker
            destinationMarker?.position = location.coordinate
            destinationMarker?.map = mapView
        }
        
        

        
    }
    
    
    
    // MARK: - Search API
    
    func searchRequest(keyword: String) {
        
        let autocompleteURL = String(format: "https://maps.googleapis.com/maps/api/place/autocomplete/json?components=country:IN&input=%@&key=%@", keyword, Utilities.GlobalConstants.GOOGLE_API_KEY)
        
        APIManager.sharedInstance().requestGooglePlaceApi(with: autocompleteURL, webService: .placeAutocomplete, success: { (isSuccess, data) in
            
            if isSuccess, let places = data as? [[String: Any]] {
                    
                    print(places)
                    
                    // set places array the data
                self.locations = places
                self.tableView.reloadData()
                
            }
            else {
                
                self.locations = []
                self.tableView.reloadData()
                
            }
            
            
        }, failure: { (error) in
            self.locations = []
            self.tableView.reloadData()
        })
        
    }
    
    
    
    
    
    func requestPlaceCoordinatesFor(_ placeid: String, completion: @escaping ((_ isSuccess: Bool, _ location: [String : Any]) -> Void))  {
        
        let placeDetailURL    =   String(format: "https://maps.googleapis.com/maps/api/place/details/json?placeid=%@&key=%@", placeid, Utilities.GlobalConstants.GOOGLE_API_KEY)
        
        
        APIManager.sharedInstance().requestGooglePlaceApi(with: placeDetailURL, webService: .placeDetails, success: { (isSuccess, data) in
            
            if isSuccess, let location = data as? [String: Any] {
                
                
                completion(true, location)
                
            }
            else {
                
                completion(false, [:])
            }
            
            
        }, failure: { (error) in
            
            completion(false, [:])
        })
    }
    
    
    func drawDirections() {
        
        let origin = "\(currentLocation!.coordinate.latitude),\(currentLocation!.coordinate.longitude)"
        let destination = "\(destinationLocation!.coordinate.latitude),\(destinationLocation!.coordinate.longitude)"
        
        let urlString = "https://maps.googleapis.com/maps/api/directions/json?origin=\(origin)&destination=\(destination)&mode=driving&key=\(Utilities.GlobalConstants.GOOGLE_API_KEY)"

        Alamofire.request(urlString).responseJSON { (response) in
            
            switch response.result {
                
            case .success(let value):
                
                let json = JSON(value)
                
                let routes  =   json["routes"].array!
                
                for route in routes
                {
                    let routeOverviewPolyline = route["overview_polyline"].dictionaryObject!
                    let points = routeOverviewPolyline["points"] as! String
                    let path = GMSPath.init(fromEncodedPath: points)
                    self.polyline.path  =   path //= GMSPolyline.init(path: path)
                    self.polyline.strokeWidth = 3
                    
                    let bounds = GMSCoordinateBounds(path: path!)
                    self.mapView!.animate(with: GMSCameraUpdate.fit(bounds, withPadding: 30.0))
                    
                    self.polyline.map = self.mapView
                    
                }
                
                
            case .failure(_):
                break
            }
            
        }
        
    }

}

// MARK: CLLocationManager Delegate

extension ViewController : CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let location = locations.last
        
        let camera = GMSCameraPosition.camera(withTarget: location!.coordinate, zoom: 6)
        self.mapView.animate(to: camera)
        
        currentLocation =   location
        
        self.locationManager.stopUpdatingLocation()
        
    }
}

extension ViewController : UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchRequest(keyword: searchText)
    }
    
}

extension ViewController : UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return locations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "locationCell", for: indexPath)
        let result      =   locations[indexPath.row]
        
        cell.textLabel?.text    =   result["description"] as? String
        
        return cell
    }
    
}

extension ViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let heading    =   UILabel(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 44))
        
        heading.text    =   "    LOCATIONS:"
        heading.textColor   =   UIColor.lightGray
        heading.font        =   UIFont(name: "AppleSDGothicNeo-Regular", size: 15)
        
        return heading
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let result = locations[indexPath.row]
        
        if let placeid     =   result["place_id"] as? String {
            
            self.requestPlaceCoordinatesFor(placeid, completion: { (isSuccess, location) in
                
                if isSuccess {
                    
                    let lat     =   location["lat"] as? Double
                    let lng     =   location["lng"] as? Double
                    
                    let coordinates =   CLLocation(latitude: lat!, longitude: lng!)
                    
                    
                    self.toggleSidePanel()
                    
                    self.destinationLocation =   coordinates
                    
                    self.drawDirections()
                }
                
            })
        }
    }
}
