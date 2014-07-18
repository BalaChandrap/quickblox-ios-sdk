//
//  UserCredentials.h
//  VideoChat
//
//  Created by Andrey Moskvin on 5/20/14.
//  Copyright (c) 2014 Ruslan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UserCredentials : NSObject

@property (nonatomic, assign) NSUInteger userID;
@property (nonatomic, strong) NSString* login;
@property (nonatomic, strong) NSString* password;

@end
