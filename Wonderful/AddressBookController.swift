//
//  AddressBookController.swift
//  Wonderful
//
//  Created by Alessio Santo on 28/04/15.
//  Copyright (c) 2015 Alessio Santo. All rights reserved.
//

import UIKit

class AddressBookController: UITableViewController, UISearchDisplayDelegate {

    var contacts            : [SwiftAddressBookPerson] = []
    var searchContacts      : [SwiftAddressBookPerson] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
         self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.Done, target: self, action: "closeAddressBook")
        
        self.searchDisplayController?.searchResultsTableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "addressBookPersonCellIdentifier")
        
        swiftAddressBook?.requestAccessWithCompletion({ (success, error) -> Void in
            if success {
                if let people = swiftAddressBook?.allPeople {
                    self.contacts = people
                    self.tableView.reloadData()
                }
            }
            else {
                // Say something
            }
        })
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func updateTitleAndDoneButton(){
        let count = self.selectedContacts().count
        
        if(count > 0){
            self.title = "Share with (\(count))"
            self.navigationItem.rightBarButtonItem?.title = "Send"
        }else{
            self.title = "Share with"
            self.navigationItem.rightBarButtonItem?.title = "Done"
        }
    }
    
    func closeAddressBook(){
        
        let count = self.selectedContacts().count
        
        if(count > 0){
            let p = (count > 1) ? "people" : "person"
            
            let successAlert = UIAlertController(title: "Yeah, sent!", message: "Your notification was successfully shared with \(count) \(p)", preferredStyle: UIAlertControllerStyle.Alert)
            
            let successAction = UIAlertAction(title: "Alright", style: UIAlertActionStyle.Default, handler: { (action: UIAlertAction!) -> Void in
                self.dismissViewControllerAnimated(true, completion: nil)
            })
            
            var selectedEmailsAndPhoneNumbers : [NSDictionary] = []
            for contact in self.selectedContacts(){
                var name = contact.compositeName
                var number = contact.phoneNumbers?.map( {$0.value} ).first
                var email = contact.emails?.map( {$0.value} ).first
                
                if(number == nil){
                    number = ""
                }
                
                if(email == nil){
                    email = ""
                }
                
                let dictionary : NSDictionary = [
                    "name": contact.compositeName!,
                    "phone_number": number!,
                    "email": email!
                ]
                
                selectedEmailsAndPhoneNumbers.append(dictionary)
            }
            
            CSAPIRequest().sendInvitationsToContactsArray(selectedEmailsAndPhoneNumbers, success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) -> Void in
                
            }, failure: { (operation: AFHTTPRequestOperation!, error: NSError!) -> Void in
                
            })
            
            
            successAlert.addAction(successAction)
            
            self.presentViewController(successAlert, animated: true, completion: nil)
        }else{
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        let search = self.searchDisplayController!
        if (search.active && self.searchContacts.count > 0) {
            return self.searchContacts.count
        } else {
            return self.contacts.count
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("addressBookPersonCellIdentifier", forIndexPath: indexPath) as! UITableViewCell

        // Configure the cell...
        
        var contact : SwiftAddressBookPerson!
        
        let search = self.searchDisplayController!
        if (search.active && self.searchContacts.count > 0) {
            contact = self.searchContacts[indexPath.row]
        } else {
            contact = self.contacts[indexPath.row]
        }
        
        if let name = contact.compositeName{
            cell.textLabel?.text = name
        }

        if let selected = contact.wf_selected{
            if(selected){
                cell.accessoryType = UITableViewCellAccessoryType.Checkmark
            }else{
                cell.accessoryType = UITableViewCellAccessoryType.None
            }
        }else{
            cell.accessoryType = UITableViewCellAccessoryType.None
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
        
        var contact : SwiftAddressBookPerson!
        
        let search = self.searchDisplayController!
        if (search.active && self.searchContacts.count > 0) {
            contact = self.searchContacts[indexPath.row]
            
            for realContact in self.contacts{
                if(realContact === contact){
                    contact = realContact
                }
            }
            
        } else {
            contact = self.contacts[indexPath.row]
        }

        // If the contact is already there. Remove it
        if let selected = contact.wf_selected{
            contact.wf_selected = !selected
        }else{
            contact.wf_selected = true
        }
        
        self.updateTitleAndDoneButton()
        tableView.reloadData()
    }

    func selectedContacts() -> [SwiftAddressBookPerson]{
        var contacts : [SwiftAddressBookPerson] = []
        
        for contact in self.contacts{
            if let selected = contact.wf_selected{
                if(selected){
                    contacts.append(contact)
                }
            }
        }
        
        return contacts
    }
    
    // MARK: - SearchDisplayDelegate methods
    
    func searchDisplayController(controller: UISearchDisplayController, shouldReloadTableForSearchString searchString: String!) -> Bool {
        self.filterAddressesForSearchText(searchString, scope: "")
        
        return true
    }
    
    func searchDisplayController(controller: UISearchDisplayController, didHideSearchResultsTableView tableView: UITableView) {
        self.tableView.reloadData()
    }

    /**
    This function filters the array with a given text.
    */
    func filterAddressesForSearchText(searchText: String, scope: String){
        self.searchContacts = []
        
        for contact in contacts{
            var shouldAdd = false
            
            if let name = contact.compositeName {
                if(name.rangeOfString(searchText) != nil){
                    shouldAdd = true
                }
            }
            
            if(shouldAdd){
                self.searchContacts.append(contact)
            }
        }
    }

    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

}


private var wf_selectedAssociationKey: UInt8 = 0
extension SwiftAddressBookPerson{
    var wf_selected : Bool? {
        get{
            return objc_getAssociatedObject(self, &wf_selectedAssociationKey) as? Bool
        }
        
        set{
            objc_setAssociatedObject(self, &wf_selectedAssociationKey, newValue, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN))
        }
    }

}

extension Array {
    mutating func removeObject <U: Equatable> (object: U) {
        for i in stride(from: self.count-1, through: 0, by: -1) {
            if let element = self[i] as? U {
                if element == object {
                    self.removeAtIndex(i)
                }
            }
        }
    }
}
