//
//  ProcessSMSViewController.m
//  linphone
//
//  Created by  on 3/5/15.
//
//

#import "ProcessSMSViewController.h"
#import "PhoneMainView.h"
#import "SmsCaspianVC.h"

@interface ProcessSMSViewController ()

@end

@implementation ProcessSMSViewController
@synthesize textActivateSMS;
// Added by  on 8 March for comparing the text field user entered data with the random char sent to the user


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
// Added by  on 5 March 2015 for Activate SMS No button
- (void)dismiss {
    
    [[PhoneMainView instance] popCurrentView];
    
}
- (IBAction)cancelSMSActivationProcess:(id)sender {
    NSLog(@"Cancelled SMS Activation Process");
    [[PhoneMainView instance] popCurrentView];

}
- (IBAction)confirmActivationSMS:(id)sender {

    NSString *str_randomNumber = [[NSUserDefaults standardUserDefaults] objectForKey:@"Random_Character"];

    NSLog(@"Random generated Activation key:%@",str_randomNumber);
    
    NSString *textActivateConfirm = textActivateSMS.text;
    NSLog(@"Text Activate Confirm:%@",textActivateConfirm);
    
    if ([textActivateConfirm isEqualToString:str_randomNumber])    {
        NSLog(@"Bingo You have successfully autheticated yourself");
        NSString *smsActiveState = @"1";
        [[NSUserDefaults standardUserDefaults] setObject:smsActiveState forKey:@"SMS_Active_State"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        
        SmsCaspianVC *controller = DYNAMIC_CAST([[PhoneMainView instance] changeCurrentView:[SmsCaspianVC compositeViewDescription]
                                                                                       push:TRUE], SmsCaspianVC);
        if (controller) {
            NSLog(@"Changing to smsCaspianVC View Controller");
        }
    }
    else    {
        
            [[PhoneMainView instance] popCurrentView];
    }
}
// Dismiss keyboard 
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    [self.view endEditing:YES];
}
- (void)dealloc {
    [textActivateSMS release];
    [super dealloc];
}
@end
