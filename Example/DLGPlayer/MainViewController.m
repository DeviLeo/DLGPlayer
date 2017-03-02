//
//  MainViewController.m
//  DLGPlayer
//
//  Created by DeviLeo on 2017/2/26.
//  Copyright © 2017年 Liu Junqi. All rights reserved.
//

#import "MainViewController.h"
#import "ViewController.h"
#import "FileManagementViewController.h"

@interface MainViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate> {
    NSString *_urlForSegue;
}

@property (nonatomic, weak) IBOutlet UITextField *tfUrl;
@property (nonatomic, weak) IBOutlet UITableView *tvTableView;
@property (nonatomic, weak) IBOutlet UIToolbar *tbToolbar;

@property (nonatomic) NSArray *menu;
@property (nonatomic) NSMutableArray *history;

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationItem.title = @"DLGPlayer";
    _tfUrl.delegate = self;
    _tvTableView.delegate = self;
    _tvTableView.dataSource = self;
    [self initVars];
    [self initToolbarItems:NO];
    [self registerNotifications];
}

- (void)dealloc {
    [self unregisterNotifications];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)registerNotifications {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(notifyAddUrlToHistory:) name:FMVNotificationAddUrlToHistory object:nil];
}

- (void)unregisterNotifications {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self];
}

#pragma mark - Init
- (void)initVars {
    self.menu = @[
                  @{
                      @"title":@"Local Files",
                      @"action":NSStringFromSelector(@selector(onMenuLocalFilesTapped))
                    }
                  ];
    [self loadHistory];
}

- (void)initToolbarItems:(BOOL)editing {
    UIBarButtonItem *bbi = nil;
    if (editing) {
        UIBarButtonItem *bbiDone = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                 target:self
                                                                                 action:@selector(onDoneTapped:)];
        bbi = bbiDone;
    } else {
        UIBarButtonItem *bbiEdit = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
                                                                                 target:self
                                                                                 action:@selector(onEditTapped:)];
        bbi = bbiEdit;
    }
    UIBarButtonItem *bbiFlex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                             target:nil
                                                                             action:nil];
    UIBarButtonItem *bbiTrash = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
                                                                             target:self
                                                                                  action:@selector(onTrashTapped:)];
    [_tbToolbar setItems:@[bbi, bbiFlex, bbiTrash] animated:YES];
}

#pragma mark - Action
- (void)onEditTapped:(id)sender {
    [_tvTableView setEditing:YES animated:YES];
    [self initToolbarItems:YES];
}

- (void)onDoneTapped:(id)sender {
    [_tvTableView setEditing:NO animated:YES];
    [self initToolbarItems:NO];
}

- (void)onTrashTapped:(id)sender {
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"Delete All History"
                                                                message:@"Are you sure to delete all history?"
                                                         preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *delete = [UIAlertAction actionWithTitle:@"Delete"
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * _Nonnull action) {
                                                       [self deleteAllHistory];
                                                   }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel"
                                                     style:UIAlertActionStyleCancel
                                                   handler:nil];
    [ac addAction:delete];
    [ac addAction:cancel];
    [self presentViewController:ac animated:YES completion:nil];
}

- (void)onMenuLocalFilesTapped {
    [self performSegueWithIdentifier:@"m2fm" sender:self];
}

#pragma mark - Notification
- (void)notifyAddUrlToHistory:(NSNotification *)notif {
    NSDictionary *userinfo = notif.userInfo;
    NSString *url = userinfo[@"url"];
    [self addHistoryUrl:url];
}

#pragma mark - History
- (void)addHistoryUrl:(NSString *)url {
    NSTimeInterval dt = [NSDate timeIntervalSinceReferenceDate];
    
    NSInteger count = _history.count;
    for (NSInteger i = 0; i < count; ++i) {
        NSMutableDictionary *obj = _history[i];
        if ([obj[@"url"] isEqualToString:url]) {
            [_history removeObjectAtIndex:i];
            break;
        }
    }
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"url"] = url;
    dict[@"dt"] = @(dt);
    [_history insertObject:dict atIndex:0];
    [self saveHistory];
    [_tvTableView reloadData];
}

