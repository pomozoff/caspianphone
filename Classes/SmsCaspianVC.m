//
//  smsCaspianVC.m
//  linphone
//
//  Created by  on 3/12/15.
//
//

#import "SmsCaspianVC.h"
#import "PhoneMainView.h"
#import "SmsCaspianConversationVC.h"
// Added by  on 14 March for sms History fetch
#import "SmsHistory.h"
#import "SmsHistoryFetch.h"
//End

@interface SmsCaspianVC ()

@end

@implementation SmsCaspianVC



@synthesize getSMSHistoryPhoneNumbers=_getSMSHistoryPhoneNumbers;    // Fetch phone numbers from history SQL Lite 3
@synthesize phoneNumberSelectCell;
@synthesize window, navController;



- (id)init {
    return [super initWithNibName:@"SmsCaspianVC" bundle:[NSBundle mainBundle]];
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [super dealloc];
    self.getSMSHistoryPhoneNumbers = nil;
    self.phoneNumberSelectCell = nil;
    [window release];
    [navController release];
    
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
static UICompositeViewDescription *compositeDescription = nil;

+ (UICompositeViewDescription *)compositeViewDescription {
    if(compositeDescription == nil) {
        compositeDescription = [[UICompositeViewDescription alloc] init:@"sms"
                                                                content:@"SmsCaspianVC"
                                                               stateBar:nil
                                                        stateBarEnabled:false
                                                                 tabBar: @"UIMainBar"
                                                          tabBarEnabled:true
                                                             fullscreen:false
                                                          landscapeMode:[LinphoneManager runningOnIpad]
                                                           portraitMode:true];
        //compositeDescription.statusBarMargin = 0.0f;
        //compositeDescription.darkBackground = NO;
        //compositeDescription.statusBarColor = [UIColor colorWithWhite:0.935f alpha:0.0f];
    }
    return compositeDescription;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.

    self.getSMSHistoryPhoneNumbers = [SmsHistoryFetch database].getSMSHistoryPhoneNumbers;   // Fetch phone numbers from sms history
    
//    NSArray *getSMSHistoryPhoneNumbers = [smsHistoryFetch database].getSMSHistoryPhoneNumbers;
//    NSLog(@"Inside sendSMS");
//    for (smsHistory *getSMS in getSMSHistoryPhoneNumbers){
//        NSLog(@"%@",getSMS.phoneNumber);
//    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{

    //self.getSMSHistoryPhoneNumbers = [smsHistoryFetch database].getSMSHistoryPhoneNumbers;
    return [_getSMSHistoryPhoneNumbers count];
    //return [tableData count];
    
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *simpleTableIdentifier = @"SimpleTableItem";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }

    SmsHistory *getSMS = [_getSMSHistoryPhoneNumbers objectAtIndex:indexPath.row];
        cell.textLabel.text = getSMS.phoneNumber;
    cell.imageView.image = [UIImage imageNamed:@"contacts.png"];
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
            SmsHistory *getSMS = [_getSMSHistoryPhoneNumbers objectAtIndex:indexPath.row];
    NSString *finalPhoneNumber = [NSString stringWithFormat:@"%@",getSMS.phoneNumber];

    if ([finalPhoneNumber length])   {
        [[NSUserDefaults standardUserDefaults] setObject:finalPhoneNumber forKey:@"finalPhoneNumber"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        NSLog(@"Sync successful");
    }

    SmsCaspianConversationVC *controller = DYNAMIC_CAST([[PhoneMainView instance] changeCurrentView:[SmsCaspianConversationVC compositeViewDescription]
                                                                                   push:TRUE], SmsCaspianConversationVC);
            controller.seguePhoneNumber = getSMS.phoneNumber;
   
    
    // Preparing for segue -- passing phone number varible from smsCaspianVC to smsCaspianConversationVC
    

    if (controller) {
        NSLog(@"Switching to smsCaspianConversationVC");
        
//        smsHistory *getSMS = [_getSMSHistoryPhoneNumbers objectAtIndex:indexPath.row];
//        cell.textLabel.text = getSMS.phoneNumber;
        SmsHistory *getSMS = [_getSMSHistoryPhoneNumbers objectAtIndex:indexPath.row];
        controller.seguePhoneNumber = getSMS.phoneNumber;
//        NSString *finalPhoneNumber = [NSString stringWithFormat:@"%@",controller.seguePhoneNumber];
//
//        if ([finalPhoneNumber length])   {
//            [[NSUserDefaults standardUserDefaults] setObject:finalPhoneNumber forKey:@"finalPhoneNumber"];
//            [[NSUserDefaults standardUserDefaults] synchronize];
//            NSLog(@"Sync successful");
//        }
//        
//        NSLog(@"Index Path%@",controller.seguePhoneNumber);
    

    }
    // Pass the selected object to the new view controller.

    
    
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
