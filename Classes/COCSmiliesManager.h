//
//  COCSmiliesManager.h
//  linphone
//
//  Created by Антон on 10.02.15.
//
//

#import <Foundation/Foundation.h>

@interface COCSmiliesManager : NSObject

+ (instancetype)sharedInstance;

- (NSAttributedString *)attributedStringForText:(NSString *)nstext;

@end
