//
//  ViewController.h
//  iOSBackground
//
//  Created by Richard Lee on 8/4/15.
//  Copyright (c) 2015 weimed. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController < NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDownloadDelegate, UIDocumentInteractionControllerDelegate >

@property (nonatomic) NSURLSession *session;
@property (nonatomic) NSURLSessionDownloadTask *downloadTask;
@property (strong, nonatomic) UIDocumentInteractionController *documentInteractionController;

@end

