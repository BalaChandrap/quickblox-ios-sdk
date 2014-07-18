//
//  MainViewController.m
//  SimpleSample-videochat-ios
//
//  Created by QuickBlox team on 1/02/13.
//  Copyright (c) 2013 QuickBlox. All rights reserved.
//

#import "MainViewController.h"
#import "UserCredentials.h"

@interface MainViewController () <QBChatDelegate, AVAudioPlayerDelegate, UIAlertViewDelegate, UITextFieldDelegate>{
	__weak IBOutlet UIButton *callButton;
	__weak IBOutlet UIButton *finishCallButton;
    __weak IBOutlet UILabel *ringigngLabel;
    __weak IBOutlet UIActivityIndicatorView *callingActivityIndicator;
    __weak IBOutlet UIActivityIndicatorView *startingCallActivityIndicator;
    __weak IBOutlet QBVideoView *opponentVideoView;
	__weak IBOutlet UIView *myVideoView;
	__weak IBOutlet UITextField *opponentTextField;
    
    AVAudioPlayer *ringingPlayer;
    
    NSUInteger videoChatOpponentID;
    NSString *sessionID;
}

@property (nonatomic, strong) NSDictionary* customParameters;

@property (nonatomic, strong) QBWebRTCVideoChat *videoChat;
@property (nonatomic, strong) UIAlertView *callAlert;

@property (nonatomic, assign) enum QBVideoChatConferenceType callConferenceType;

@end

@implementation MainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    opponentVideoView.layer.borderWidth = 1;
    opponentVideoView.layer.borderColor = [[UIColor grayColor] CGColor];
    opponentVideoView.layer.cornerRadius = 5;
	
	opponentTextField.text = [[[NSUserDefaults standardUserDefaults] objectForKey:@"qb_opponent_id"] stringValue];
	
    self.navigationItem.title = self.credentials.login;
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
	
    // Start sending chat presence
    [QBChat instance].delegate = self;
    [NSTimer scheduledTimerWithTimeInterval:30 target:[QBChat instance] selector:@selector(sendPresence) userInfo:nil repeats:YES];
}

- (IBAction)logoutTouched:(id)sender
{
	[self finishCall];
	videoChatOpponentID = 0;
	[[QBChat instance] logout];
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)callButtonTouched:(id)sender
{
	if (opponentTextField.text.length > 0) {
		videoChatOpponentID = [opponentTextField.text integerValue];
		[[NSUserDefaults standardUserDefaults] setObject:@(videoChatOpponentID) forKey:@"qb_opponent_id"];
		[opponentTextField resignFirstResponder];
		[self startCall];
	}
}

- (IBAction)finishCallButtonTouched:(id)sender
{
	[self finishCall];
}

- (IBAction)cameraModeChanged:(UISegmentedControl *)sender
{
//	self.videoChat.useBackCamera = !self.videoChat.useBackCamera;
}

- (void)startCall
{
	opponentTextField.enabled = NO;
	self.videoChat = [[QBChat instance] createWebRTCVideoChatInstance];
    self.videoChat.currentConferenceType = QBVideoChatConferenceTypeAudio;
	self.videoChat.viewToRenderOpponentVideoStream = opponentVideoView;
//	self.videoChat.viewToRenderOwnVideoStream = myVideoView;
	
	[self.videoChat callUser:videoChatOpponentID];
	
	callButton.hidden = YES;
	finishCallButton.hidden = NO;
	ringigngLabel.hidden = NO;
	[callingActivityIndicator startAnimating];
}

- (void)finishCall
{
	[self.videoChat finishCall];
	
	opponentVideoView.layer.borderWidth = 1;
	
	myVideoView.hidden = YES;
	finishCallButton.hidden = YES;
	callButton.hidden = NO;
	ringigngLabel.hidden = YES;
	opponentTextField.enabled = YES;

	[startingCallActivityIndicator stopAnimating];
	[callingActivityIndicator stopAnimating];

	[[QBChat instance] unregisterWebRTCVideoChatInstance:self.videoChat];
}

- (void)reject
{
	[opponentTextField resignFirstResponder];
	
	self.videoChat = [[QBChat instance] createAndRegisterWebRTCVideoChatInstanceWithSessionID:sessionID];

    [self.videoChat rejectCallWithOpponentID:videoChatOpponentID];
    [[QBChat instance] unregisterWebRTCVideoChatInstance:self.videoChat];

    // update UI
    callButton.hidden = NO;
	finishCallButton.hidden = YES;
    ringigngLabel.hidden = YES;
	opponentTextField.enabled = YES;
    
    // release player
    ringingPlayer = nil;
}

- (void)accept
{
	[opponentTextField resignFirstResponder];
	
	self.videoChat = [[QBChat instance] createAndRegisterWebRTCVideoChatInstanceWithSessionID:sessionID];
    self.videoChat.currentConferenceType = self.callConferenceType;
	self.videoChat.viewToRenderOpponentVideoStream = opponentVideoView;
//	self.videoChat.viewToRenderOwnVideoStream = myVideoView;
	
	self.videoChat.viewToRenderOpponentVideoStream.remotePlatform = self.customParameters[qbvideochat_platform];
	self.videoChat.viewToRenderOpponentVideoStream.remoteVideoOrientation = [QBChatUtils interfaceOrientationFromString:self.customParameters[qbvideochat_device_orientation]];
    
    [self.videoChat acceptCallWithOpponentID:videoChatOpponentID
                            customParameters:self.customParameters];

    ringigngLabel.hidden = YES;
    callButton.hidden = YES;
	finishCallButton.hidden = NO;
    opponentVideoView.layer.borderWidth = 0;
	myVideoView.hidden = NO;
	opponentTextField.enabled = NO;
    [startingCallActivityIndicator startAnimating];
    
    ringingPlayer = nil;
}

