//
//  TTViewController.m
//  UITableViewNavigation
//
//  Created by sergey on 4/26/14.
//  Copyright (c) 2014 sergey. All rights reserved.
//

#import "TTViewController.h"

typedef enum {
    TTCreateFolder,
    TTBackToRoot
} TTActionSheetSection;

@interface TTViewController () <UITableViewDataSource,UITableViewDelegate,UIActionSheetDelegate,UIAlertViewDelegate,UITextFieldDelegate>

@property (weak,nonatomic) UITableView *tabelView;
@property (strong,nonatomic) NSArray *folderItem;
@property (strong,nonatomic) NSMutableArray *item;
@property (strong,nonatomic) NSString* path;

@end

@implementation TTViewController

- (id)initWithFolderPath:(NSString *)path {
    self = [super init];
    if (self) {
        self.path = path;
        self.folderItem = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.path error:nil];
    }
    return self;
}

- (void)loadView {
    [super loadView];
    
    CGRect rect = self.view.bounds;
    rect.origin = CGPointZero;
    
    UITableView *tabelView = [[UITableView alloc]initWithFrame:rect style:UITableViewStylePlain];
    tabelView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
    tabelView.dataSource = self;
    tabelView.delegate = self;
    tabelView.separatorInset = UIEdgeInsetsZero;
    tabelView.backgroundColor = [UIColor colorWithRed:0.192 green:0.192 blue:0.192 alpha:1.000];
    tabelView.separatorColor = [UIColor colorWithRed:0.114 green:0.118 blue:0.098 alpha:1.000];
    
    [self.view addSubview:tabelView];
    self.tabelView = tabelView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = [self.path lastPathComponent];
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:0.192 green:0.192 blue:0.192 alpha:1.000];
    self.item = [[NSMutableArray alloc]init];
    
    for (NSString *fileName in self.folderItem) {
        if (![fileName rangeOfString:@"."].location == 0) {
            [self.item addObject:fileName];
        }
    }
    
    NSArray *sortedArray = [self.item sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {

        if ([self isFile:obj1] && [self isFile:obj2]) {
            return [obj1 compare:obj2];
        } else if ([self isFile:obj1] && ![self isFile:obj2]) {
            return NSOrderedDescending;
        } else {
            return ![obj1 compare:obj2];
        }
    }];
    
    self.item = [NSMutableArray arrayWithArray:sortedArray];
    
    UIBarButtonItem *item = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(goToRoot:)];

    self.navigationItem.rightBarButtonItem = item;
}

#pragma mark - Methods

