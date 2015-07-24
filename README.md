# ADGCoreDataKit

## Requirement

Swift 2.0 SDK beta 4

A set of classes for easy to use CoreData

## Examples

#### Without subclassing NSManagedObject

##### 1. Add a row and popuplate the UITableView

Given this model

![Example1](Model.png)

This is the minimum amount of code to show the rows inserted in a table. This example doesn't need any NSManagedObject subclass

```swift

class ManagedObjectDAO: CoreDataDAO<NSManagedObject> {
    override init(usingContext context: CoreDataContext) {
        super.init(usingContext: context)
    }
}

class ViewController: UITableViewController {

    var coreData:CoreDataManager?
    var datasource: [[String:Any]] = []
    var dao: ManagedObjectDAO!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.coreData = try! CoreDataManager(usingModelName: "Model")
        let context = CoreDataContext(usingPersistentStoreCoordinator: self.coreData!.persistentStoreCoordinator, concurrencyType: NSManagedObjectContextConcurrencyType.MainQueueConcurrencyType)
        
        self.dao = ManagedObjectDAO(usingContext: context)
        
        print("----- empty the table ----")
        try! self.dao.truncate("TableA")
        
        print("----- insert some rows ----")
        for (var i=0; i < 10; i++) {
            try! self.dao.insert(entityName:"TableA", map: ["ta_field1":"value \(i)", "ta_field2":i])
        }
        print("----- get the array of managed object ----")
        let result = try! self.dao.findObjectsByEntity("TableA")
        
        print("----- create an array of dictionary elements representing the retrieved managed objects ----")
        self.datasource = self.dao.managedObjectsToDictionary(result)
        
        self.tableView.reloadData()
    }
}

```

#### Subclassing NSManagedObject

TODO
