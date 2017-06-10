//
//  ViewController.m
//  DLGPlayer
//
//  Created by Liu Junqi on 29/11/2016.
//  Copyright © 2016 Liu Junqi. All rights reserved.
//

#import "ViewController.h"
#import "DLGPlayerViewController.h"

@interface ViewController () <UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UIView *vContainer;
@property (nonatomic, weak) IBOutlet UITextField *tfUrl;
@property (nonatomic) DLGPlayerViewController *vcDLGPlayer;
@property (nonatomic) BOOL fullscreen;
@property (nonatomic) BOOL landscape;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _tfUrl.delegate = self;
    _tfUrl.text = _url;
    [self updateTitle];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [_vcDLGPlayer close];
    [self unregisterNotification];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self initDLGPlayer];
    [self registerNotification];
    [self go];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)registerNotification {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(notifyPlayerError:) name:DLGPlayerNotificationError object:_vcDLGPlayer];
}

- (void)unregisterNotification {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self];
}

- (void)notifyPlayerError:(NSNotification *)notif {
    NSDictionary *userInfo = notif.userInfo;
    NSError *error = userInfo[DLGPlayerNotificationErrorKey];
    BOOL isAudioError = [error.domain isEqualToString:DLGPlayerErrorDomainAudioManager];
    NSString *title = isAudioError ? @"Audio Error" : @"Error";
    NSString *message = error.localizedDescription;
    if (isAudioError) {
        NSError *rawError = error.userInfo[NSLocalizedFailureReasonErrorKey];
        message = [message stringByAppendingFormat:@"\n%@", rawError];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK"
                                                     style:UIAlertActionStyleCancel
                                                   handler:nil];
        [alert addAction:ok];
        [self presentViewController:alert animated:YES completion:nil];
    });
}

- (void)updateTitle {
    if (_tfUrl.text.length == 0) {
        self.navigationItem.title = @"DLGPlayer";
    } else {
        self.navigationItem.title = [_tfUrl.text lastPathComponent];
    }
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField.returnKeyType == UIReturnKeyGo) {
        [textField resignFirstResponder];
        [self go];
    }
    return YES;
}

- (void)go {
    if (_tfUrl.text.length == 0) return;
    [self updateTitle];
    _vcDLGPlayer.url = _tfUrl.text;
    [_vcDLGPlayer close];
    [_vcDLGPlayer open];
}

- (void)initDLGPlayer {
    if (_vcDLGPlayer != nil) {
        [_vcDLGPlayer.view removeFromSuperview];
        self.vcDLGPlayer = nil;
    }
    DLGPlayerViewController *vc = [[DLGPlayerViewController alloc] init];
    vc.view.translatesAutoresizingMaskIntoConstraints = YES;
    vc.view.frame = self.vContainer.frame;
    vc.autoplay = YES;
    vc.repeat = YES;
    vc.preventFromScreenLock = YES;
    vc.restorePlayAfterAppEnterForeground = YES;
    [self.view addSubview:vc.view];
    self.vcDLGPlayer = vc;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    BOOL isLandscape = size.width > size.height;
    [coordinator animateAlongsideTransition:nil
                                 completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
                                     self.landscape = isLandscape;
                                 }];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    if ([_tfUrl canResignFirstResponder]) [_tfUrl resignFirstResponder];
    
    UITouch *touch = [touches anyObject];
    if (touch.tapCount == 2) {
        self.fullscreen = !self.fullscreen;
    }
}

- (void)setFullscreen:(BOOL)fullscreen {
    _fullscreen = fullscreen;
    [self updatePlayerFrame];
}

- (void)setLandscape:(BOOL)landscape {
    _landscape = landscape;
    [self updatePlayerFrame];
}

- (void)updatePlayerFrame {
    BOOL fullscreen = _landscape || _fullscreen;
    [self.navigationController setNavigationBarHidden:fullscreen animated:YES];
    [[UIApplication sharedApplication] setStatusBarHidden:fullscreen withAnimation:YES];
    [self setNeedsStatusBarAppearanceUpdate];
    [UIView animateWithDuration:0.2f
                     animations:^{
                         _vcDLGPlayer.view.frame = fullscreen ? self.view.frame : _vContainer.frame;
                     }];
}

- (BOOL)prefersStatusBarHidden {
    return (_landscape || _fullscreen);
}

@end
