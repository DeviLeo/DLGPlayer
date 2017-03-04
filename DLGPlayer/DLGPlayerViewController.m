//
//  DLGPlayerViewController.m
//  DLGPlayer
//
//  Created by Liu Junqi on 06/12/2016.
//  Copyright © 2016 Liu Junqi. All rights reserved.
//

#import "DLGPlayerViewController.h"
#import "DLGPlayerUtils.h"

typedef enum : NSUInteger {
    DLGPlayerOperationNone,
    DLGPlayerOperationOpen,
    DLGPlayerOperationPlay,
    DLGPlayerOperationPause,
    DLGPlayerOperationClose,
} DLGPlayerOperation;

@interface DLGPlayerViewController () {
    BOOL restorePlay;
    BOOL animatingHUD;
    NSTimeInterval showHUDTime;
}

@property (nonatomic) DLGPlayer *player;
@property (nonatomic) UIActivityIndicatorView *aivBuffering;

@property (nonatomic, weak) UIView *vTopBar;
@property (nonatomic, weak) UILabel *lblTitle;
@property (nonatomic, weak) UIView *vBottomBar;
@property (nonatomic, weak) UIButton *btnPlay;
@property (nonatomic, weak) UILabel *lblPosition;
@property (nonatomic, weak) UILabel *lblDuration;
@property (nonatomic, weak) UISlider *sldPosition;

@property (nonatomic) UITapGestureRecognizer *grTap;

@property (nonatomic) dispatch_source_t timer;
@property (nonatomic) BOOL updateHUD;
@property (nonatomic) NSTimer *timerForHUD;

@property (nonatomic, readwrite) DLGPlayerStatus status;
@property (nonatomic) DLGPlayerOperation nextOperation;

@end

@implementation DLGPlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self initAll];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self registerNotification];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self unregisterNotification];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self showHUD];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)registerNotification {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(notifyAppDidEnterBackground:)
               name:UIApplicationDidEnterBackgroundNotification object:nil];
    [nc addObserver:self selector:@selector(notifyAppWillEnterForeground:)
               name:UIApplicationWillEnterForegroundNotification object:nil];
    [nc addObserver:self selector:@selector(notifyPlayerOpened:) name:DLGPlayerNotificationOpened object:_player];
    [nc addObserver:self selector:@selector(notifyPlayerClosed:) name:DLGPlayerNotificationClosed object:_player];
    [nc addObserver:self selector:@selector(notifyPlayerEOF:) name:DLGPlayerNotificationEOF object:_player];
    [nc addObserver:self selector:@selector(notifyPlayerBufferStateChanged:) name:DLGPlayerNotificationBufferStateChanged object:_player];
}

- (void)unregisterNotification {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self];
}

#pragma mark - Init
- (void)initAll {
    [self initPlayer];
    [self initBuffering];
    [self initTopBar];
    [self initBottomBar];
    [self initGestures];
    self.status = DLGPlayerStatusNone;
    self.nextOperation = DLGPlayerOperationNone;
}

- (void)onPlayButtonTapped:(id)sender {
    if (_player.playing) {
        [self pause];
    } else {
        [self play];
    }
}

- (void)onSliderStartSlide:(id)sender {
    self.updateHUD = NO;
    self.grTap.enabled = NO;
}

- (void)onSliderValueChanged:(id)sender {
    UISlider *slider = sender;
    int seconds = slider.value;
    _lblPosition.text = [DLGPlayerUtils durationStringFromSeconds:seconds];
}

- (void)onSliderEndSlide:(id)sender {
    UISlider *slider = sender;
    float position = slider.value;
    _player.position = position;
    self.updateHUD = YES;
    self.grTap.enabled = YES;
}

- (void)syncHUD {
    [self syncHUD:NO];
}

- (void)syncHUD:(BOOL)force {
    if (!force) {
        if (_vTopBar.hidden) return;
        if (!_player.playing) return;
        if (!_updateHUD) return;
    }
    
    // position
    double position = _player.position;
    int seconds = ceil(position);
    _lblPosition.text = [DLGPlayerUtils durationStringFromSeconds:seconds];
    _sldPosition.value = seconds;
}

- (void)open {
    if (self.status == DLGPlayerStatusClosing) {
        self.nextOperation = DLGPlayerOperationOpen;
        return;
    }
    if (self.status != DLGPlayerStatusNone &&
        self.status != DLGPlayerStatusClosed) {
        return;
    }
    self.status = DLGPlayerStatusOpening;
    _aivBuffering.hidden = NO;
    [_aivBuffering startAnimating];
    [self.player open:_url];
}

