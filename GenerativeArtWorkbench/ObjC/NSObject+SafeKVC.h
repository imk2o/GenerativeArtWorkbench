//
//  NSObject+SafeKVC.h
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/03/29.
//

#import <Foundation/Foundation.h>

@interface NSObject (SafeKVC)
// 未定義のキーで参照したときに例外が発生してもnilを返す
- (id)safeValueForKey:(NSString *)key;
- (void)setSafeValue:(id)value forKey:(NSString *)key;
@end
