//
//  HistoryCell.h
//  linphone
//
//  Created by Art on 6/16/15.
//
//

#import <UIKit/UIKit.h>
@class HistoryCell;

@protocol HistoryCellDelegate <NSObject>

- (void)didTapChatButton:(HistoryCell *)historyCell;
- (void)didTapSMSButton:(HistoryCell *)historyCell;
- (void)didTapCallButton:(HistoryCell *)historyCell;
- (void)didTapAddButton:(HistoryCell *)historyCell;
- (void)didTapLogoButton:(HistoryCell *)historyCell;

@end

@interface HistoryCell : UITableViewCell

@property (weak, nonatomic) id <HistoryCellDelegate> delegate;
@property (strong, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (strong, nonatomic) IBOutlet UILabel *nameLabel;
@property (strong, nonatomic) IBOutlet UILabel *numberLabel;
@property (strong, nonatomic) IBOutlet UILabel *dateLabel;

+ (NSString *)reuseIdentifier;

@end
