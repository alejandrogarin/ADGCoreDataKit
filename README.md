# ADGCoreDataKit

A set of classes for easy to use CoreData

## Examples

### 1. Insert values into a CoreData Entity and populate a UITableViewController

Given this model

(Model.png)

This is the minimum amount of code to show the rows inserted in a table. This example doesn't need any NSManagedObject subclass

```swift

import UIKit

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
            println("----- get the array of managed object ----")
            let result:[NSManagedObject] = coreDataAccess.findObjectsByEntity("TableA")
            println(result)
            
            println("----- create an array of dictionary elements representing the retrieved managed objects ----")
            self.datasource = coreDataAccess.managedObjectsToDictionary(result)
            println(self.datasource)
            
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