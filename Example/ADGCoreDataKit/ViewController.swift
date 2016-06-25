import UIKit
import CoreData
import ADGCoreDataKit

class ViewController: UITableViewController {
    
    var coreData:CoreDataManager!
    var datasource: [TableA] = []
    var dao: CoreDataGenericDAO<TableA>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.coreData = CoreDataManager(usingModelName: "Model", useInMemoryStore: true)
        try! self.coreData.setupCoreDataStack()
        let context = self.coreData.makeContext(associateWithMainQueue: true)
        
        self.dao = CoreDataGenericDAO<TableA>(usingContext: context, forEntityName: "TableA")
        
        for i in 0..<10 {
            try! self.dao.insert(withMap: ["ta_field1":"value \(i)", "ta_field2":i])
        }

        self.datasource = try! self.dao.find()
        
        self.tableView.reloadData()
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.datasource.count
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            try! self.delete(self.datasource[indexPath.row])

            self.tableView.beginUpdates()
            self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
            self.datasource.removeAtIndex(indexPath.row)
            self.tableView.endUpdates()
        }
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func delete(table: TableA) throws {
        try self.dao.delete(managedObject: table)
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("aCell", forIndexPath: indexPath) as UITableViewCell
        
        let aTable = self.datasource[indexPath.row]
        cell.textLabel?.text = (aTable.ta_field1)
        
        return cell;
    }
}