- (void)hideCallAlert
{
    [self.callAlert dismissWithClickedButtonIndex:-1 animated:YES];
    self.callAlert = nil;
    
    callButton.hidden = NO;
}

- (NSUInteger)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskAll;
}

- (BOOL)shouldAutorotate
{
	return YES;
}

#pragma mark -
#pragma mark AVAudioPlayerDelegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
    ringingPlayer = nil;
}


#pragma mark -
#pragma mark QBChatDelegate - VideoChat

- (void)chatDidReceiveCallRequestFromUser:(NSUInteger)userID
							withSessionID:(NSString *)_sessionID
						   conferenceType:(enum QBVideoChatConferenceType)conferenceType
						 customParameters:(NSDictionary *)customParameters
{
    NSLog(@"chatDidReceiveCallRequestFromUser %d", userID);
    
	self.customParameters = customParameters;
    self.callConferenceType = conferenceType;
	
    // save  opponent data
    videoChatOpponentID = userID;
    
    sessionID = _sessionID;
	[[NSUserDefaults standardUserDefaults] setObject:@(videoChatOpponentID) forKey:@"qb_opponent_id"];
    
	opponentTextField.text = [NSString stringWithFormat:@"%d", userID];
    callButton.hidden = YES;
    
    if (self.callAlert == nil) {
        NSString *message = [NSString stringWithFormat:@"%d is calling. Would you like to answer?", userID];
        self.callAlert = [[UIAlertView alloc] initWithTitle:@"Call" message:message
												   delegate:self
										  cancelButtonTitle:@"Decline"
										  otherButtonTitles:@"Accept", nil];
        [self.callAlert show];
    }
    
    if(ringingPlayer == nil) {
        NSString *path =[[NSBundle mainBundle] pathForResource:@"ringing" ofType:@"wav"];
        NSURL *url = [NSURL fileURLWithPath:path];
        ringingPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:NULL];
        ringingPlayer.delegate = self;
        [ringingPlayer setVolume:1.0];
        [ringingPlayer play];
    }
}

- (void)chatCallUserDidNotAnswer:(NSUInteger)userID
{
    NSLog(@"chatCallUserDidNotAnswer %d", userID);
    
    callButton.hidden = NO;
	finishCallButton.hidden = YES;
    ringigngLabel.hidden = YES;
    callingActivityIndicator.hidden = YES;
    callButton.tag = 101;
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"QuickBlox VideoChat" message:@"User isn't answering. Please try again." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];
}

- (void)chatCallDidRejectByUser:(NSUInteger)userID
{
     NSLog(@"chatCallDidRejectByUser %d", userID);
    
	[[QBChat instance] unregisterWebRTCVideoChatInstance:self.videoChat];
	
	opponentTextField.enabled = YES;
    callButton.hidden = NO;
	finishCallButton.hidden = YES;
    ringigngLabel.hidden = YES;
    callingActivityIndicator.hidden = YES;
    
    callButton.tag = 101;
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"QuickBlox VideoChat" message:@"User has rejected your call." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];
}

- (void)chatCallDidAcceptByUser:(NSUInteger)userID
{
    NSLog(@"chatCallDidAcceptByUser %d", userID);
    
    ringigngLabel.hidden = YES;
    callingActivityIndicator.hidden = YES;
	finishCallButton.hidden = NO;
    
    opponentVideoView.layer.borderWidth = 0;
    
     myVideoView.hidden = NO;
    
    [startingCallActivityIndicator startAnimating];
}

- (void)chatCallDidStopByUser:(NSUInteger)userID status:(NSString *)status
{
    NSLog(@"chatCallDidStopByUser %d purpose %@", userID, status);
    
    if([status isEqualToString:kStopVideoChatCallStatus_OpponentDidNotAnswer]){
        
        self.callAlert.delegate = nil;
        [self.callAlert dismissWithClickedButtonIndex:0 animated:YES];
        self.callAlert = nil;
     
        ringigngLabel.hidden = YES;
        
        ringingPlayer = nil;
    
    }else{
        myVideoView.hidden = YES;
        opponentVideoView.layer.borderWidth = 1;
    }
    
	opponentTextField.enabled = YES;
    callButton.hidden = NO;
	finishCallButton.hidden = YES;
	
    [[QBChat instance] unregisterWebRTCVideoChatInstance:self.videoChat];
}

- (void)chatCallDidStartWithUser:(NSUInteger)userID sessionID:(NSString *)sessionID
{
    [startingCallActivityIndicator stopAnimating];
}

- (void)didStartUseTURNForVideoChat
{
//    NSLog(@"_____TURN_____TURN_____");
}

 
#pragma mark -
#pragma mark UIAlertView

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        // Reject
        case 0:
            [self reject];
            break;
        // Accept
        case 1:
            [self accept];
            break;
            
        default:
            break;
    }
    
    self.callAlert = nil;
}

#pragma mark -
#pragma mark Background notification

- (void)didEnterBackground:(NSNotification *)notification
{
	[self finishCall];
}

@end
