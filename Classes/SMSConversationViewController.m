//
//  SMSConversationViewController.m
//  linphone
//
//  Created by Art on 5/21/15.
//
//

#import "SMSConversationViewController.h"
#import "CoreDataManager.h"
#import "SMSMessageCell.h"
#import "PhoneMainView.h"
#import "Conversation.h"
#import "Message.h"

static NSString *caspianPhoneNumber = @"uk.co.onecallcaspian.phone.phoneNumber";
static NSString *caspianPasswordKey = @"uk.co.onecallcaspian.phone.password";
static NSString *smsAPI = @"https://onecallcaspian.co.uk/mobile/sms?phone_number=%@&password=%@&from=%@&text=%@&receiver=%@";

@interface SMSConversationViewController () <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) IBOutlet UILabel *nameLabel;
@property (nonatomic, strong) IBOutlet UIImageView *profileImageView;
@property (nonatomic, strong) IBOutlet UIView *textEditView;
@property (nonatomic, strong) IBOutlet UITextView *messageTextView;
@property (nonatomic, strong) IBOutlet UIButton *sendButton;
@property (nonatomic) BOOL keyboardShown;

@end

@implementation SMSConversationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.profileImageView.layer.cornerRadius = self.profileImageView.frame.size.width / 2;
    self.messageTextView.layer.cornerRadius = 7;
    self.messageTextView.autocorrectionType = UITextAutocorrectionTypeNo;
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.tableFooterView = [UIView new];
    self.tableView.allowsSelection = NO;
    self.tableView.clipsToBounds = YES;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];
    [self.view bringSubviewToFront:self.textEditView];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    CGRect frame = CGRectMake(0, 70, self.view.frame.size.width, self.view.frame.size.height - 122);
    self.tableView.frame = frame;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    self.textEditView.frame = CGRectMake(0, self.view.frame.size.height - self.textEditView.frame.size.height, self.textEditView.frame.size.width, self.textEditView.frame.size.height);
    [self.view bringSubviewToFront:self.textEditView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    UITapGestureRecognizer * tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    [self.view addGestureRecognizer:tapGesture];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    self.messageTextView.text = @"";
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)scrollToBottomAnimated:(BOOL)animated
{
    NSSortDescriptor *sortDescriptor =  [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:YES];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"recepientNumber = %@", self.conversation.recepientNumber];
    [[CoreDataManager sharedManager] retrieveManagedObject:@"Message" predicate:predicate sortDescriptors:@[sortDescriptor] successBlock:^(NSArray *retrievedObjects) {
        if ([retrievedObjects count] > 0) {
            NSIndexPath *lastMessage = [NSIndexPath indexPathForRow:[retrievedObjects count] - 1 inSection:0];
            [self.tableView scrollToRowAtIndexPath:lastMessage atScrollPosition:UITableViewScrollPositionBottom animated:animated];
        }
    }];
}

- (void)hideKeyboard
{
    [self.messageTextView resignFirstResponder];
}

