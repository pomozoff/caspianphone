//
//  smsCaspianConversationVC.m
//  linphone
//
//  Created by  on 3/13/15.
//
//
#import "AMBubbleTableViewController.h"
#import "AMBubbleTableCell.h"

#import "SmsCaspianConversationVC.h"
#import "PhoneMainView.h"

// Added on 14 March for Growing text
#import "DTActionSheet.h"
#import "UILinphone.h"

#import <NinePatch.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import "Utils.h"
#import "UISmiliesBoardViewController.h"
#import "COCSmiliesManager.h"
//End
// Added by  on 14 March for sms History fetch
#import "SmsHistory.h"
#import "SmsHistoryFetch.h"
#import "DialerViewController.h"
//End


@interface SmsCaspianConversationVC () <AMBubbleTableDataSource, AMBubbleTableDelegate>

@property (nonatomic, strong) NSMutableArray* data;


@end

@implementation SmsCaspianConversationVC

@synthesize messageView;
@synthesize messageField;
@synthesize messageViewField;
@synthesize contactLabel = _contactLabel;
@synthesize seguePhoneNumber = _seguePhoneNumber;  // Added on 15 March to pass value from smsCaspianVC to smsCaspianConversationVC



- (id)init {
   // return [super initWithNibName:@"SmsCaspianConversationVC" bundle:[NSBundle mainBundle]];  removed for growing text change
        self = [super initWithNibName:@"SmsCaspianConversationVC" bundle:[NSBundle mainBundle]];

    return self;
    // End
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
 
    [messageView release];
    [messageField release];
    [messageViewField release];
 //   self.seguePhoneNumber = nil;
    
    [_contactLabel release];

    [super dealloc];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
   // [self performSelector:@selector(testme) withObject:nil afterDelay:0.3f];
//
//    NSString *str_finalPhoneNumber = [[NSUserDefaults standardUserDefaults] objectForKey:@"finalPhoneNumber"];
//    NSArray *smsHistoryObj = [[smsHistoryFetch database] getSMSHistory:(NSString *)str_finalPhoneNumber];
//    
//    NSLog(@"Inside sendSMS");
//    for (smsHistory *smsHistoryObject in smsHistoryObj){
//        
//        NSLog(@"%d - %@ - %@ - %@",smsHistoryObject.sno,smsHistoryObject.username,smsHistoryObject.phoneNumber,smsHistoryObject.message);
//    }
//

}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self performSelector:@selector(testme) withObject:nil afterDelay:0.1f];
    [self viewDidLoad];

    
    
    
}

-(void)testme
{
    NSString *str_finalPhoneNumber = [[NSUserDefaults standardUserDefaults] objectForKey:@"finalPhoneNumber"];
    
    NSLog(@"Segue phone number is:%@",str_finalPhoneNumber);
    [_contactLabel setText:str_finalPhoneNumber];
    
////////////////// Code goes here
    
    // Bubble Table setup
    
    [self setDataSource:self]; // Weird, uh?
    [self setDelegate:self];
    
    [self setTitle:@"Chat"];
    
    self.data = [[NSMutableArray alloc] init];
    
//    NSString *str_finalPhoneNumber = [[NSUserDefaults standardUserDefaults] objectForKey:@"finalPhoneNumber"];
    NSArray *smsHistoryObj = [[SmsHistoryFetch database] getSMSHistory:(NSString *)str_finalPhoneNumber];
    
    NSLog(@"Inside sendSMS");
    if(self.data)
    {
        [self.data removeAllObjects];
    }
    
    for (SmsHistory *smsHistoryObject in smsHistoryObj){
        NSMutableDictionary *mdict = [NSMutableDictionary dictionary];
        [mdict setValue:smsHistoryObject.message forKey:@"text"];
        [mdict setValue:[NSDate date] forKey:@"date"];
        [mdict setValue:[UIColor redColor] forKey:@"color"];
        [mdict setValue:smsHistoryObject.username forKey:@"username"];
        [mdict setValue:@(AMBubbleCellSent) forKey:@"type"];
        [self.data addObject:mdict];
        NSLog(@"%d - %@ - %@ - %@",smsHistoryObject.sno,smsHistoryObject.username,smsHistoryObject.phoneNumber,smsHistoryObject.message);
    }
    // Set a style
    [self setTableStyle:AMBubbleTableStyleFlat];
    
    [self setBubbleTableOptions:@{AMOptionsBubbleDetectionType: @(UIDataDetectorTypeAll),
                                  AMOptionsBubblePressEnabled: @NO,
                                  AMOptionsBubbleSwipeEnabled: @NO,
                                  AMOptionsButtonTextColor: [UIColor colorWithRed:1.0f green:1.0f blue:184.0f/256 alpha:1.0f]}];
    
    // Call super after setting up the options
    [super viewDidLoad];
    
    [self.tableView setContentInset:UIEdgeInsetsMake(64, 0, 0, 0)];
    
    //    [self fakeMessages];

    
    
    
    
    
    
/////////////////////////////////////
    
//    NSArray *smsHistoryObj = [[smsHistoryFetch database] getSMSHistory:(NSString *)str_finalPhoneNumber];
//    
//    NSLog(@"Inside sendSMS");
//    if(self.data)
//    {
//        [self.data removeAllObjects];
//    }
//    
//    for (smsHistory *smsHistoryObject in smsHistoryObj){
//        NSMutableDictionary *mdict = [NSMutableDictionary dictionary];
//        [mdict setValue:smsHistoryObject.message forKey:@"text"];
//        [mdict setValue:[NSDate date] forKey:@"date"];
//        [mdict setValue:[UIColor redColor] forKey:@"color"];
//        [mdict setValue:smsHistoryObject.username forKey:@"username"];
//        [mdict setValue:@(AMBubbleCellSent) forKey:@"type"];
//        [self.data addObject:mdict];
//        NSLog(@"%d - %@ - %@ - %@",smsHistoryObject.sno,smsHistoryObject.username,smsHistoryObject.phoneNumber,smsHistoryObject.message);
//        
//    }
    
    // Bubble Table setup
    
//    [self setDataSource:self]; // Weird, uh?
//    [self setDelegate:self];
//    
//    [self setTitle:@"Chat"];
//    
//  //   Set a style
//    [self setTableStyle:AMBubbleTableStyleFlat];
//    
//    [self setBubbleTableOptions:@{AMOptionsBubbleDetectionType: @(UIDataDetectorTypeAll),
//                                  AMOptionsBubblePressEnabled: @NO,
//                                  AMOptionsBubbleSwipeEnabled: @NO,
//                                  AMOptionsButtonTextColor: [UIColor colorWithRed:1.0f green:1.0f blue:184.0f/256 alpha:1.0f]}];
//    
//    // Call super after setting up the options
//
//    
//    [self.tableView setContentInset:UIEdgeInsetsMake(64, 0, 0, 0)];
//    
//  //      [self fakeMessages];
    
    

    // NSString *str_finalPhoneNumber = [[NSUserDefaults standardUserDefaults] objectForKey:@"finalPhoneNumber"];
    

    
    
    
    // End

}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    
    [messageViewField resignFirstResponder];
}


