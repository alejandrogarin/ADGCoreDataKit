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
            if let tableObject = self.dao.create() as? TableA {
                tableObject.ta_field1 = "value \(i)"
                tableObject.ta_field2 = NSNumber(value: i)
            }
        }
        
        try! self.dao.commit()

        self.datasource = try! self.dao.find()
        
        self.tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.datasource.count
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCellEditingStyle.delete {
            try! self.delete(self.datasource[(indexPath as NSIndexPath).row])

            self.tableView.beginUpdates()
            self.tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.fade)
            self.datasource.remove(at: (indexPath as NSIndexPath).row)
            self.tableView.endUpdates()
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func delete(_ table: TableA) throws {
        try self.dao.delete(managedObject: table)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "aCell", for: indexPath) as UITableViewCell
        
        let aTable = self.datasource[(indexPath as NSIndexPath).row]
        cell.textLabel?.text = (aTable.ta_field1)
        
        return cell;
    }
}