- (void)close {
    if (self.status == DLGPlayerStatusOpening) {
        self.nextOperation = DLGPlayerOperationClose;
        return;
    }
    self.status = DLGPlayerStatusClosing;
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    [self.player close];
    [_btnPlay setTitle:@"|>" forState:UIControlStateNormal];
}

- (void)play {
    if (self.status == DLGPlayerStatusNone ||
        self.status == DLGPlayerStatusClosed) {
        [self open];
        self.nextOperation = DLGPlayerOperationPlay;
    }
    if (self.status != DLGPlayerStatusOpened &&
        self.status != DLGPlayerStatusPaused &&
        self.status != DLGPlayerStatusEOF) {
        return;
    }
    self.status = DLGPlayerStatusPlaying;
    [UIApplication sharedApplication].idleTimerDisabled = _preventFromScreenLock;
    [self.player play];
    [_btnPlay setTitle:@"||" forState:UIControlStateNormal];
}

- (void)replay {
    self.player.position = 0;
    [self play];
}

- (void)pause {
    if (self.status != DLGPlayerStatusOpened &&
        self.status != DLGPlayerStatusPlaying &&
        self.status != DLGPlayerStatusEOF) {
        return;
    }
    self.status = DLGPlayerStatusPaused;
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    [self.player pause];
    [_btnPlay setTitle:@"|>" forState:UIControlStateNormal];
}

- (BOOL)doNextOperation {
    if (_nextOperation == DLGPlayerOperationNone) return NO;
    switch (_nextOperation) {
        case DLGPlayerOperationOpen:
            [self open];
            break;
        case DLGPlayerOperationPlay:
            [self play];
            break;
        case DLGPlayerOperationPause:
            [self pause];
            break;
        case DLGPlayerOperationClose:
            [self close];
            break;
        default:
            break;
    }
    self.nextOperation = DLGPlayerOperationNone;
    return YES;
}

#pragma mark - Notifications
- (void)notifyAppDidEnterBackground:(NSNotification *)notif {
    if (_player.playing) {
        [self pause];
        if (_restorePlayAfterAppEnterForeground) restorePlay = YES;
    }
}

- (void)notifyAppWillEnterForeground:(NSNotification *)notif {
    if (restorePlay) {
        restorePlay = NO;
        [self play];
    }
}

- (void)notifyPlayerEOF:(NSNotification *)notif {
    self.status = DLGPlayerStatusEOF;
    if (_repeat) [self replay];
    else [self close];
}

- (void)notifyPlayerClosed:(NSNotification *)notif {
    self.status = DLGPlayerStatusClosed;
    [_aivBuffering stopAnimating];
    [self destroyTimer];
    [self doNextOperation];
}

- (void)notifyPlayerOpened:(NSNotification *)notif {
    dispatch_async(dispatch_get_main_queue(), ^{
        [_aivBuffering stopAnimating];
    });
    if (!_player.opened) {
        self.status = DLGPlayerStatusNone;
        [self doNextOperation];
        return;
    }
    
    self.status = DLGPlayerStatusOpened;
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *title = nil;
        if (_player.metadata != nil) {
            NSString *t = _player.metadata[@"title"];
            NSString *a = _player.metadata[@"artist"];
            if (t != nil) title = t;
            if (a != nil) title = [title stringByAppendingFormat:@" - %@", a];
        }
        if (title == nil) title = [_url lastPathComponent];
        _lblTitle.text = title;
        double duration = _player.duration;
        int seconds = ceil(duration);
        _lblDuration.text = [DLGPlayerUtils durationStringFromSeconds:seconds];
        _sldPosition.enabled = seconds > 0;
        _sldPosition.maximumValue = seconds;
        _sldPosition.minimumValue = 0;
        _sldPosition.value = 0;
        _updateHUD = YES;
        [self createTimer];
        [self showHUD];
    });
    if (![self doNextOperation]) {
        if (_autoplay) [self play];
    }
}

- (void)notifyPlayerBufferStateChanged:(NSNotification *)notif {
    NSDictionary *userInfo = notif.userInfo;
    BOOL state = [userInfo[DLGPlayerNotificationBufferStateKey] boolValue];
    if (state) {
        self.status = DLGPlayerStatusBuffering;
        [_aivBuffering startAnimating];
    } else {
        self.status = DLGPlayerStatusPlaying;
        [_aivBuffering stopAnimating];
    }
}

