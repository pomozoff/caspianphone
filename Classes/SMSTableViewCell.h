//
//  SMSTableViewCell.h
//  linphone
//
//  Created by Art on 5/19/15.
//
//

#import <UIKit/UIKit.h>

@interface SMSTableViewCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UIImageView *profileImageView;
@property (nonatomic, strong) IBOutlet UILabel *nameLabel;
@property (nonatomic, strong) IBOutlet UILabel *messageLabel;
@property (nonatomic, strong) IBOutlet UILabel *dateLabel;

+ (NSString *)reuseIdentifier;

@end
