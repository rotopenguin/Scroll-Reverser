#import "ScrollInverterAppDelegate.h"
#import "StatusItemController.h"
#import "LoginItemsController.h"
#import "MouseTap.h"
#import "NSObject+ObservePrefs.h"
#import "WelcomeWindowController.h"
#import <Sparkle/SUUpdater.h>

NSString *const PrefsReverseScrolling=@"InvertScrollingOn";
NSString *const PrefsReverseHorizontal=@"ReverseX";
NSString *const PrefsReverseVertical=@"ReverseY";
NSString *const PrefsReverseTrackpad=@"ReverseTrackpad";
NSString *const PrefsReverseMouse=@"ReverseMouse";
NSString *const PrefsReverseTablet=@"ReverseTablet";
NSString *const PrefsHasRunBefore=@"HasRunBefore";
NSString *const PrefsHideIcon=@"HideIcon";

@implementation ScrollInverterAppDelegate

+ (void)initialize
{
	if ([self class]==[ScrollInverterAppDelegate class])
    {
		[[NSUserDefaults standardUserDefaults] registerDefaults:@{
        PrefsReverseScrolling: @(YES),
        PrefsReverseHorizontal: @(NO),
        PrefsReverseVertical: @(YES),
        PrefsReverseTrackpad: @(YES),
        PrefsReverseMouse: @(YES),
        PrefsReverseTablet: @(YES),
        @"MinZeros": @2,
        @"MinFingers": @2}];
	}
}

- (void)updateTap
{
	tap->inverting=[[NSUserDefaults standardUserDefaults] boolForKey:PrefsReverseScrolling];
    tap->invertX=[[NSUserDefaults standardUserDefaults] boolForKey:PrefsReverseHorizontal];
    tap->invertY=[[NSUserDefaults standardUserDefaults] boolForKey:PrefsReverseVertical];
    tap->invertMultiTouch=[[NSUserDefaults standardUserDefaults] boolForKey:PrefsReverseTrackpad];
    tap->invertTablet=[[NSUserDefaults standardUserDefaults] boolForKey:PrefsReverseTablet];
    tap->invertOther=[[NSUserDefaults standardUserDefaults] boolForKey:PrefsReverseMouse];
}

- (id)init
{
	self=[super init];
	if (self) {
        tap=[[MouseTap alloc] init];
		[self updateTap];
        
		statusController=[[StatusItemController alloc] init];
		loginItemsController=[[LoginItemsController alloc] init];
        
        [self observePrefsKey:PrefsReverseScrolling];
        [self observePrefsKey:PrefsReverseHorizontal];
        [self observePrefsKey:PrefsReverseVertical];
        [self observePrefsKey:PrefsReverseTrackpad];
        [self observePrefsKey:PrefsReverseMouse];
        [self observePrefsKey:PrefsReverseTablet];
        [self observePrefsKey:PrefsHideIcon];
        
        [[SUUpdater sharedUpdater] setDelegate:self];
    }
	return self;
}

- (IBAction)startAtLoginClicked:(id)sender
{
    const BOOL newState=![loginItemsController startAtLogin];
    [loginItemsController setStartAtLogin:newState];
    [startAtLoginMenu setState:newState];
}

- (void)awakeFromNib
{
	[statusController attachMenu:statusMenu];
	[loginItemsController addObserver:self forKeyPath:@"startAtLogin" options:NSKeyValueObservingOptionInitial context:nil];
}
	
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	const BOOL first=![[NSUserDefaults standardUserDefaults] boolForKey:PrefsHasRunBefore];
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:PrefsHasRunBefore];
	if(first) {
        welcomeWindowController=[[WelcomeWindowController alloc] initWithWindowNibName:@"WelcomeWindow"];
        [welcomeWindowController showWindow:self];
	}
	[tap start];
}

- (IBAction)showAbout:(id)sender
{
	[NSApp activateIgnoringOtherApps:YES];
    NSDictionary *dict=@{@"ApplicationName": @"Scroll Reverser"};
    [NSApp orderFrontStandardAboutPanelWithOptions:dict];
}

- (IBAction)checkForUpdatesClicked:(id)sender
{
    // check for updates whenever the Check For Updates is set to 'on'.
    // do it asynchronously to allow menu item state to change.
    dispatch_async(dispatch_get_current_queue(), ^{
        if ([sender state]==NSOnState) {
            [[SUUpdater sharedUpdater] checkForUpdatesInBackground];
        }        
    });
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag
{
	[[NSUserDefaults standardUserDefaults] setBool:NO forKey:PrefsHideIcon];
	return NO;
}

- (void)handleHideIconChange
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:PrefsHideIcon])
    {
		[NSApp activateIgnoringOtherApps:YES];
        NSAlert *alert=[NSAlert alertWithMessageText:NSLocalizedString(@"Status Icon Hidden",nil)
                                       defaultButton:NSLocalizedString(@"OK",nil)
                                     alternateButton:NSLocalizedString(@"Restore Now",nil)
                                         otherButton:nil
                           informativeTextWithFormat:NSLocalizedString(@"MENU_HIDDEN_TEXT", @"text shown when the menu bar icon is hidden")];
        const unsigned long button=[alert runModal];
        if (button==NSAlertAlternateReturn) {
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:PrefsHideIcon];
        }
    }    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object==loginItemsController) {
        [startAtLoginMenu setState:[loginItemsController startAtLogin]];
    }
    else if ([keyPath hasSuffix:@"HideIcon"]) {
        // run it asynchronously, because we shouldn't change the pref back inside the observer
        [self performSelector:@selector(handleHideIconChange) withObject:nil afterDelay:0.001];
    }
    else {
        [self updateTap];
    }
}

#pragma mark Sparkle delegate methods

- (NSArray *)feedParametersForUpdater:(SUUpdater *)updater sendingSystemProfile:(BOOL)sendingProfile
{
    NSLog(@"Checking for updates");
    return [NSArray array];
}

#pragma mark Strings

- (NSString *)menuStringReverseScrolling {
	return NSLocalizedString(@"Reverse Scrolling", nil);
}
- (NSString *)menuStringAbout {
	return NSLocalizedString(@"About", nil);
}
- (NSString *)menuStringPreferences {
	return NSLocalizedString(@"Preferences", nil);
}
- (NSString *)menuStringCheckForUpdates {
	return NSLocalizedString(@"Check For Updates", nil);
}
- (NSString *)menuStringCheckNow {
	return NSLocalizedString(@"Check Now...", nil);
}
- (NSString *)menuStringQuit {
	return NSLocalizedString(@"Quit Scroll Reverser", nil);
}
- (NSString *)menuStringStartAtLogin {
	return NSLocalizedString(@"Start at Login", nil);
}
- (NSString *)menuStringShowInMenuBar {
	return NSLocalizedString(@"Show in Menu Bar", nil);
}
- (NSString *)menuStringHorizontal {
	return NSLocalizedString(@"Reverse Horizontal", nil);
}
- (NSString *)menuStringVertical {
	return NSLocalizedString(@"Reverse Vertical", nil);
}
- (NSString *)menuStringTrackpad {
	return NSLocalizedString(@"Reverse Trackpad", nil);
}
- (NSString *)menuStringMouse {
	return NSLocalizedString(@"Reverse Mouse", nil);
}
- (NSString *)menuStringTablet {
	return NSLocalizedString(@"Reverse Tablet", nil);
}

@end