#pragma mark - UI
- (void)initPlayer {
    self.player = [[DLGPlayer alloc] init];
    UIView *v = _player.playerView;
    v.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:v];
    
    // Add constraints
    NSDictionary *views = NSDictionaryOfVariableBindings(v);
    NSArray<NSLayoutConstraint *> *ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[v]|"
                                                                                options:0
                                                                                metrics:nil
                                                                                  views:views];
    [self.view addConstraints:ch];
    NSArray<NSLayoutConstraint *> *cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[v]|"
                                                                                options:0
                                                                                metrics:nil
                                                                                  views:views];
    [self.view addConstraints:cv];
}

- (void)initBuffering {
    UIActivityIndicatorView *aiv = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    aiv.translatesAutoresizingMaskIntoConstraints = NO;
    aiv.hidesWhenStopped = YES;
    [self.view addSubview:aiv];
    
    UIView *playerView = _player.playerView;
    
    // Add constraints
    NSLayoutConstraint *cx = [NSLayoutConstraint constraintWithItem:aiv
                                                          attribute:NSLayoutAttributeCenterX
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:playerView
                                                          attribute:NSLayoutAttributeCenterX
                                                         multiplier:1
                                                           constant:0];
    NSLayoutConstraint *cy = [NSLayoutConstraint constraintWithItem:aiv
                                                          attribute:NSLayoutAttributeCenterY
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:playerView
                                                          attribute:NSLayoutAttributeCenterY
                                                         multiplier:1
                                                           constant:0];
    [self.view addConstraints:@[cx, cy]];
    self.aivBuffering = aiv;
}

- (void)initTopBar {
    CGRect frame = self.view.bounds;
    frame.size.height = 44;
    UIView *v = [[UIView alloc] initWithFrame:frame];
    v.translatesAutoresizingMaskIntoConstraints = NO;
    v.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];
    [self.view addSubview:v];
    NSDictionary *views = NSDictionaryOfVariableBindings(v);
    NSArray *ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[v]|"
                                                          options:0
                                                          metrics:nil
                                                            views:views];
    NSArray *cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[v(==44)]"
                                                          options:0
                                                          metrics:nil
                                                            views:views];
    [self.view addConstraints:ch];
    [self.view addConstraints:cv];
    
    // Title Label
    UILabel *lbltitle = [[UILabel alloc] init];
    lbltitle.translatesAutoresizingMaskIntoConstraints = NO;
    lbltitle.backgroundColor = [UIColor clearColor];
    lbltitle.text = @"DLGPlayer";
    lbltitle.font = [UIFont systemFontOfSize:15];
    lbltitle.textColor = [UIColor whiteColor];
    lbltitle.textAlignment = NSTextAlignmentCenter;
    [v addSubview:lbltitle];
    views = NSDictionaryOfVariableBindings(lbltitle);
    ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[lbltitle]-|" options:0 metrics:nil views:views];
    [v addConstraints:ch];
    cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[lbltitle]|" options:0 metrics:nil views:views];
    [v addConstraints:cv];
    
    self.vTopBar = v;
    self.lblTitle = lbltitle;
}

