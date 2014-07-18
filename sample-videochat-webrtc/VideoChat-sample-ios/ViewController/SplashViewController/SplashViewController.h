//
//  SpalshViewController.h
//  SimpleSample-videochat-ios
//
//  Created by QuickBlox team on 1/02/13.
//  Copyright (c) 2013 QuickBlox. All rights reserved.
//
//
// This class creates QuickBlox session with user in order to use QuickBlox API.
// Then hides splash screen & show main controller that shows how to work
// with QuickBlox VideoChat API - how to organize 1-1 videochat.
//

#import <UIKit/UIKit.h>

@interface SplashViewController : UIViewController<QBActionStatusDelegate, QBChatDelegate>
@end