- (void) goToRoot:(UIBarButtonItem *)sender {
    
    UIActionSheet* sheet;
    
    if ([self.navigationController.viewControllers count] > 1) {
        sheet = [[UIActionSheet alloc]initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Create Folder",@"Go to root directory", nil];
    } else {
        sheet = [[UIActionSheet alloc]initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Create Folder", nil];
    }
    
    [sheet showFromBarButtonItem:sender animated:YES];
}

- (BOOL) isDirectory:(NSIndexPath *)indexPath {
    
    BOOL isDirectory = NO;
    
    NSString *path = [self.path stringByAppendingPathComponent:[self.item objectAtIndex:indexPath.row]];
    
    [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
    
    return isDirectory;
}

- (BOOL) isFile:(id)obj {
    
    BOOL isFile = NO;
    
    NSString *path = [self.path stringByAppendingPathComponent:obj];
    
    [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isFile];
    
    return !isFile;
}

- (void) createFolderWithName:(NSString *)name {
    if (name != nil) {
        
        BOOL isFolder;
        NSString *filePath = [self.path stringByAppendingPathComponent:name];
        NSFileManager *fileManager= [NSFileManager defaultManager];
        if(![fileManager fileExistsAtPath:filePath isDirectory:&isFolder]) {
            if(![fileManager createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:NULL]) {
                NSLog(@"Create folder failed %@", filePath);
            }
        }
        
        NSUInteger insertIndex = 0;
        
        [self.item insertObject:name atIndex:insertIndex];
        
        [self.tabelView beginUpdates];
        
        NSIndexPath *indexpath = [NSIndexPath indexPathForItem:insertIndex inSection:insertIndex];
        
        [self.tabelView insertRowsAtIndexPaths:[NSArray arrayWithObject:indexpath] withRowAnimation:UITableViewRowAnimationTop];
        
        [self.tabelView endUpdates];
        
    }
}

- (unsigned long long)sizeOfFolder:(NSString *)folderPath {
    
    unsigned long long int result = 0;
        
    NSArray *array = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:folderPath error:nil];
    
        for (NSString *fileSystemItem in array) {
            BOOL directory = NO;
            [[NSFileManager defaultManager] fileExistsAtPath:[folderPath stringByAppendingPathComponent:fileSystemItem] isDirectory:&directory];
            if (!directory) {
                result += [[[[NSFileManager defaultManager] attributesOfItemAtPath:[folderPath stringByAppendingPathComponent:fileSystemItem] error:nil] objectForKey:NSFileSize] unsignedIntegerValue];
            }
            else {
                result += [self sizeOfFolder:[folderPath stringByAppendingPathComponent:fileSystemItem]];
            }
        }
        
    return result;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    NSCharacterSet * set = [[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLKMNOPQRSTUVWXYZ0123456789"] invertedSet];
    if ([string rangeOfCharacterFromSet:set].location != NSNotFound) {
        return NO;
    } else {
        return YES;
    }

}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (buttonIndex == 1) {
        UITextField *textfild = [alertView textFieldAtIndex:0];

        [self createFolderWithName:textfild.text];
    }
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (buttonIndex == TTCreateFolder) {
        UIAlertView * alertView = [[UIAlertView alloc]initWithTitle:@"set folder name" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK",nil];
        alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
        [alertView textFieldAtIndex:0].keyboardAppearance = UIKeyboardAppearanceDark;
        [alertView textFieldAtIndex:0].delegate = self;
        [alertView show];
        
    } else if (buttonIndex == TTBackToRoot) {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.item count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *identifier = @"cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
    }
    
    NSString *fileName = [self.item objectAtIndex:indexPath.row];
    NSString *filePath = [self.path stringByAppendingPathComponent:fileName];
    
    if (![self isDirectory:indexPath]) {
        
        NSDictionary *data = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
        cell.detailTextLabel.text = [NSByteCountFormatter stringFromByteCount:[data fileSize] countStyle:NSByteCountFormatterCountStyleFile];
        
    } else {
        
        NSString *folderSizeStr = [NSByteCountFormatter stringFromByteCount:[self sizeOfFolder:filePath] countStyle:NSByteCountFormatterCountStyleFile];
        cell.detailTextLabel.text = folderSizeStr;
    }
    
    cell.textLabel.text = fileName;

    
    if ([self isDirectory:indexPath]) {
        cell.imageView.image = [UIImage imageNamed:@"folder.png"];
    } else {
        cell.imageView.image = [UIImage imageNamed:@"file.png"];
    }
    
    cell.textLabel.textColor = [UIColor colorWithRed:0.231 green:0.616 blue:0.925 alpha:1.000];
    cell.detailTextLabel.textColor = [UIColor colorWithRed:0.933 green:0.467 blue:0.078 alpha:1.000];
    cell.backgroundColor = [UIColor colorWithRed:0.192 green:0.192 blue:0.192 alpha:1.000];
    cell.tintColor = [UIColor colorWithRed:0.192 green:0.192 blue:0.192 alpha:1.000];
    
    return cell;
    
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    BOOL isFolder;
    NSError *error;
    NSString *filePath = [self.path stringByAppendingPathComponent:[self.item objectAtIndex:indexPath.row]];
    NSFileManager *fileManager= [NSFileManager defaultManager];
    
    if([fileManager fileExistsAtPath:filePath isDirectory:&isFolder]) {
        
        if(![fileManager removeItemAtPath:filePath error:&error]) {
            NSLog(@"Delete folder failed %@", filePath);
        }
    }
    
    [self.item removeObjectAtIndex:indexPath.row];
    
    [self.tabelView beginUpdates];
    
    [self.tabelView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationRight];
    
    [self.tabelView endUpdates];
    
}

#pragma mark - UITabelViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if ([self isDirectory:indexPath]) {
        
        NSString *path = [self.path stringByAppendingPathComponent:[self.item objectAtIndex:indexPath.row]];
        
        TTViewController *vc = [[TTViewController alloc]initWithFolderPath:path];
        
        [self.navigationController pushViewController:vc animated:YES];
        
    }
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
