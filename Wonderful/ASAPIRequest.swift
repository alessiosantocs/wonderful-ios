//
//  ASAPIRequest.swift
//  Handles most of the common network operations for you
//
//  Created by Alessio Santo on 26/03/15.
//  Copyright (c) 2015 Cinnamon. All rights reserved.
//

import UIKit
import AdSupport

class ASAPIRequest: AFHTTPRequestOperationManager, ASAPIRequestInterface {
    
    /** The key to store the user id received from the server */
    private let userIdDefaultsKey = "user_id_defaults_key"
    
    private let deviceUniqueIdentifier = ASIdentifierManager.sharedManager().advertisingIdentifier.UUIDString
    
    // MARK: - Initializers
    init(){
        super.init(baseURL: NSURL())
    }
    
    override init(baseURL url: NSURL!) {
        super.init(baseURL: url)
    }
    
    
    // MARK: - Interface functions
    
    func APIPathDictionary() -> [String : String] {
        return [
            "User" : "/users/:id.json"
        ]
    }
    
    // MARK: - Utility Functions
    func uniqueIdentifier() -> String{
        
        if let userId = self.defaultsUserId(){
            return userId
        }
        
        return self.deviceUniqueIdentifier
    }
    
    private func defaultsUserId() -> String?{
        let string = NSUserDefaults.standardUserDefaults().objectForKey(self.baseURL.description + self.userIdDefaultsKey) as? String
        return string
    }
    
    private func defaultsUserId(userId: String){
        NSUserDefaults.standardUserDefaults().setObject(userId, forKey: self.baseURL.description + self.userIdDefaultsKey)
    }
    
    func getAPIPath(model: String) -> String{
        return self.getAPIPath(model, withRecordId: nil)
    }
    
    // Retrieves stuff from the dictionary and parses it
    func getAPIPath(model: String, withRecordId recordId: String?) -> String{
        var path : String = self.APIPathDictionary()[model]!
        
        if recordId != nil{
            path = path.stringByReplacingOccurrencesOfString(":id", withString: recordId!)
        }else{
            path = path.stringByReplacingOccurrencesOfString("/:id", withString: "")
        }
        
        return path
    }
    
    func getAPICombinedPath(parentModel: String, withParentRecordId parentRecordId: String, andModel model: String) -> String{
        var path : String = self.getAPIPath(parentModel, withRecordId: parentRecordId)
        var appendPath : String = self.getAPIPath(model)
        
        path = path.stringByReplacingOccurrencesOfString(".json", withString: appendPath)
        
        return path
    }
    
    func getAPICombinedPath(parentModel: String, withParentRecordId parentRecordId: String, andModel model: String, withRecordId recordId: String?) -> String{
        var path : String = self.getAPIPath(parentModel, withRecordId: parentRecordId)
        var appendPath : String = self.getAPIPath(model, withRecordId: recordId)
        
        path = path.stringByReplacingOccurrencesOfString(".json", withString: appendPath)
        
        return path
    }
    
    
    // MARK: - User authentication methods
    
    /**
    Use the device UUID to authenticate the user.
    It will create a new user if the UUID is not found.
    */
    func checkCurrentUserInUsingDeviceUUID(success: ((AFHTTPRequestOperation!, AnyObject!) -> Void)?){
        let userPath : String = self.getAPIPath("User")
        
        let zone = NSTimeZone.localTimeZone().secondsFromGMT / 60 / 60
        
        var params : NSDictionary!
        
        // Already have an id in the defaults
        if let userId = self.defaultsUserId(){
            println("Already have an id \(userId)")
            params = [
                "user": [
                    "id": self.uniqueIdentifier(),
                    "device_uuid": self.deviceUniqueIdentifier,
                    "time_zone": zone.description
                ]
            ]
            
        }else{
            params = [
                "user": [
                    "device_uuid": self.uniqueIdentifier(),
                    "time_zone": zone.description
                ]
            ]
        }
        
        self.POST(userPath,
            parameters: params,
            success: { (request: AFHTTPRequestOperation!, responseObject: AnyObject!) -> Void in
                let userDictionary = responseObject as! NSDictionary
                
                if let userId = userDictionary["id"] as? Int{
                    // Set user defaults
                    self.defaultsUserId(userId.description)
                }
                
                // Call the given block
                if let callback = success{
                    callback(request, responseObject)
                }
                
            },
            failure: { (request: AFHTTPRequestOperation!, error: NSError!) -> Void in
                println("Error in api")
                //                fatalError("Fix this!")
            }
        )
        
    }
    
    /**
    Save the currentUser's remote notification token on the server.
    
    :param: deviceToken The token received from the AppDelegate.
    */
    
    private var updateTokenRetrials = 0
    func updateCurrentUserNotificationToken(deviceToken : NSData){
        
        var plainToken = deviceToken.description.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: "<>"))
        plainToken = plainToken.stringByReplacingOccurrencesOfString(" ", withString: "")
        
        let userPath : String = self.getAPIPath("User", withRecordId: self.uniqueIdentifier())
        
        let params : NSDictionary = [
            "user": [
                "push_notification_token": plainToken
            ]
        ]
        
        self.PUT(userPath,
            parameters: params,
            success: { (request: AFHTTPRequestOperation!, sender: AnyObject!) -> Void in
                println("Token has been updated")
                self.updateTokenRetrials = 0
            },
            failure: { (request: AFHTTPRequestOperation!, error: NSError!) -> Void in
                println("Error when updating the token: \n \(error)")
                
                if(self.updateTokenRetrials < 5){
                    self.updateTokenRetrials++
                    self.updateCurrentUserNotificationToken(deviceToken)
                }
            }
        )
        
        
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}



protocol ASAPIRequestInterface{
    func APIPathDictionary() -> [String : String]
}