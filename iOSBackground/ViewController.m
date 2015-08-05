//
//  ViewController.m
//  iOSBackground
//
//  Created by Richard Lee on 8/4/15.
//  Copyright (c) 2015 weimed. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;

- (IBAction)start:(id)sender;
@end

@implementation ViewController

static NSString *DownloadURLString = @"https://developer.apple.com/library/ios/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/RemoteNotificationsPG.pdf";

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.session = [self backgroundSession];

    self.progressView.progress = 0;
    self.progressView.hidden = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)start:(id)sender {
    if (self.downloadTask) {
        return;
    }

    NSURL *downloadURL = [NSURL URLWithString:DownloadURLString];
    NSURLRequest *request = [NSURLRequest requestWithURL:downloadURL];
    self.downloadTask = [self.session downloadTaskWithRequest:request];
    [self.downloadTask resume];
    self.progressView.hidden = NO;
}

- (NSURLSession *)backgroundSession {
    static NSURLSession *session = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"com.weimed.iOSBackground.BackgroundSession"];
        session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
    });
    return session;
}

#pragma mark - Background Transfer Service Delegate Method

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    if (downloadTask == self.downloadTask) {
        double progress = (double)totalBytesWritten / (double)totalBytesExpectedToWrite;
        NSLog(@"DownloadTask: %@ progress: %lf", downloadTask, progress);
        dispatch_async(dispatch_get_main_queue(), ^{
            self.progressView.progress = progress;
        });
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    NSFileManager *fileManager = [NSFileManager defaultManager];

    NSArray *URLs = [fileManager URLsForDirectory:NSDocumentationDirectory inDomains:NSUserDomainMask];
    NSURL *documentsDirectory = [URLs objectAtIndex:0];

    NSURL *originalURL = [[downloadTask originalRequest] URL];
    NSURL *destinationURL = [documentsDirectory URLByAppendingPathComponent:[originalURL lastPathComponent]];
    NSError *errorCopy;

    // If the destinationURL does not exist, create it
    [fileManager createDirectoryAtURL:destinationURL withIntermediateDirectories:YES
                           attributes:nil error:nil];
    // For the purposes of testing, remove any esisting file at the destination.
    [fileManager removeItemAtURL:destinationURL error:NULL];
    NSLog(@"download to URL: %@", location);
    NSLog(@"Here is the destination URL: %@", destinationURL);
    BOOL success = [fileManager copyItemAtURL:location toURL:destinationURL error:&errorCopy];

    if (success) {
        dispatch_async(dispatch_get_main_queue(), ^{
            //download finished - open the pdf
            self.documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:destinationURL];
            //configure document interaction controller
            [self.documentInteractionController setDelegate:self];
            //preview the pdf
            [self.documentInteractionController presentPreviewAnimated:YES];
            self.progressView.hidden = YES;
        });
    } else {
        NSLog(@"Error during the copy: %@", [errorCopy localizedDescription]);
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes {
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (error == nil) {
        NSLog(@"Task: %@ completed successfully", task);
    } else {
        NSLog(@"Task: %@ completed with error: %@", task, [error localizedDescription]);
    }

    double progress = (double)task.countOfBytesReceived / (double)task.countOfBytesExpectedToReceive;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.progressView.progress = progress;
    });
    self.downloadTask = nil;
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if(appDelegate.backgroundSessionCompletionHandler) {
        void (^completionHandler)() = appDelegate.backgroundSessionCompletionHandler;
        appDelegate.backgroundSessionCompletionHandler = nil;
        completionHandler();
    }

    NSLog(@"All tasks are finished!");
}

- (UIViewController *)documentInteractionControllerViewControllerForPreview: (UIDocumentInteractionController *)controller {
    return self;
}

@end
