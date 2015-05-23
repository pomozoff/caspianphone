//
//  SMSTableViewController.m
//  linphone
//
//  Created by Art on 5/18/15.
//
//

#import "SMSTableViewController.h"
#import "SMSConversationViewController.h"
#import "SMSTableViewCell.h"
#import "CoreDataManager.h"
#import "PhoneMainView.h"
#import "Conversation.h"
#import "Message.h"

#import "LinphoneUI/UIChatCell.h"

@interface SMSTableViewController () <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) UITableView *tableView;

@end

@implementation SMSTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.contentInset = UIEdgeInsetsMake(20, 0, 0, 0);
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.tableFooterView = [UIView new];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"SMSTableViewCell" bundle:nil] forCellReuseIdentifier:[SMSTableViewCell reuseIdentifier]];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    CGRect frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    self.tableView.frame = frame;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.fetchedResultsController = nil;
    [self.fetchedResultsController performFetch:nil];
    [self.tableView reloadData];
}

#pragma mark - UITableViewDelegate and UITableViewDataSource methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id sectionInfo = [[_fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Conversation *conversation = (Conversation *)[self.fetchedResultsController objectAtIndexPath:indexPath];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"MMM dd, hh:mm a"];
    UIImage *profilePicture = [UIImage imageWithData:conversation.image];
    
    SMSTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[SMSTableViewCell reuseIdentifier]];
    
    if (conversation.recepientName) {
        cell.nameLabel.text = conversation.recepientName;
    }
    else {
        cell.nameLabel.text = conversation.recepientNumber;
    }
    
    cell.messageLabel.text = conversation.lastMessage;
    cell.dateLabel.text = [dateFormat stringFromDate:conversation.timestamp];
    
    if (profilePicture != nil) {
        cell.profileImageView.image = profilePicture;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    Conversation *conversation = (Conversation *)[self.fetchedResultsController objectAtIndexPath:indexPath];
    
    SMSConversationViewController *controller = DYNAMIC_CAST([[PhoneMainView instance] changeCurrentView:[SMSConversationViewController compositeViewDescription] push:TRUE], SMSConversationViewController);
    controller.conversation = conversation;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Conversation *conversation = (Conversation *)[self.fetchedResultsController objectAtIndexPath:indexPath];
        NSManagedObjectContext *backgroundContext = [CoreDataManager sharedManager].backgroundContext;
        Conversation *conversationFromBackground = (Conversation *)[backgroundContext objectWithID:conversation.objectID];
        [[CoreDataManager sharedManager] deleteManagedObject:conversationFromBackground];
        [[CoreDataManager sharedManager] saveContextSuccessBlock:nil];
    }
}

#pragma mark - NSFetchedResultsControllerDelegate methods

- (NSFetchedResultsController *)fetchedResultsController
{
    if (!_fetchedResultsController) {
        NSSortDescriptor *sortDescriptor =  [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO];
        _fetchedResultsController = [[CoreDataManager sharedManager] fetchedResultsControllerWithEntityName:@"Conversation" predicate:nil sortDescriptorArray:@[sortDescriptor] andSectionNameKeyPath:nil];
        _fetchedResultsController.delegate = self;
    }
    return _fetchedResultsController;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeMove:
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        default:
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}

#pragma mark - Custom Setters

- (void)setPhoneNumber:(NSString *)phoneNumber
{
    _phoneNumber = phoneNumber;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"recepientNumber = %@", phoneNumber];
    [[CoreDataManager sharedManager] retrieveManagedObject:@"Conversation" predicate:predicate sortDescriptors:nil successBlock:^(NSArray *retrievedObjects) {
        if ([retrievedObjects count] <= 0) {
            [self getContactSuccessBlock:^(NSString *name, NSString *number, NSData *image) {
                Conversation *conversation = (Conversation *)[[CoreDataManager sharedManager] createManagedObject:@"Conversation"];
                
                if ([name isEqualToString:@""]) {
                    // Create conversation without data from contacts
                    conversation.recepientNumber = phoneNumber;
                }
                else {
                    // Create conversation with data from contacts
                    conversation.recepientName = name;
                    conversation.recepientNumber = number;
                    conversation.image = image;
                }
                
                [[CoreDataManager sharedManager] saveContextSuccessBlock:^{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        SMSConversationViewController *controller = DYNAMIC_CAST([[PhoneMainView instance] changeCurrentView:[SMSConversationViewController compositeViewDescription] push:TRUE], SMSConversationViewController);
                        controller.conversation = conversation;
                    });
                }];
            }];
        }
        else {
            // Open existing conversation
            Conversation *conversation = (Conversation *)retrievedObjects[0];
            SMSConversationViewController *controller = DYNAMIC_CAST([[PhoneMainView instance] changeCurrentView:[SMSConversationViewController compositeViewDescription] push:TRUE], SMSConversationViewController);
            controller.conversation = conversation;
        }
    }];
}

