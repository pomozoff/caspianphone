//
//  CoreDataManager.h
//  linphone
//
//  Created by Art on 5/18/15.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface CoreDataManager : NSObject

@property (strong, nonatomic, readonly) NSManagedObjectContext *mainContext;
@property (strong, nonatomic, readonly) NSManagedObjectContext *backgroundContext;

+ (CoreDataManager *)sharedManager;

- (void)setupCoreData;


- (NSManagedObject *)createManagedObject:(NSString *)entityName;

- (void)saveContextSuccessBlock:(void(^)())successBlock;

- (void)retrieveManagedObject:(NSString*)managedObjectName
                    predicate:(NSPredicate *)predicate
              sortDescriptors:(NSArray *)sortDescriptors
                 successBlock:(void(^)(NSArray *retrievedObjects))successBlock;

- (NSFetchedResultsController *)fetchedResultsControllerWithEntityName:(NSString *)className
                                                             predicate:(NSPredicate *)predicate
                                                   sortDescriptorArray:(NSArray *)sortDescriptorArray
                                                 andSectionNameKeyPath:(NSString *)sectionNameKeyPath;

- (void)deleteManagedObject:(id)managedObject;

- (void)tearDownCoreData;

@end
