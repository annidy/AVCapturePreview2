//
//  ViewController.m
//  AVCapturePreview2
//
//  Created by annidy on 16/4/16.
//  Copyright © 2016年 annidy. All rights reserved.
//

#import "ViewController.h"
#import "VideoGLView.h"
@import AVFoundation;

//#define QUARTZ
//#define LAYER

#include <assert.h>
#include <CoreServices/CoreServices.h>
#include <mach/mach.h>
#include <mach/mach_time.h>
#include <unistd.h>

#import <OpenGL/gl3.h>


@interface ViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate>

@property (weak) IBOutlet NSImageView *cameraView;
@property (weak) IBOutlet NSTextField *fpsLabel;
@property (weak) IBOutlet VideoGLView *openGLView;
@end

@implementation ViewController
{
    AVCaptureSession *_captureSession;
    
    AVSampleBufferDisplayLayer *_videoLayer;
    NSMutableArray *_displayFrameBuffer;
    dispatch_queue_t _captureQueue;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view setWantsLayer:YES];
    // Do any additional setup after loading the view.
    
    _captureQueue = dispatch_queue_create("AVCapture2", 0);
}

- (void)viewDidAppear
{
    [super viewDidAppear];
    
    [self initCaptureSession];
    
#ifdef LAYER
    [self initSampleBufferDisplayLayer];
#endif
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    
    // Update the view, if already loaded.
}

- (IBAction)startSession:(id)sender {
    if (![_captureSession isRunning]) {
        [_captureSession startRunning];
    }
}
- (IBAction)stopSession:(id)sender {
    if ([_captureSession isRunning]) {
        [_captureSession stopRunning];
    }
}


- (void)initCaptureSession
{
    _captureSession = [[AVCaptureSession alloc] init];
    
    [_captureSession beginConfiguration];
    
    if ([_captureSession canSetSessionPreset:AVCaptureSessionPreset640x480])
        [_captureSession setSessionPreset:AVCaptureSessionPreset640x480];
    
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSCAssert(captureDevice, @"no device");
    
    NSError *error;
    AVCaptureDeviceInput *input = [[AVCaptureDeviceInput alloc] initWithDevice:captureDevice error:&error];
    [_captureSession addInput:input];
    
    //-- Create the output for the capture session.
    AVCaptureVideoDataOutput * dataOutput = [[AVCaptureVideoDataOutput alloc] init];
    [dataOutput setAlwaysDiscardsLateVideoFrames:YES]; // Probably want to set this to NO when recording
    
    for (int i = 0; i < dataOutput.availableVideoCVPixelFormatTypes.count; i++) {
        char fourr[5] = {0};
        *((int32_t *)fourr) = CFSwapInt32([dataOutput.availableVideoCVPixelFormatTypes[i] intValue]);
        NSLog(@"%s", fourr);
    }
    
    //-- Set to YUV420.
    [dataOutput setVideoSettings:@{(id)kCVPixelBufferPixelFormatTypeKey:[NSNumber numberWithInt:kCVPixelFormatType_24RGB],
                                   (id)kCVPixelBufferWidthKey:@640,
                                   (id)kCVPixelBufferHeightKey:@480}];
     
    // Set dispatch to be on the main thread so OpenGL can do things with the data
    [dataOutput setSampleBufferDelegate:self queue:_captureQueue];
    
    NSAssert([_captureSession canAddOutput:dataOutput], @"can't output");
    
    [_captureSession addOutput:dataOutput];
    
    [_captureSession commitConfiguration];

}

- (void)initSampleBufferDisplayLayer
{
    _videoLayer = [[AVSampleBufferDisplayLayer alloc] init];
    [_videoLayer setFrame:(CGRect){.origin=CGPointZero, .size=self.cameraView.frame.size}];
    _videoLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    _videoLayer.backgroundColor = CGColorGetConstantColor(kCGColorBlack);
    _videoLayer.layoutManager  = [CAConstraintLayoutManager layoutManager];
    _videoLayer.autoresizingMask = kCALayerHeightSizable | kCALayerWidthSizable;
    _videoLayer.contentsGravity = kCAGravityResizeAspect;
    /*
    CMTimebaseRef controlTimebase;
    CMTimebaseCreateWithMasterClock( CFAllocatorGetDefault(), CMClockGetHostTimeClock(), &controlTimebase );
    
    _videoLayer.controlTimebase = controlTimebase;
    
    // Set the timebase to the initial pts here
    CMTimebaseSetTime(_videoLayer.controlTimebase, CMTimeMakeWithSeconds(CACurrentMediaTime(), 24));
    CMTimebaseSetRate(_videoLayer.controlTimebase, 1.0);
    */
    [self.cameraView.layer addSublayer:_videoLayer];
}



- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    static CMFormatDescriptionRef desc;
    if (!desc) {
        desc = CMSampleBufferGetFormatDescription(sampleBuffer);
        NSLog(@"%@", desc);
    }
    
    CVImageBufferRef buffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    [self.openGLView setImage:buffer];
    
    [self frameUpdate];
}

- (void)frameUpdate
{
    static int fps = 0;
    
    static uint64_t        start;
    uint64_t        end;
    uint64_t        elapsed;
    Nanoseconds     elapsedNano;
    
    // Start the clock.
    if (start == 0) {
        start = mach_absolute_time();
    }
    
    
    // Stop the clock.
    
    end = mach_absolute_time();
    
    // Calculate the duration.
    
    elapsed = end - start;
    
    // Convert to nanoseconds.
    
    // Have to do some pointer fun because AbsoluteToNanoseconds
    // works in terms of UnsignedWide, which is a structure rather
    // than a proper 64-bit integer.
    
    elapsedNano = AbsoluteToNanoseconds( *(AbsoluteTime *) &elapsed );
    
    if (* (uint64_t *) &elapsedNano > 1000000000ULL) {
        [self.fpsLabel performSelectorOnMainThread:@selector(setStringValue:) withObject:[NSString stringWithFormat:@"fps %d", fps] waitUntilDone:NO];
        fps = 0;
        start = end;
    }
    
    fps++;
    
}



@end
