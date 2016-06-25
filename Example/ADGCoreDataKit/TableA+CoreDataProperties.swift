//
//  TableA+CoreDataProperties.swift
//  
//
//  Created by Alejandro Garin on 6/23/16.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension TableA {

    @NSManaged var ta_field1: String?
    @NSManaged var ta_field2: NSNumber?

}
