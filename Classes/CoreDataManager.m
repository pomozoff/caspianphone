//
//  CoreDataManager.m
//  linphone
//
//  Created by Art on 5/18/15.
//
//

#import "CoreDataManager.h"

@interface CoreDataManager ()

@property (strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (strong, nonatomic) NSManagedObjectContext *rootContext;
@property (strong, nonatomic, readwrite) NSManagedObjectContext *mainContext;
@property (strong, nonatomic, readwrite) NSManagedObjectContext *backgroundContext;
@property (strong, nonatomic) NSManagedObjectModel *managedObjectModel;

@end

@implementation CoreDataManager

+ (CoreDataManager *)sharedManager
{
    static dispatch_once_t onceToken;
    static CoreDataManager *sharedInstance = nil;
    
    dispatch_once(&onceToken, ^{
        sharedInstance = [[CoreDataManager alloc] init];
    });
    
    return sharedInstance;
}

- (void)setupCoreData
{
    self.managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:[self modelURL]];
    self.persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
    
    NSURL *storeURL = [self storeURL];
    NSError *error = nil;
    
    if (![self.persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:[self persistentStoreCoordinatorOptions] error:&error]) {
        abort();
    }
    
    self.rootContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    self.rootContext.persistentStoreCoordinator = self.persistentStoreCoordinator;
    
    self.mainContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    self.mainContext.parentContext = self.rootContext;
    
    self.backgroundContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    self.backgroundContext.parentContext = self.mainContext;
}

#pragma mark - Create

- (NSManagedObject *)createManagedObject:(NSString *)entityName
{
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:self.backgroundContext];
    NSManagedObject *managedObject = [[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:self.backgroundContext];
    return managedObject;
}

#pragma mark - Save

- (void)saveContextSuccessBlock:(void(^)())successBlock
{
    __block CoreDataManager *blockSelf = self;
    [self.backgroundContext performBlock:^{
        [blockSelf.backgroundContext save:nil];
        [blockSelf.mainContext performBlock:^{
            [blockSelf.mainContext save:nil];
            [blockSelf.rootContext performBlock:^{
                [blockSelf.rootContext save:nil];
                if (successBlock) {
                    successBlock();
                }
            }];
        }];
    }];
}

#pragma mark - Retrieve

- (void)retrieveManagedObject:(NSString *)managedObjectName
                    predicate:(NSPredicate *)predicate
              sortDescriptors:(NSArray *)sortDescriptors
                 successBlock:(void(^)(NSArray *retrievedObjects))successBlock
{
    __block CoreDataManager *blockSelf = self;
    [self.mainContext performBlock:^{
        NSEntityDescription *entity = [NSEntityDescription entityForName:managedObjectName inManagedObjectContext:blockSelf.mainContext];
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        fetchRequest.entity = entity;
        fetchRequest.returnsObjectsAsFaults = NO;
        if (sortDescriptors.count > 0) {
            fetchRequest.sortDescriptors = sortDescriptors;
        }
        
        if (predicate) {
            fetchRequest.predicate = predicate;
        }
        
        NSError *error = nil;
        NSArray *fetchedObjectsFromBackgroundContext = [blockSelf.mainContext executeFetchRequest:fetchRequest error:&error];
        
        if (successBlock) {
            successBlock(fetchedObjectsFromBackgroundContext);
        }
    }];
}

- (NSFetchedResultsController *)fetchedResultsControllerWithEntityName:(NSString *)className
                                                             predicate:(NSPredicate *)predicate
                                                   sortDescriptorArray:(NSArray *)sortDescriptorArray
                                                 andSectionNameKeyPath:(NSString *)sectionNameKeyPath
{
    [NSFetchedResultsController deleteCacheWithName:nil];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:className inManagedObjectContext:self.mainContext];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:predicate];
    [fetchRequest setSortDescriptors:sortDescriptorArray];
    return [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.mainContext sectionNameKeyPath:sectionNameKeyPath cacheName:nil];
}

#pragma mark - Delete

- (void)deleteManagedObject:(id)managedObject
{
    [self.backgroundContext deleteObject:managedObject];
}

- (void)tearDownCoreData
{
    self.rootContext = nil;
    self.mainContext = nil;
    self.backgroundContext = nil;
    self.managedObjectModel = nil;
    NSPersistentStore *store = [[[self persistentStoreCoordinator] persistentStores] lastObject];
    NSURL *storeURL = store.URL;
    if ([self.persistentStoreCoordinator removePersistentStore:store error:nil]) {
        NSError *error;
        self.persistentStoreCoordinator = nil;
        if (![[NSFileManager defaultManager] removeItemAtPath:storeURL.path error:&error]) {
            if (error) {
                NSLog(@"Error deleting core data objects");
            }
        }
    }
}

#pragma mark - Other methods

- (NSURL *)modelURL
{
    return [[NSBundle mainBundle] URLForResource:@"SMS" withExtension:@"momd"];
}

- (NSURL *)storeURL
{
    return [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"SMS.sqlite"];
}

- (NSDictionary *)persistentStoreCoordinatorOptions
{
    return @{ NSMigratePersistentStoresAutomaticallyOption : @YES,
              NSInferMappingModelAutomaticallyOption : @YES };
}

- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
