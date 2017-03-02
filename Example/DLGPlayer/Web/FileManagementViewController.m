//
//  FileManagementViewController.m
//  DLGPlayer
//
//  Created by DeviLeo on 2017/2/26.
//  Copyright © 2017年 Liu Junqi. All rights reserved.
//

#import "FileManagementViewController.h"
#import "HTTPServer.h"
#import "HTTPUploader.h"
#import "WebUtils.h"
#import "ViewController.h"

@interface FileManagementViewController () <UITableViewDataSource, UITableViewDelegate> {
    NSString *_urlForSegue;
}

@property (nonatomic, weak) IBOutlet UILabel *lblUrlTips;
@property (nonatomic, weak) IBOutlet UILabel *lblUrl;
@property (nonatomic, weak) IBOutlet UITableView *tvFiles;
@property (nonatomic, weak) IBOutlet UIToolbar *tbToolbar;

@property (nonatomic) HTTPServer *server;
@property (nonatomic) NSMutableArray *files;

@end

@implementation FileManagementViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationItem.title = @"File Manager";
    _lblUrlTips.text = @"To upload files from your computer,\nplease type the following url into the browser.";
    
    UIBarButtonItem *bbiEdit = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
                                                                             target:self
                                                                             action:@selector(onEditTapped:)];
    [_tbToolbar setItems:@[bbiEdit] animated:YES];
    
    self.files = [[NSMutableArray alloc] init];
}

- (void)viewWillAppear:(BOOL)animated {
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    [self startServer];
}

- (void)viewWillDisappear:(BOOL)animated {
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    [self stopServer];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)reload {
    [_files removeAllObjects];
    NSError *error = nil;
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSArray *a = [fm contentsOfDirectoryAtPath:docPath error:&error];
    if (error) {
        NSLog(@"contentsOfDirectoryAtPath:%@ error:%@", docPath, error);
        return;
    }
    for (NSString *filename in a) {
        [_files addObject:filename];
    }
    
    [_files sortUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
        return [obj1 compare:obj2 options:NSNumericSearch] == NSOrderedDescending;
    }];
    
    [_tvFiles reloadData];
}

#pragma mark - HTTP Server
- (BOOL)startServer {
    if (_server != nil) {
        if (_server.isRunning) { return YES; }
        else { [self stopServer]; }
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifyRefreshFileList:) name:HttpUploadNotificationRefreshFileList object:nil];
    
    // Create server using our custom MyHTTPServer class
    self.server = [[HTTPServer alloc] init];
    
    // Tell the server to broadcast its presence via Bonjour.
    // This allows browsers such as Safari to automatically discover our service.
    [_server setType:@"_http._tcp."];
    
    // Normally there's no need to run our server on any specific port.
    // Technologies like Bonjour allow clients to dynamically discover the server's port at runtime.
    // However, for easy testing you may want force a certain port so you can just hit the refresh button.
    [_server setPort:80];
    
    // Serve files from our embedded Web folder
    NSString *webPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"web"];
    NSLog(@"Setting document root: %@", webPath);
    
    [_server setDocumentRoot:webPath];
    
    [_server setConnectionClass:[HTTPUploader class]];
    
    // Start the server (and check for problems)
    NSString *ipv4 = nil;
    NSString *ipv6 = nil;
    BOOL success = [WebUtils getIpAddress:&ipv4 ipv6:&ipv6];
    if (success) {
        NSString *ipAddress = ipv4;
        if (ipAddress == nil) ipAddress = [NSString stringWithFormat:@"[%@]", ipv6];
        NSError *error;
        if([_server start:&error]) {
            _lblUrl.text = [NSString stringWithFormat:@"http://%@", ipAddress];
            NSLog(@"Started HTTP Server on port %hu", [_server listeningPort]);
            success = YES;
        } else {
            NSLog(@"Error starting HTTP Server: %@", error);
            [_server setPort:8080];
            if ([_server start:&error]) {
                _lblUrl.text = [NSString stringWithFormat:@"http://%@:%hu", ipAddress, [_server listeningPort]];
                NSLog(@"Started HTTP Server on port %hu", [_server listeningPort]);
                success = YES;
            } else {
                NSLog(@"Error starting HTTP Server: %@", error);
                [_server setPort:0];
                if ([_server start:&error]) {
                    _lblUrl.text = [NSString stringWithFormat:@"http://%@:%hu", ipAddress, [_server listeningPort]];
                    NSLog(@"Started HTTP Server on port %hu", [_server listeningPort]);
                    success = YES;
                } else {
                    NSLog(@"Error starting HTTP Server: %@", error);
                }
            }
        }
        
        if (!success) { [self stopServer]; }
    } else {
        _lblUrl.text = @"Please connect to WIFI and try again.";
    }
    
    [self reload];
    
    return success;
}

- (void)stopServer {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HttpUploadNotificationRefreshFileList object:nil];
    [_server stop];
    self.server = nil;
}

#pragma mark - Notification
- (void)notifyRefreshFileList:(NSNotification *)notif {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self reload];
    });
}

#pragma mark - Action
- (void)onEditTapped:(id)sender {
    [_tvFiles setEditing:YES animated:YES];
    
    UIBarButtonItem *bbiFlex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                             target:nil
                                                                             action:nil];
    UIBarButtonItem *bbiDone = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                             target:self
                                                                             action:@selector(onDoneTapped:)];
    [_tbToolbar setItems:@[bbiFlex, bbiDone] animated:YES];
}

- (void)onDoneTapped:(id)sender {
    [_tvFiles setEditing:NO animated:YES];
    UIBarButtonItem *bbiEdit = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
                                                                             target:self
                                                                             action:@selector(onEditTapped:)];
    [_tbToolbar setItems:@[bbiEdit] animated:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return _files.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FileCell" forIndexPath:indexPath];
    
    // Configure the cell...
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.text = [_files objectAtIndex:indexPath.row];
    
    return cell;
}

#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSInteger row = indexPath.row;
    if (row < _files.count) {
        NSString *filename = [_files objectAtIndex:row];
        NSString *filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        NSString *fullPath = [filePath stringByAppendingPathComponent:filename];
        _urlForSegue = [NSString stringWithFormat:@"file://%@", fullPath];
        [[NSNotificationCenter defaultCenter] postNotificationName:FMVNotificationAddUrlToHistory object:nil userInfo:@{@"url":filename}];
        [self performSegueWithIdentifier:@"fm2v" sender:self];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSInteger row = indexPath.row;
        if (row < _files.count) {
            NSString *filename = [_files objectAtIndex:row];
            NSString *filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
            NSString *fullPath = [filePath stringByAppendingPathComponent:filename];
            NSError *error = nil;
            if ([[NSFileManager defaultManager] removeItemAtPath:fullPath error:&error]) {
                [_files removeObjectAtIndex:row];
                [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            } else {
                NSLog(@"Failed to delete file: %@ error: %@", filePath, error);
            }
        }
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"fm2v"]) {
        ViewController *vc = segue.destinationViewController;
        vc.url = _urlForSegue;
    }
}


@end
