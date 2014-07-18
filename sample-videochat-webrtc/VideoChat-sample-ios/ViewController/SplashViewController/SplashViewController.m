//
//  SpalshViewController.m
//  SimpleSample-videochat-ios
//
//  Created by QuickBlox team on 1/02/13.
//  Copyright (c) 2013 QuickBlox. All rights reserved.
//

#import "SplashViewController.h"
#import "MainViewController.h"
#import "UserCredentials.h"

@interface SplashViewController () <UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UITextField *loginTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;

@property (strong, nonatomic) UserCredentials* credentials;

@end

@implementation SplashViewController

- (BOOL)shouldAutorotate
{
	return NO;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	NSString* login = [defaults objectForKey:@"qb_user_login"];
	NSString* password = [defaults objectForKey:@"qb_user_password"];
	NSInteger ID = [defaults integerForKey:@"qb_user_identifier"];
	
	if (login != nil && password != nil) {
		self.credentials = [UserCredentials new];
		self.credentials.login = login;
		self.credentials.password = password;
		self.credentials.userID = ID;
		self.loginTextField.text = login;
		self.passwordTextField.text = password;
	}
}

- (IBAction)loginButtonTouched:(id)sender
{
	[self login];
}

- (void)login
{
	if (self.loginTextField.text.length > 0 && self.passwordTextField.text.length > 0) {
		[self.passwordTextField resignFirstResponder];
		[self.view resignFirstResponder];
		if (self.credentials == nil) {
			self.credentials = [UserCredentials new];
			self.credentials.login = self.loginTextField.text;
			self.credentials.password = self.passwordTextField.text;
			
			NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
			[defaults setObject:self.credentials.login forKey:@"qb_user_login"];
			[defaults setObject:self.credentials.password forKey:@"qb_user_password"];
		}
		
		QBASessionCreationRequest *extendedAuthRequest = [QBASessionCreationRequest request];
		extendedAuthRequest.userLogin = self.credentials.login;
		extendedAuthRequest.userPassword = self.credentials.password;
		
		[QBAuth createSessionWithExtendedRequest:extendedAuthRequest delegate:self];
		
		[self.activityIndicator startAnimating];
	} else {
		UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"Trying to login with empty credentials!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alertView show];
	}
}

#pragma mark -
#pragma mark QBActionStatusDelegate

// QuickBlox API queries delegate
- (void)completedWithResult:(Result *)result
{
    // QuickBlox session creation  result
    if([result isKindOfClass:[QBAAuthSessionCreationResult class]]){
        
        // Success result
        if(result.success){
            
            // Set QuickBlox Chat delegate
            //
            [QBChat instance].delegate = self;
            
            QBUUser *user = [QBUUser user];
            user.ID = ((QBAAuthSessionCreationResult *)result).session.userID;
            user.password = self.credentials.password;
			
			
			self.credentials.userID = user.ID;
			[[NSUserDefaults standardUserDefaults] setInteger:self.credentials.userID forKey:@"qb_user_identifier"];
			
            // Login to QuickBlox Chat
            //
            [[QBChat instance] loginWithUser:user];
        }else{
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:[[result errors] description]
														   delegate:nil
												  cancelButtonTitle:@"Ok"
												  otherButtonTitles:nil];
            [alert show];
		}
    }
}


#pragma mark -
#pragma mark QBChatDelegate

- (void)chatDidLogin
{
	[self.activityIndicator stopAnimating];
	
    MainViewController *mainViewController = [[MainViewController alloc] init];
	mainViewController.credentials = self.credentials;
	UINavigationController* controller = [[UINavigationController alloc] initWithRootViewController:mainViewController];
	controller.navigationBar.translucent = NO;
    [self presentViewController:controller animated:YES completion:nil];
}

- (void)chatDidNotLogin
{
	
}

#pragma mark -
#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	if ([textField isEqual:self.loginTextField]) {
		[self.passwordTextField becomeFirstResponder];
	}
	
	if ([textField isEqual:self.passwordTextField]) {
		[self.passwordTextField resignFirstResponder];
		[self login];
	}
	return YES;
}

@end