#pragma mark - UITableViewDelegate and UITableViewDataSource methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Message *message = (Message *)[self.fetchedResultsController objectAtIndexPath:indexPath];
    return [SMSMessageCell cellHeightWithMessage:message.content];
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
    Message *message = (Message *)[self.fetchedResultsController objectAtIndexPath:indexPath];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"MMM dd, yyyy, hh:mm a"];
    
    SMSMessageCell *cell = [[SMSMessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    cell.messageLabel.text = message.content;
    cell.timestampLabel.text = [dateFormat stringFromDate:message.timestamp];
    UIImage *messageStatus = ([message.status boolValue]) ? [UIImage imageNamed:@"chat_message_delivered"] : [UIImage imageNamed:@"chat_message_inprogress"];
    cell.statusImageView.image = messageStatus;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - NSFetchedResultsControllerDelegate methods

- (NSFetchedResultsController *)fetchedResultsController
{
    if (!_fetchedResultsController) {
        NSSortDescriptor *sortDescriptor =  [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:YES];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"recepientNumber = %@", self.conversation.recepientNumber];
        _fetchedResultsController = [[CoreDataManager sharedManager] fetchedResultsControllerWithEntityName:@"Message" predicate:predicate sortDescriptorArray:@[sortDescriptor] andSectionNameKeyPath:nil];
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
            [self scrollToBottomAnimated:YES];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeMove:
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
        {
            Message *message = (Message *)[self.fetchedResultsController objectAtIndexPath:indexPath];
            SMSMessageCell *cell = (SMSMessageCell *)[self.tableView cellForRowAtIndexPath:indexPath];
            UIImage *messageStatus = ([message.status boolValue]) ? [UIImage imageNamed:@"chat_message_delivered"] : [UIImage imageNamed:@"chat_message_inprogress"];
            cell.statusImageView.image = messageStatus;
            break;
        }
            
        default:
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}

#pragma mark - Custom Setters

- (void)setConversation:(Conversation *)conversation
{
    _conversation = conversation;
    self.fetchedResultsController = nil;
    [self.fetchedResultsController performFetch:nil];
    [self.tableView reloadData];
    if (conversation.recepientName) {
        self.nameLabel.text = conversation.recepientName;
    }
    else {
        self.nameLabel.text = conversation.recepientNumber;
    }
    
    UIImage *profilePicture = [UIImage imageWithData:conversation.image];
    if (profilePicture != nil) {
        self.profileImageView.image = profilePicture;
    }
    else {
        self.profileImageView.image = [UIImage imageNamed:@"profile-picture-small"];
    }
    
    [self scrollToBottomAnimated:NO];
}

#pragma mark - Button Click methods

- (IBAction)backButtonTapped:(id)sender
{
    [[PhoneMainView instance] popCurrentView];
}

- (IBAction)sendButtonTapped:(id)sender
{
    NSString *messageString = self.messageTextView.text;
    self.messageTextView.text = @"";
    NSString *phoneNumber = [[NSUserDefaults standardUserDefaults] objectForKey:caspianPhoneNumber];
    NSString *password = [[NSUserDefaults standardUserDefaults] objectForKey:caspianPasswordKey];
    
    Conversation *conversationFromBackground = (Conversation *)[[CoreDataManager sharedManager].backgroundContext objectWithID:self.conversation.objectID];
    Message *message = (Message *)[[CoreDataManager sharedManager] createManagedObject:@"Message"];
    message.content = messageString;
    message.timestamp = [NSDate date];
    message.status = [NSNumber numberWithBool:NO];
    message.recepientNumber = self.conversation.recepientNumber;
    [conversationFromBackground addMessagesObject:message];
    
    conversationFromBackground.timestamp = message.timestamp;
    conversationFromBackground.lastMessage = message.content;
    
    [[CoreDataManager sharedManager] saveContextSuccessBlock:^{
        NSString *urlString = [NSString stringWithFormat:smsAPI, phoneNumber, password, phoneNumber, messageString, self.conversation.recepientNumber];
        [[LinphoneManager instance] dataFromUrlString:urlString method:@"GET" completionBlock:^{
            message.status = [NSNumber numberWithBool:YES];
            [[CoreDataManager sharedManager] saveContextSuccessBlock:nil];
        } errorBlock:nil];
    }];
}

#pragma mark - Keyboard Observer

- (void)keyboardWillShow:(NSNotification *)notification
{
    self.keyboardShown = YES;
    
    NSDictionary *info = notification.userInfo;
    NSValue *value = info[UIKeyboardFrameEndUserInfoKey];
    CGRect rawFrame = [value CGRectValue];
    CGRect keyboardFrame = [self.view convertRect:rawFrame fromView:nil];
    
    NSNumber *animationDurationNumber = [[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval keyboardAnimationDuration = [animationDurationNumber doubleValue];
    NSNumber *animationCurveNumber = [[notification userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey];
    UIViewAnimationCurve animationCurve = (UIViewAnimationCurve)[animationCurveNumber intValue];
    UIViewAnimationOptions keyboardAnimationOptions = animationCurve << 16;
    
    [UIView animateWithDuration:keyboardAnimationDuration delay:0.0 options:keyboardAnimationOptions animations:^{
        CGFloat originY = self.view.frame.size.height - self.textEditView.frame.size.height - keyboardFrame.size.height;
        self.textEditView.frame = CGRectMake(self.textEditView.frame.origin.x, originY, self.textEditView.frame.size.width, self.textEditView.frame.size.height);
        self.tableView.contentInset = UIEdgeInsetsMake(0, 0, keyboardFrame.size.height, 0);
        [self scrollToBottomAnimated:YES];
    } completion:nil];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    NSNumber *animationDurationNumber = [[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval keyboardAnimationDuration = [animationDurationNumber doubleValue];
    NSNumber *animationCurveNumber = [[notification userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey];
    UIViewAnimationCurve animationCurve = (UIViewAnimationCurve)[animationCurveNumber intValue];
    UIViewAnimationOptions keyboardAnimationOptions = animationCurve << 16;
    
    [UIView animateWithDuration:keyboardAnimationDuration delay:0.0 options:keyboardAnimationOptions animations:^{
        CGFloat originY = self.view.frame.size.height - self.textEditView.frame.size.height;
        self.textEditView.frame = CGRectMake(self.textEditView.frame.origin.x, originY, self.textEditView.frame.size.width, self.textEditView.frame.size.height);
        self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    } completion:nil];
}

#pragma mark - UICompositeViewDelegate Functions

static UICompositeViewDescription *compositeDescription = nil;

+ (UICompositeViewDescription *)compositeViewDescription {
    if(compositeDescription == nil) {
        compositeDescription = [[UICompositeViewDescription alloc] init:@"SMS"
                                                                content:@"SMSConversationViewController"
                                                               stateBar:nil
                                                        stateBarEnabled:false
                                                                 tabBar:nil
                                                          tabBarEnabled:false
                                                             fullscreen:false
                                                          landscapeMode:true
                                                           portraitMode:true];
        compositeDescription.darkBackground = NO;
        compositeDescription.statusBarMargin = 0.0f;
        compositeDescription.statusBarColor = [UIColor colorWithWhite:0.935f alpha:0.0f];
        compositeDescription.statusBarStyle = UIStatusBarStyleLightContent;
    }
    return compositeDescription;
}

@end
