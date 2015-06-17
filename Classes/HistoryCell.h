//
//  HistoryCell.h
//  linphone
//
//  Created by Art on 6/16/15.
//
//

#import <UIKit/UIKit.h>

@interface HistoryCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (strong, nonatomic) IBOutlet UILabel *nameLabel;
@property (strong, nonatomic) IBOutlet UILabel *numberLabel;
@property (strong, nonatomic) IBOutlet UILabel *dateLabel;

+ (NSString *)reuseIdentifier;

@end
