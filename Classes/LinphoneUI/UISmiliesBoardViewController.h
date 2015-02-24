//
//  UISmiliesBoardViewController.h
//  linphone
//
//  Created by Антон on 18.02.15.
//
//

#import <UIKit/UIKit.h>

@protocol UISmiliesCollectionDelegate <NSObject>

- (void)didSelectSmileWithIndex:(NSInteger)index;

@end

@interface UISmiliesBoardViewController : UICollectionViewController <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, retain) id<UISmiliesCollectionDelegate> delegate;

@end
