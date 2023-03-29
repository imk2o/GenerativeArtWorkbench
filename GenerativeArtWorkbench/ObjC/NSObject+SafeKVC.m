//
//  NSObject+SafeKVC.m
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/03/29.
//

#import "NSObject+SafeKVC.h"

@implementation NSObject (SafeKVC)

- (id)safeValueForKey:(NSString *)key
{
    @try {
        return [self valueForKey:key];
    }
    @catch (NSException *exception) {
        return nil;
    }
}

- (void)setSafeValue:(id)value forKey:(NSString *)key
{
    @try {
        [self setValue:value forKey:key];
    }
    @catch (NSException *exception) {
        return;
    }
}

@end
