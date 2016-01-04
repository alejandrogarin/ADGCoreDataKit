//
//  ViewController.swift
//  CoreDataKitExample
//
//  Created by Alejandro Diego Garin on 5/20/15.
//  Copyright (c) 2015 ADG. All rights reserved.
//

import UIKit
import CoreData
import ADGCoreDataKit

class ManagedObjectDAO: CoreDataDAO<NSManagedObject> {
    override init(usingContext context: CoreDataContext) {
        super.init(usingContext: context)
    }
}

class ViewController: UITableViewController {
    
    var coreData:CoreDataManager!
    var datasource: [[String:Any]] = []
    var dao: ManagedObjectDAO!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.coreData = CoreDataManager(usingModelName: "Model")
        try! self.coreData.setupCoreDataStack()
        let context = CoreDataContext(usingPersistentStoreCoordinator: self.coreData.persistentStoreCoordinator!, concurrencyType: NSManagedObjectContextConcurrencyType.MainQueueConcurrencyType)
        
        self.dao = ManagedObjectDAO(usingContext: context)
        
        print("----- empty the table ----")
        try! self.dao.truncate("TableA")
        
        print("----- insert some rows ----")
        for (var i=0; i < 10; i++) {
            try! self.dao.insert(entityName:"TableA", map: ["ta_field1":"value \(i)", "ta_field2":i])
        }
        print("----- get the array of managed object ----")
        let result = try! self.dao.findObjectsByEntity("TableA")
        print(result)
        
        print("----- create an array of dictionary elements representing the retrieved managed objects ----")
        self.datasource = self.dao.managedObjectsToDictionary(result)
        print(self.datasource)
                
        self.tableView.reloadData()
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.datasource.count
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            
            print("----- delete the object from the store ----")
            try! self.deleteObject(self.datasource[indexPath.row][CoreDataKitKeys.ObjectId.rawValue] as! String, atIndex: indexPath.row)
            print("----- update both the local datasource and the tableview ----")
            self.tableView.beginUpdates()
            self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
            self.datasource.removeAtIndex(indexPath.row)
            self.tableView.endUpdates()
        }
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func deleteObject(let objectId: String, atIndex: Int) throws {
        try self.dao.delete(objectId: objectId)
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("aCell", forIndexPath: indexPath) as UITableViewCell
        
        let dto: [String:Any] = self.datasource[indexPath.row]
        cell.textLabel?.text = (dto["ta_field1"] as! String)
        
        return cell;
    }
}

