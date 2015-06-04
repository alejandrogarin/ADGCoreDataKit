# ADGCoreDataKit

A set of classes for easy to use CoreData

## Examples

#### Without subclassing NSManagedObject

##### 1. Add a row and popuplate the UITableView

Given this model

![Example1](Model.png)

This is the minimum amount of code to show the rows inserted in a table. This example doesn't need any NSManagedObject subclass

```swift

import UIKit
import CoreData

class ViewController: UITableViewController {

    var datasource: [[String:Any]] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        println("----- create the core class ----")
        let coreData = CoreDataManager(usingModelName: "Model", error: nil)
        
        if let coreData = coreData {
            println("----- create the data access wrapper  ----")
            let coreDataAccess = CoreDataAccessImpl(usingCoreDataManager: coreData, concurrencyType: NSManagedObjectContextConcurrencyType.MainQueueConcurrencyType)

            println("----- insert some rows ----")
            for (var i=0; i < 10; i++) {
                let mo:NSManagedObject? = coreDataAccess.insert(entityName:"TableA", map: ["ta_field1":"value \(i)", "ta_field2":i], error: nil)
            }
            println("----- get the array of managed objects ----")
            let result:[NSManagedObject] = coreDataAccess.findObjectsByEntity("TableA")
            
            println("----- create an array of dictionary elements representing the retrieved managed objects ----")
            self.datasource = coreDataAccess.managedObjectsToDictionary(result)
            
            self.tableView.reloadData()
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.datasource.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCellWithIdentifier("aCell", forIndexPath: indexPath) as! UITableViewCell
        
        let dto: [String:Any] = self.datasource[indexPath.row]
        cell.textLabel?.text = (dto["ta_field1"] as! String)

        return cell;
    }
}

```

##### 2. Delete a row and update the UITableView

```swift

import UIKit
import CoreData

class ViewController: UITableViewController {

    let coreData = CoreDataManager(usingModelName: "Model", error: nil)
    
    var datasource: [[String:Any]] = []
    
    var dataAccess: CoreDataAccess? {
        get {
            println("----- get the core class ----")
            if let coreData = coreData {
                let coreDataAccess = CoreDataAccessImpl(usingCoreDataManager: coreData, concurrencyType: NSManagedObjectContextConcurrencyType.MainQueueConcurrencyType)
                return coreDataAccess
            } else {
                return nil
            }
        }
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
        
            println("----- delete the object from the store ----")
            self.deleteObject(self.datasource[indexPath.row][CoreDataAccessConstants.CORE_DATA_OBJECT_ID] as! String, atIndex: indexPath.row)
            
            println("----- update both the local datasource and the tableview ----")
            self.tableView.beginUpdates()
            self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
            self.datasource.removeAtIndex(indexPath.row)
            self.tableView.endUpdates()
        }
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func deleteObject(let objectId: String, atIndex: Int) {
        println("----- get the data access wrapper  ----")
        if let dataAccess = self.dataAccess {
            dataAccess.delete(objectId: objectId)
        }
    }
}

```