- (void)deleteHistoryAtIndex:(NSInteger)index {
    [_history removeObjectAtIndex:index];
    [self saveHistory];
}

- (void)loadHistory {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSArray *array = [ud objectForKey:@"history"];
    if (array == nil) self.history = [NSMutableArray array];
    else self.history = [NSMutableArray arrayWithArray:array];
    [_tvTableView reloadData];
}

- (void)saveHistory {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setObject:_history forKey:@"history"];
    [ud synchronize];
}

- (void)deleteAllHistory {
    [self.history removeAllObjects];
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud removeObjectForKey:@"history"];
    [ud synchronize];
    [_tvTableView reloadData];
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField.returnKeyType == UIReturnKeyGo) {
        [textField resignFirstResponder];
        NSString *url = textField.text;
        if (url.length > 0) {
            [self addHistoryUrl:url];
            _urlForSegue = [self checkUrl:url];
            [self performSegueWithIdentifier:@"m2v" sender:self];
        }
    }
    return YES;
}

- (BOOL)isLocalFile:(NSString *)url {
    NSRange range = [url rangeOfString:@":"];
    BOOL isLocalFile = (range.location == NSNotFound);
    if (!isLocalFile) {
        NSString *protocol = [url substringToIndex:range.location];
        if ([protocol compare:@"file" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
            isLocalFile = YES;
        }
    }
    return isLocalFile;
}

- (NSString *)checkUrl:(NSString *)url {
    NSString *finalurl = url;
    NSRange range = [url rangeOfString:@":"];
    if (range.location == NSNotFound) { // file
        if ([url characterAtIndex:0] != '/') { // relative
            NSString *doc = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
            url = [doc stringByAppendingPathComponent:url];
        } // else absolute 
        finalurl = [NSString stringWithFormat:@"file://%@", url];
    } // else network url or file://
    return finalurl;
}

- (NSString *)cellTextUrl:(NSString *)url {
    NSString *finalUrl = url;
    if ([self isLocalFile:url]) finalUrl = [url lastPathComponent];
    return finalUrl;
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if (section == 0) return _menu.count;
    else return _history.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FileCell" forIndexPath:indexPath];
    
    cell.textLabel.numberOfLines = 0;
    if (indexPath.section == 0) {
        NSDictionary *dict = _menu[indexPath.row];
        cell.textLabel.text = dict[@"title"];
    } else {
        NSDictionary *dict = _history[indexPath.row];
        NSString *url = dict[@"url"];
        cell.textLabel.text = [self cellTextUrl:url];
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) return @"Menu";
    else return @"History";
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) return 44;
    return UITableViewAutomaticDimension;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 0) {
        NSDictionary *dict = _menu[indexPath.row];
        NSString *selName = dict[@"action"];
        SEL sel = NSSelectorFromString(selName);
        IMP imp = [self methodForSelector:sel];
        void (*func)(id, SEL) = (void *)imp;
        func(self, sel);
    } else {
        NSInteger row = indexPath.row;
        if (row < _history.count) {
            NSDictionary *dict = _history[row];
            NSString *url = dict[@"url"];
            [self addHistoryUrl:url];
            _urlForSegue = [self checkUrl:url];
            [self performSegueWithIdentifier:@"m2v" sender:self];
        }
    }
    
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) return NO;
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) return UITableViewCellEditingStyleNone;
    return UITableViewCellEditingStyleDelete;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) return;
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSInteger row = indexPath.row;
        if (row < _history.count) {
            [self deleteHistoryAtIndex:row];
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"m2v"]) {
        ViewController *vc = segue.destinationViewController;
        vc.url = _urlForSegue;
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    if ([_tfUrl canResignFirstResponder]) [_tfUrl resignFirstResponder];
}

@end