- (void)initBottomBar {
    CGRect frame = self.view.bounds;
    frame.size.height = 44;
    UIView *v = [[UIView alloc] initWithFrame:frame];
    v.translatesAutoresizingMaskIntoConstraints = NO;
    v.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];
    [self.view addSubview:v];
    NSDictionary *views = NSDictionaryOfVariableBindings(v);
    NSArray *ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[v]|"
                                                          options:0
                                                          metrics:nil
                                                            views:views];
    NSArray *cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[v(==44)]|"
                                                          options:0
                                                          metrics:nil
                                                            views:views];
    [self.view addConstraints:ch];
    [self.view addConstraints:cv];
    
    // Play/Pause Button
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.backgroundColor = [UIColor clearColor];
    [button setTitle:@"|>" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(onPlayButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [v addSubview:button];
    views = NSDictionaryOfVariableBindings(button);
    cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[button]|" options:0 metrics:nil views:views];
    [v addConstraints:cv];
    
    // Position Label
    UILabel *lblpos = [[UILabel alloc] init];
    lblpos.translatesAutoresizingMaskIntoConstraints = NO;
    lblpos.backgroundColor = [UIColor clearColor];
    lblpos.text = @"--:--:--";
    lblpos.font = [UIFont systemFontOfSize:15];
    lblpos.textColor = [UIColor whiteColor];
    lblpos.textAlignment = NSTextAlignmentCenter;
    [v addSubview:lblpos];
    views = NSDictionaryOfVariableBindings(lblpos);
    cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[lblpos]|" options:0 metrics:nil views:views];
    [v addConstraints:cv];
    
    UISlider *sldpos = [[UISlider alloc] init];
    sldpos.translatesAutoresizingMaskIntoConstraints = NO;
    sldpos.backgroundColor = [UIColor clearColor];
    sldpos.continuous = YES;
    [sldpos addTarget:self action:@selector(onSliderStartSlide:) forControlEvents:UIControlEventTouchDown];
    [sldpos addTarget:self action:@selector(onSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    [sldpos addTarget:self action:@selector(onSliderEndSlide:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
    [v addSubview:sldpos];
    views = NSDictionaryOfVariableBindings(sldpos);
    cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[sldpos]|" options:0 metrics:nil views:views];
    [v addConstraints:cv];
    
    UILabel *lblduration = [[UILabel alloc] init];
    lblduration.translatesAutoresizingMaskIntoConstraints = NO;
    lblduration.backgroundColor = [UIColor clearColor];
    lblduration.text = @"--:--:--";
    lblduration.font = [UIFont systemFontOfSize:15];
    lblduration.textColor = [UIColor whiteColor];
    lblduration.textAlignment = NSTextAlignmentCenter;
    [v addSubview:lblduration];
    views = NSDictionaryOfVariableBindings(lblduration);
    cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[lblduration]|" options:0 metrics:nil views:views];
    [v addConstraints:cv];
    
    views = NSDictionaryOfVariableBindings(button, lblpos, sldpos, lblduration);
    ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[button(==32)]-[lblpos(==72)]-[sldpos]-[lblduration(==72)]-|"
                                                 options:0
                                                 metrics:nil
                                                   views:views];
    [v addConstraints:ch];
    
    self.vBottomBar = v;
    self.btnPlay = button;
    self.lblPosition = lblpos;
    self.sldPosition = sldpos;
    self.lblDuration = lblduration;
}

- (void)initGestures {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapGesutreRecognizer:)];
    tap.numberOfTapsRequired = 1;
    tap.numberOfTouchesRequired = 1;
    [self.view addGestureRecognizer:tap];
    self.grTap = tap;
}

#pragma mark - Show/Hide HUD
- (void)showHUD {
    if (animatingHUD) return;
    [self syncHUD:YES];
    animatingHUD = YES;
    _vTopBar.hidden = NO;
    _vBottomBar.hidden = NO;
    [UIView animateWithDuration:0.5f
                     animations:^{
                         _vTopBar.alpha = 1.0f;
                         _vBottomBar.alpha = 1.0f;
                     }
                     completion:^(BOOL finished) {
                         animatingHUD = NO;
                     }];
    [self startTimerForHideHUD];
}

- (void)hideHUD {
    if (animatingHUD) return;
    animatingHUD = YES;
    [UIView animateWithDuration:0.5f
                     animations:^{
                         _vTopBar.alpha = 0.0f;
                         _vBottomBar.alpha = 0.0f;
                     }
                     completion:^(BOOL finished) {
                         _vTopBar.hidden = YES;
                         _vBottomBar.hidden = YES;
                         animatingHUD = NO;
                     }];
    [self stopTimerForHideHUD];
}

#pragma mark - Timer
- (void)startTimerForHideHUD {
    [self updateTimerForHideHUD];
    if (_timerForHUD != nil) return;
    self.timerForHUD = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(timerForHideHUD:) userInfo:nil repeats:YES];
}

- (void)stopTimerForHideHUD {
    if (_timerForHUD == nil) return;
    [_timerForHUD invalidate];
    self.timerForHUD = nil;
}

- (void)updateTimerForHideHUD {
    showHUDTime = [NSDate timeIntervalSinceReferenceDate];
}

- (void)timerForHideHUD:(NSTimer *)timer {
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    if (now - showHUDTime > 5) {
        [self hideHUD];
        [self stopTimerForHideHUD];
    }
}

#pragma mark - Gesture
- (void)onTapGesutreRecognizer:(UITapGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        if (_vTopBar.hidden) [self showHUD];
        else [self hideHUD];
    }
}

- (void)createTimer {
    if (_timer != nil) return;
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC, 1 * NSEC_PER_SEC);
    dispatch_source_set_event_handler(timer, ^{
        [self syncHUD];
    });
    dispatch_resume(timer);
    self.timer = timer;
}

- (void)destroyTimer {
    if (_timer == nil) return;
    dispatch_cancel(_timer);
    self.timer = nil;
}

@end