- (void)getContactSuccessBlock:(void(^)(NSString *name, NSString *number, NSData *image))successBlock

{
    CFErrorRef *error = NULL;
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, error);
    CFArrayRef allPeople = ABAddressBookCopyArrayOfAllPeople(addressBook);
    CFIndex numberOfPeople = ABAddressBookGetPersonCount(addressBook);
    
    BOOL isNumberExisting = NO;
    NSString *name = @"";
    NSString *number = @"";
    NSData *image;
    
    for (int i = 0; i < numberOfPeople; i++) {
        
        ABRecordRef person = CFArrayGetValueAtIndex(allPeople, i);
        
        NSString *firstName = (__bridge NSString *)(ABRecordCopyValue(person, kABPersonFirstNameProperty));
        NSString *lastName = (__bridge NSString *)(ABRecordCopyValue(person, kABPersonLastNameProperty));
        
        ABMultiValueRef phoneNumbers = ABRecordCopyValue(person, kABPersonPhoneProperty);
        
        for (CFIndex i = 0; i < ABMultiValueGetCount(phoneNumbers); i++) {
            NSString *phoneNumber = (NSString *)ABMultiValueCopyValueAtIndex(phoneNumbers, i);
            phoneNumber = [phoneNumber stringByReplacingOccurrencesOfString:@" " withString:@""];
            phoneNumber = [phoneNumber stringByReplacingOccurrencesOfString:@"+" withString:@""];
            phoneNumber = [phoneNumber stringByReplacingOccurrencesOfString:@"(" withString:@""];
            phoneNumber = [phoneNumber stringByReplacingOccurrencesOfString:@")" withString:@""];
            
            if ([phoneNumber isEqualToString:self.phoneNumber]) {
                isNumberExisting = YES;
                number = phoneNumber;
                break;
            }
        }
        
        if (isNumberExisting) {
            if (firstName && lastName) {
                name = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
            }
            else if (firstName && !lastName) {
                name = firstName;
            }
            else if (!firstName && lastName) {
                name = lastName;
            }
            
            CFDataRef imageData = ABPersonCopyImageData(person);
            image = (NSData *)imageData;
            if (imageData) {
                CFRelease(imageData);
            }
            break;
        }
    }
    
    if (successBlock) {
        successBlock(name, number, image);
    }
}

#pragma mark - UICompositeViewDelegate Functions

static UICompositeViewDescription *compositeDescription = nil;

+ (UICompositeViewDescription *)compositeViewDescription {
    if(compositeDescription == nil) {
        compositeDescription = [[UICompositeViewDescription alloc] init:@"SMS"
                                                                content:@"SMSTableViewController"
                                                               stateBar:nil
                                                        stateBarEnabled:false
                                                                 tabBar:@"UIMainBar"
                                                          tabBarEnabled:true
                                                             fullscreen:false
                                                          landscapeMode:[LinphoneManager runningOnIpad]
                                                           portraitMode:true];
        compositeDescription.darkBackground = NO;
        compositeDescription.statusBarMargin = 0.0f;
        compositeDescription.statusBarColor = [UIColor colorWithWhite:0.935f alpha:0.0f];
        compositeDescription.statusBarStyle = UIStatusBarStyleLightContent;
    }
    return compositeDescription;
}

#pragma mark - Populate CoreData

// Remove after implementing SMS functionality
- (void)populateCoreData
{
    Conversation *conversation1 = (Conversation *)[[CoreDataManager sharedManager] createManagedObject:@"Conversation"];
    conversation1.recepientName = @"Darcy";
    conversation1.recepientNumber = @"639995163632";
    conversation1.lastMessage = @"Message";
    conversation1.timestamp = [NSDate date];
    
    NSString *msg = @"Message";
    
    for (int i = 0; i <= 19; i++) {
        msg = [NSString stringWithFormat:@"%@ message", msg];
        Message *message = (Message *)[[CoreDataManager sharedManager] createManagedObject:@"Message"];
        message.content = msg;
        message.timestamp = [NSDate date];
        message.status = [NSNumber numberWithBool:NO];
        message.recepientNumber = @"639995163632";
        [conversation1 addMessagesObject:message];
    }
    
    [[CoreDataManager sharedManager] saveContextSuccessBlock:nil];
}

- (void)dealloc {
    [super dealloc];
}

@end
