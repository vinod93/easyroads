//
//  APIManager.swift
//  EasyRoad-Assignment
//
//  Created by Holachef on 16/04/18.
//  Copyright © 2018 Vinod. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

enum GoogleWebService {
    case placeAutocomplete
    case placeDetails
}


typealias successHandler = ((Any) -> Void)
typealias failureHandler = ((Error) -> Void)

class APIManager {
    
    fileprivate static let _sharedInstance = APIManager()
    
    class func sharedInstance() -> APIManager {
        
        return _sharedInstance
    }
    
    func requestGooglePlaceApi(with url: String, webService: GoogleWebService, success: @escaping ((_ isSuccess: Bool, _ data: Any) -> Void), failure: @escaping failureHandler) {
        
        
        Alamofire.request(url, parameters: nil).responseJSON { response in
            
            if (response.result.isSuccess) {
                
                var json = JSON( response.result.value!)
                let status = json["status"].stringValue
                let message = json["error_message"].stringValue
                
                if status.uppercased() == "OK" {
                    
                    switch webService {
                    case .placeAutocomplete:
                        if let places  =   json["predictions"].arrayObject as? [[String: Any]] {
                            
                            success(true, places)
                        }
                        else {
                            // google search places nil
                            success(true, [])
                        }
                        
                    case .placeDetails:
                        
                        if let result   =   json["result"].dictionaryObject,
                            let geometry = result["geometry"] as? [String : Any],
                            let location = geometry["location"] as? [String : Any] {
                            
                            success(true, location)
                            
                        }
                        else {
                            
                            success(true, [:])
                        }
                    }
                    
                    
                    
                }
                else {
                    
                    success(false, message)
                    
                }
                
            }
            else {
                
                failure(response.result.error! as NSError)
                
            }
        }
        
    }

    
    
}
