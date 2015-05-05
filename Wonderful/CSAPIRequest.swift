//
//  CSAPIRequest.swift
//  CinnamonSpark
//
//  Created by Alessio Santo on 26/03/15.
//  Copyright (c) 2015 Cinnamon. All rights reserved.
//

import UIKit

class CSAPIRequest: ASAPIRequest {

    // Endpoints
    private let apiEndpoint : NSURL = NSURL(string: "http://wonderful-production.herokuapp.com")!
//    private let apiEndpoint : NSURL = NSURL(string: "http://192.168.1.223:3000")!
    
    override init() {
        super.init(baseURL: apiEndpoint)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Interface methods
    
    override func APIPathDictionary() -> [String : String] {
        return [
            "User"              : "/users/:id.json",
            "UserNotification"  : "/user_notifications/:id.json",
            "Notification"      : "/notifications/:id.json",
            "Invitation"        : "/invitations/:id.json"
        ]
    }
    
    // MARK: - HTTP custom requests methods
    
    
    func getUserNotifications(success: ((AFHTTPRequestOperation!, AnyObject!) -> Void), failure: ((AFHTTPRequestOperation!, NSError!) -> Void)){
        let notificationsPath : String = self.getAPICombinedPath("User", withParentRecordId: self.uniqueIdentifier(), andModel: "Notification")

        self.GET(notificationsPath, parameters: [], success: success, failure: failure)
    }
    
    // Love a notification
    
    /**
        This method updates the field loved_at of a user_notification record. 
        Pass 1 to set it as loved, pass 0 to set it as unloved.
    */
    func updateLovedAtNotificationWithValueWithId(id: String, andValue value: Int, success: ((AFHTTPRequestOperation!, AnyObject!) -> Void), failure: ((AFHTTPRequestOperation!, NSError!) -> Void)){
        let userNotificationsPath : String = self.getAPICombinedPath("User", withParentRecordId: self.uniqueIdentifier(), andModel: "UserNotification", withRecordId: id)
        
        let params = [
            "user_notification":[
                "loved_at": value
            ]
        ]

        self.PUT(userNotificationsPath, parameters: params, success: success, failure: failure)
    }
    
    /**
        Shortcut method to love a user_notification record.
    */
    func loveUserNotificationWithId(id: String, success: ((AFHTTPRequestOperation!, AnyObject!) -> Void), failure: ((AFHTTPRequestOperation!, NSError!) -> Void)){
        self.updateLovedAtNotificationWithValueWithId(id, andValue: 1, success: success, failure: failure)
    }
    
    /**
        Shortcut method to un-love a user_notification record.
    */
    func unloveUserNotificationWithId(id: String, success: ((AFHTTPRequestOperation!, AnyObject!) -> Void), failure: ((AFHTTPRequestOperation!, NSError!) -> Void)){
        self.updateLovedAtNotificationWithValueWithId(id, andValue: 0, success: success, failure: failure)
    }
    
    /**
        Sends invitations to comtacts emails or phone numbers.
    */
    func sendInvitationsToContactsArray(array: [NSDictionary], success: ((AFHTTPRequestOperation!, AnyObject!) -> Void), failure: ((AFHTTPRequestOperation!, NSError!) -> Void)){
        let invitationsPath = self.getAPIPath("Invitation", withRecordId: nil)
        
        let params : NSDictionary = [
            "contacts": array
        ]
        
        self.POST(invitationsPath, parameters: params, success: success, failure: failure)
    }
    
}
