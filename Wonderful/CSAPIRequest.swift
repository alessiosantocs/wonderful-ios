//
//  CSAPIRequest.swift
//  CinnamonSpark
//
//  Created by Alessio Santo on 26/03/15.
//  Copyright (c) 2015 Cinnamon. All rights reserved.
//

import UIKit
import AdSupport

class CSAPIRequest: AFHTTPRequestOperationManager {
    
    private let deviceUniqueIdentifier = ASIdentifierManager.sharedManager().advertisingIdentifier.UUIDString
    private let APIEndpoint : NSURL = NSURL(string: "http://wonderful-production.herokuapp.com")!
//    private let APIEndpoint : NSURL = NSURL(string: "http://192.168.1.12:3000")!
    
    private let APIPathDictionary : [String : String] = [
        "User" : "/users/:id.json",
        "Notification" : "/notifications/:id.json"
    ]

    func uniqueIdentifier() -> String{
        return self.deviceUniqueIdentifier
    }
    
    // default initiator with default base url
    init(){
        super.init(baseURL: self.APIEndpoint)
    }
    
    override init(baseURL url: NSURL!) {
        super.init(baseURL: url)
    }
    
    func getAPIPath(model: String) -> String{
        return self.getAPIPath(model, withRecordId: nil)
    }
    
    // Retrieves stuff from the dictionary and parses it
    func getAPIPath(model: String, withRecordId recordId: String?) -> String{
        var path : String = self.APIPathDictionary[model]!
        
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
    

    // MARK: - HTTP custom requests methods
    
    
    func getUserNotifications(success: ((AFHTTPRequestOperation!, AnyObject!) -> Void), failure: ((AFHTTPRequestOperation!, NSError!) -> Void)){
        let notificationsPath : String = self.getAPICombinedPath("User", withParentRecordId: self.uniqueIdentifier(), andModel: "Notification")
        
        self.GET(notificationsPath, parameters: [], success: success, failure: failure)
    }
    
    /** 
        Use the device UUID to authenticate the user.
        It will create a new user if the UUID is not found.
    */
    func checkCurrentUserInUsingDeviceUUID(){
        let userPath : String = self.getAPIPath("User")
        
        let zone = NSTimeZone.localTimeZone().secondsFromGMT / 60 / 60
        
        let params : NSDictionary = [
            "user": [
                "device_uuid": self.uniqueIdentifier(),
                "time_zone": zone.description
            ]
        ]
        
        self.POST(userPath,
            parameters: params,
            success: { (request: AFHTTPRequestOperation!, sender: AnyObject!) -> Void in
                println("User has been created/retrieved")
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
            },
            failure: { (request: AFHTTPRequestOperation!, error: NSError!) -> Void in
                println("Token has not been updated. Error: \(error)")
            }
        )
        

    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
