## Intro

#### What is the purpose of this library?

The idea is to simplify how you can use CoreData by not exposing it to the application, meaning that ViewController/s will not know anything about CoreData objects, contexts or stores.

##### ok, continue...

When creating, updating, deleting and finding objects you will see CoreData as a DAO with useful methods to interact with.
Once you have the data return DTOs or just simple dictionaries to the application.

#### How can I do that?

One option is creating an asyncronous data access layer and behind this layer you have a CoreData DAO that helps you to interact with the data.  This is exactly what you do when interacting with a remote rest service, you have an asyncronous call that returns data, right?

#### Quick example?

```swift

// without subclassing NSManagedObject

class ManagedObjectDAO: CoreDataDAO<NSManagedObject> {
}

let managedObject = try dao.insert(entityName: "Car", map: ["name": "Mercedes"])
let cars = try dao.findObjectsByEntity("Car", withSortKey: "name")
try self.dao.delete(object: managedObject)

// subclassing NSManagedObject

class ManagedObjectDAO: CoreDataDAO<Car> {
}

let car: Car = try self.dao.insert(map: ["name": "Mercedes"])
let cars = try dao.findObjectsByEntity(sortKey: "name")
try self.dao.delete(object: car)

```

#### What should I do next?

The data access layer will have some methods with input parameters (or DTOs) and probably will return DTOs in response. 
This is specific to your application but I usually create DTOs representations of my database model and return that information to the app depending of the method that is being called.
At this point this is very similar of writing the server side module of your app, but in this case there is no server, just CoreData behind an interface. Simple example:

```swift
class Service {
    func addCarWithName(name: String, success: (car: CarDTO) -> Void, failure: (error: NSError) -> Void) {
        do {
        	let newCar = try self.dao.insert(entityName: "Car", map: ["name": name])
            success(car: CarDTO(fromManagedObject(newCar)))
        } catch let error as NSError {
            failure(error: error)
        }    
    }
}
```

#### Can I use it in my ViewController/s anyway?

Yes!


## Content

TODO
