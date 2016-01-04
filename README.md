## Intro

#### Why did I create this library?

I wanted to use CoreData without exposing it to the application. Meaning that ViewControllers will not know anything about CoreData. I wanted CoreData to be simple.

#### So?

When creating, updating, deleting and finding objects I just want to see CoreData as a DAO with useful methods to interact with.
Once I have the data I can return DTOs or just simple dictionaries to the application.

#### How do I do that?

When writing the application I normally create an asyncronous data access layer, behind this layer I have a CoreData DAO that helps me to interact with the data.

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
At this point this is very similar of writing the server side module of your app, but in this case there is no server, just CoreData behind an interface.

## Content

TODO
