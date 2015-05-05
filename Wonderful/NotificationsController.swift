//
//  ViewController.swift
//  Wonderful
//
//  Created by Alessio Santo on 19/04/15.
//  Copyright (c) 2015 Alessio Santo. All rights reserved.
//

import UIKit

class NotificationsController: UITableViewController {

    var notifications : [NSDictionary] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
//        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "NotificationCell")
        
        // Initialize refresh control for table viw
        self.refreshControl = UIRefreshControl()
        
        self.refreshControl?.addTarget(self, action: "loadNotifications:", forControlEvents: UIControlEvents.ValueChanged)
        
        self.tableView?.addSubview(self.refreshControl!)
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 88.0
        
//        self.tryAndOpenAddressBook()

    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.loadNotifications(nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loadNotifications(refreshControl: UIRefreshControl?){
        if(refreshControl == nil){
            self.refreshControl?.beginRefreshing()
        }
        
        CSAPIRequest().getUserNotifications(self.handleSuccessAPIRequest, failure: self.handleFailureAPIRequest)
    }

    func handleSuccessAPIRequest(operation: AFHTTPRequestOperation!, responseObject: AnyObject!){
        self.notifications = responseObject as! [NSDictionary]
        
        self.tableView.reloadData()
        
        self.refreshControl?.endRefreshing()
    }
    
    func handleFailureAPIRequest(operation: AFHTTPRequestOperation!, error: NSError!){
        println(error)
        self.refreshControl?.endRefreshing()
    }
    
    
    // MARK: - Table view data source
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if(self.notifications.count > 0){
            tableView.separatorStyle = UITableViewCellSeparatorStyle.SingleLine
            tableView.backgroundView = nil
            
            return 1
        }else{
            let noDataLabel = UILabel(frame: CGRectMake(0,0, self.view.frame.width, self.view.frame.height))
            
            noDataLabel.text = "Next notification at 8am"
            noDataLabel.numberOfLines = 0
            noDataLabel.textAlignment = NSTextAlignment.Center
            noDataLabel.textColor = UIColor.grayColor()
            noDataLabel.sizeToFit()
            
            tableView.backgroundView = noDataLabel
            
            tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        }
        
        return 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("NotificationCell", forIndexPath: indexPath) as! NotificationCell
        
        let notification = self.notifications[indexPath.row]
        let userNotification = notification["user_notification"] as! NSDictionary
        let isLoved = userNotification["is_loved"] as! Bool
        
        if(isLoved){
            cell.favoritedIcon.hidden = false
        }else{
            cell.favoritedIcon.hidden = true
        }
        
        cell.messageLabel?.text = notification["message"] as? String
        cell.messageLabel?.lineBreakMode = NSLineBreakMode.ByWordWrapping
        
        return cell
    }
    
    
//    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
//        
//        let notification = self.notifications[indexPath.row]
//        
//        let font = UIFont.systemFontOfSize(15)
//        
//        let text : NSString = (notification["message"] as? NSString)!
//        
//        let rect = text.boundingRectWithSize(
//            CGSizeMake(self.tableView.frame.size.width, 200),
//            options: (NSStringDrawingOptions.UsesLineFragmentOrigin | NSStringDrawingOptions.UsesFontLeading),
//            attributes: [NSFontAttributeName : font.fontName],
//            context: NSStringDrawingContext())
//        let height = rect.size.height
//        
//        return height
//    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.notifications.count
    }
    
    
    // MARK: - Table view actions on cells

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let notification = self.notifications[indexPath.row]
        let userNotification = notification["user_notification"] as! NSDictionary
        let isLoved = userNotification["is_loved"] as! Bool
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        let alertView = UIAlertController(title: "Do something about it, will you?", message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)

        
        // Stay tuned alert
        let stayTunedAlert = UIAlertController(title: "I'd love to do that too!", message: "This cool feature is going to be\nin the next Wonderful release.\nStay tuned for updates.", preferredStyle: UIAlertControllerStyle.Alert)
        
        let stayCoolAction = UIAlertAction(title: "Cool!", style: UIAlertActionStyle.Cancel, handler: nil)
        
        stayTunedAlert.addAction(stayCoolAction)
        // End stay tuned alert

        
        let mainAction = UIAlertAction(title: "Share it", style: UIAlertActionStyle.Default) { (action: UIAlertAction!) -> Void in
            self.tryAndOpenAddressBook()
        }
        let secondaryAction = UIAlertAction(title: (isLoved) ? "Unlove" : "Love", style: UIAlertActionStyle.Default) { (action: UIAlertAction!) -> Void in
            self.loveUserNotificationOfNotificationAtIndexPath(indexPath)
        }
        let optionalAction = UIAlertAction(title: "Send again", style: UIAlertActionStyle.Default) { (action: UIAlertAction!) -> Void in
            self.presentViewController(stayTunedAlert, animated: true, completion: nil)
        }
        let cancelAction = UIAlertAction(title: "Nevermind", style: UIAlertActionStyle.Cancel, handler: nil)
        
        alertView.addAction(mainAction)
        alertView.addAction(secondaryAction)
//        alertView.addAction(optionalAction)
        alertView.addAction(cancelAction)
        
        self.presentViewController(alertView, animated: true, completion: nil)
    }
    
    
    func tryAndOpenAddressBook(){
        swiftAddressBook?.requestAccessWithCompletion({ (success, error) -> Void in
            if success {
                self.performSegueWithIdentifier("addressBookModalSegue", sender: self)
            }
            else {
                // Say something
            }
        })
    }
    
    
    
    func loveUserNotificationOfNotificationAtIndexPath(indexPath: NSIndexPath){
        
        let notification = self.notifications[indexPath.row]
        
        if let userNotification = notification["user_notification"] as? NSDictionary{
            let userNotificationId = (userNotification["id"] as! Int).description
            
            if let isLoved = userNotification["is_loved"] as? Bool{
                if(isLoved){
                    CSAPIRequest().unloveUserNotificationWithId(userNotificationId, success: self.handleSuccessLoveUserNotificationRequest, failure: self.handleFailureLoveUserNotificationRequest)
                }else{
                    CSAPIRequest().loveUserNotificationWithId(userNotificationId, success: self.handleSuccessLoveUserNotificationRequest, failure: self.handleFailureLoveUserNotificationRequest)
                }
            }
            
        }
    }
    
    func handleSuccessLoveUserNotificationRequest(operation: AFHTTPRequestOperation!, responseObject: AnyObject!){
        self.loadNotifications(self.refreshControl!)
    }

    func handleFailureLoveUserNotificationRequest(operation: AFHTTPRequestOperation!, error: NSError!){
        self.loadNotifications(self.refreshControl!)
    }
}