- (void)fakeMessages
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self didSendText:@"Fake message here!"];
        [self fakeMessages];
    });
}

- (void)swipedCellAtIndexPath:(NSIndexPath *)indexPath withFrame:(CGRect)frame andDirection:(UISwipeGestureRecognizerDirection)direction
{
    NSLog(@"swiped");
}
#pragma mark - AMBubbleTableDataSource

- (NSInteger)numberOfRows
{
    return self.data.count;
}

- (AMBubbleCellType)cellTypeForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.data[indexPath.row][@"type"] intValue];
}

- (NSString *)textForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return self.data[indexPath.row][@"text"];
}

- (NSDate *)timestampForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [NSDate date];
}

- (UIImage*)avatarForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [UIImage imageNamed:@"avatar"];
}

#pragma mark - AMBubbleTableDelegate

- (void)didSendText:(NSString*)text
{
    NSLog(@"User wrote: %@", text);
    
    [self.data addObject:@{ @"text": text,
                            @"date": [NSDate date],
                            @"type": @(AMBubbleCellSent)
                            }];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:(self.data.count - 1) inSection:0];
    [self.tableView beginUpdates];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationRight];
    [self.tableView endUpdates];
    // Either do this:
    [self scrollToBottomAnimated:YES];
    // or this:
    // [super reloadTableScrollingToBottom:YES];
}

- (NSString*)usernameForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return self.data[indexPath.row][@"username"];
}

- (UIColor*)usernameColorForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return self.data[indexPath.row][@"color"];
}




- (void)dismiss {
    
    [[PhoneMainView instance] popCurrentView];
    
}
// Added by  on 7 March 2015 for warning fix

+ (UICompositeViewDescription*) compositeProcessSMSViewDescription;
{
    return nil;
}
+ (UICompositeViewDescription*) compositeSMSViewDescription;
{
    return nil;
}
+ (UICompositeViewDescription*) compositeSMSViewController;
{
    return nil;
}
// End
- (IBAction)backSMS:(id)sender {
    NSLog(@"Back to smsCaspianVC");
    [self dismiss];
    
    }
- (IBAction)sendSMS:(id)sender {
}

//End
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
static UICompositeViewDescription *compositeDescription = nil;

+ (UICompositeViewDescription *)compositeViewDescription {
    if(compositeDescription == nil) {
        compositeDescription = [[UICompositeViewDescription alloc] init:@"SmsCaspianConversationVC"
                                                                content:@"SmsCaspianConversationVC"
                                                               stateBar:nil
                                                        stateBarEnabled:false
                                                                 tabBar: /*@"UIMainBar"*/nil
                                                          tabBarEnabled:false
                                                             fullscreen:false
                                                          landscapeMode:/*[LinphoneManager runningOnIpad]*/false
                                                           portraitMode:true];
        //compositeDescription.statusBarMargin = 0.0f;
        //compositeDescription.darkBackground = NO;
        //compositeDescription.statusBarColor = [UIColor colorWithWhite:0.935f alpha:0.0f];
    }
    return compositeDescription;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
