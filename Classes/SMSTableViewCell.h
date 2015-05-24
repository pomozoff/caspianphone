//
//  SMSTableViewCell.h
//  linphone
//
//  Created by Art on 5/19/15.
//
//

#import <UIKit/UIKit.h>

@interface SMSTableViewCell : UITableViewCell

@property (retain, nonatomic) IBOutlet UIImageView *profileImageView;
@property (retain, nonatomic) IBOutlet UILabel *nameLabel;
@property (retain, nonatomic) IBOutlet UILabel *messageLabel;
@property (retain, nonatomic) IBOutlet UILabel *dateLabel;

+ (NSString *)reuseIdentifier;

@end
