//
//  SVGtoVideoConverter.m
//  macSVG
//
//  Created by Douglas Ward on 9/8/16.
//
//

// adapted from http://stackoverflow.com/questions/10647091/how-to-create-video-from-its-frames-iphone/19166876#19166876
// and http://chrisjdavis.org/capturing-the-contents-of-a-webview

#import "SVGtoVideoConverter.h"
//#import "CoreGraphics/CoreGraphics.h"

@implementation SVGtoVideoConverter

- (void)dealloc
{
    self.hiddenWebView.downloadDelegate = NULL;
    self.hiddenWebView.frameLoadDelegate = NULL;
    self.hiddenWebView.policyDelegate = NULL;
    self.hiddenWebView.UIDelegate = NULL;
    self.hiddenWebView.resourceLoadDelegate = NULL;

    self.hiddenWebView = NULL;
    self.videoWriter = NULL;
    self.videoSettings = NULL;
    self.writerInput = NULL;
    self.adaptor = NULL;
    
    self.hiddenWindow = NULL;
}



- (instancetype)init
{
    self = [super init];
    if (self)
    {
    }
    return self;
}



- (void) writeSVGAnimationAsMovie:(NSString*)path svgXmlString:(NSString *)svgXmlString
        width:(NSInteger)movieWidth height:(NSInteger)movieHeight
        startTime:(CGFloat)startTime endTime:(CGFloat)endTime
        framesPerSecond:(NSInteger)framesPerSecond
        currentTimeTextLabel:(NSTextField *)currentTimeTextLabel
        generatingHTML5VideoSheet:(NSWindow *)generatingHTML5VideoSheet
        hostWindow:(NSWindow *)hostWindow
{
    self.path = path;
    self.movieWidth = movieWidth;
    self.movieHeight = movieHeight;
    self.startTime = startTime;
    self.endTime = endTime;
    self.framesPerSecond = framesPerSecond;

    self.currentTime = self.startTime;
    self.frameCount = 0;
    self.frameTimeInterval = 1.0f / self.framesPerSecond;
    
    self.currentTimeTextLabel = currentTimeTextLabel;
    self.generatingHTML5VideoSheet = generatingHTML5VideoSheet;
    self.hostWindow = hostWindow;

    NSString * currentTimeString = [NSString stringWithFormat:@"%f", self.currentTime];
    self.currentTimeTextLabel.stringValue = currentTimeString;

    NSRect webViewFrame = NSMakeRect(0, 0, self.movieWidth, self.movieHeight);

    // create a new window, offscreen.
    self.hiddenWindow = [[NSWindow alloc]
            initWithContentRect: NSMakeRect( -1000,-1000, self.movieWidth, self.movieHeight)
            styleMask: NSTitledWindowMask | NSClosableWindowMask backing:NSBackingStoreNonretained defer:NO];

    self.hiddenWebView = [[WebView alloc] initWithFrame:webViewFrame];

    (self.hiddenWindow).contentView = self.hiddenWebView;
    
    NSData * xmlData = [svgXmlString dataUsingEncoding:NSUTF8StringEncoding];
    
    NSURL * baseURL = NULL;
    
    NSString * mimeType = @"image/svg+xml";

    [(self.hiddenWebView).mainFrame loadData:xmlData
            MIMEType:mimeType	
            textEncodingName:@"UTF-8" 
            baseURL:baseURL];

    [self performSelector:@selector(getNextFrameImage) withObject:NULL afterDelay:2.0f];
}


- (void)initVideoWriter:(NSImage *)firstFrameImage
{
    NSError *error  = nil;
    
    self.webFrameSize = firstFrameImage.size;
    
    self.videoWriter = [[AVAssetWriter alloc] initWithURL:
            [NSURL fileURLWithPath:self.path]
            //fileType:AVFileTypeQuickTimeMovie
            fileType:AVFileTypeMPEG4
            error:&error];
    
    NSParameterAssert(self.videoWriter);

    NSMutableDictionary *compressionSettings = NULL;
    compressionSettings = [NSMutableDictionary dictionary];

    /*
    Specify the HD output color space for the video color properties
    key (AVVideoColorPropertiesKey). During export, AV Foundation
    will perform a color match from the input color space to the HD
    output color space.
     
	Most clients will want to specify HD, which consists of:
 
		AVVideoColorPrimaries_ITU_R_709_2
		AVVideoTransferFunction_ITU_R_709_2
		AVVideoYCbCrMatrix_ITU_R_709_2
 
	If you require SD colorimetry use:
 
		AVVideoColorPrimaries_SMPTE_C
		AVVideoTransferFunction_ITU_R_709_2
		AVVideoYCbCrMatrix_ITU_R_601_4

	If you require wide gamut HD colorimetry, you can use:
 
		 AVVideoColorPrimaries_P3_D65
		 AVVideoTransferFunction_ITU_R_709_2
		 AVVideoYCbCrMatrix_ITU_R_709_2
    */

    //[compressionSettings setObject:AVVideoColorPrimaries_P3_D65   // TODO: requires macOS 10.12
    compressionSettings[AVVideoColorPrimariesKey] = AVVideoColorPrimaries_ITU_R_709_2;
    compressionSettings[AVVideoTransferFunctionKey] = AVVideoTransferFunction_ITU_R_709_2;
    compressionSettings[AVVideoYCbCrMatrixKey] = AVVideoYCbCrMatrix_ITU_R_709_2;
    
    self.videoSettings = @{AVVideoCodecKey: AVVideoCodecH264,
            AVVideoWidthKey: [NSNumber numberWithInteger:self.movieWidth],
            AVVideoHeightKey: [NSNumber numberWithInteger:self.movieHeight],
            AVVideoColorPropertiesKey: compressionSettings};
    
    self.writerInput = [AVAssetWriterInput
            assetWriterInputWithMediaType:AVMediaTypeVideo
            outputSettings:self.videoSettings];

    NSDictionary* bufferAttributes = @{(id)kCVPixelBufferPixelFormatTypeKey: [NSNumber numberWithInt:kCVPixelFormatType_32ARGB]};

    self.adaptor = [AVAssetWriterInputPixelBufferAdaptor
        assetWriterInputPixelBufferAdaptorWithAssetWriterInput:self.writerInput
        sourcePixelBufferAttributes:bufferAttributes];

    NSParameterAssert(self.writerInput);
    NSParameterAssert([self.videoWriter canAddInput:self.writerInput]);
    [self.videoWriter addInput:self.writerInput];

    [self.videoWriter startWriting];
    [self.videoWriter startSessionAtSourceTime:kCMTimeZero];
}


- (void)getNextFrameImage
{
    DOMDocument * domDocument = (self.hiddenWebView).mainFrame.DOMDocument;
    DOMElement * svgElement = domDocument.documentElement;
    
    NSString * currentTimeString = [NSString stringWithFormat:@"%f", self.currentTime];
    self.currentTimeTextLabel.stringValue = currentTimeString;
    NSNumber * newTimeValueNumber = @(self.currentTime);

    [svgElement callWebScriptMethod:@"pauseAnimations" withArguments:NULL];  // call JavaScript function
    
    NSArray * setCurrentTimeArgumentsArray = @[newTimeValueNumber];
    [svgElement callWebScriptMethod:@"setCurrentTime" withArguments:setCurrentTimeArgumentsArray];  // call JavaScript function

    [svgElement callWebScriptMethod:@"forceRedraw" withArguments:NULL];  // call JavaScript function

    [self.hiddenWebView setNeedsDisplay:YES];
    
    CGFloat delay = 0.1f;
    
    [self performSelector:@selector(webViewDidFinishLoad) withObject:NULL afterDelay:delay];
}



- (void)webViewDidFinishLoad
{
    NSImage * webImage = [self imageFromWebView];

    if (self.currentTime == self.startTime)
    {
        [self initVideoWriter:webImage];
    }

    CGImageSourceRef webCGImageSourceRef = CGImageSourceCreateWithData((CFDataRef)webImage.TIFFRepresentation, NULL);
    CGImageRef webCGImageRef =  CGImageSourceCreateImageAtIndex(webCGImageSourceRef, 0, NULL);

    CVPixelBufferRef buffer = [self newPixelBufferFromCGImage:webCGImageRef andFrameSize:self.webFrameSize];

    if (self.adaptor.assetWriterInput.readyForMoreMediaData)
    {
        CMTime frameTime = CMTimeMake(self.frameCount,(int32_t) self.framesPerSecond);
        [self.adaptor appendPixelBuffer:buffer withPresentationTime:frameTime];

        /*
        if (buffer)
        {
            CVBufferRelease(buffer);
        }
        */
    }

    if (buffer)
    {
        CVBufferRelease(buffer);
    }

    if (webCGImageRef)
    {
        CGImageRelease((webCGImageRef));
    }
    
    self.frameCount++;
    self.currentTime += self.frameTimeInterval;
    
    if (self.currentTime > self.endTime)
    {
        [self finishWritingVideo];
    }
    else
    {
        [self getNextFrameImage];
    }
}



- (void)finishWritingVideo
{
    [self.writerInput markAsFinished];
    
    [self.videoWriter finishWritingWithCompletionHandler:^
    {
        if (self.videoWriter.status != AVAssetWriterStatusFailed && self.videoWriter.status == AVAssetWriterStatusCompleted)
        {
        }
        else
        {
            //NSError * assetWriterError = self.videoWriter.error;
        }
    }];
    
    
    [self.hostWindow endSheet:self.generatingHTML5VideoSheet returnCode:NSModalResponseStop];
    [self.generatingHTML5VideoSheet orderOut:self];
}


- (CVPixelBufferRef) newPixelBufferFromCGImage: (CGImageRef) image andFrameSize:(CGSize)frameSize
{
    NSDictionary *options = @{(id)kCVPixelBufferCGImageCompatibilityKey: @YES,
            (id)kCVPixelBufferCGBitmapContextCompatibilityKey: @YES};
    
    CVPixelBufferRef pxbuffer = NULL;
    
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, frameSize.width,
        frameSize.height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options,
        &pxbuffer);
    
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);

    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    
    NSParameterAssert(pxdata != NULL);

    CGColorSpaceRef genericRGBColorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
    
    CGContextRef context = CGBitmapContextCreate(pxdata, frameSize.width,
            frameSize.height, 8, 4 * frameSize.width,
            genericRGBColorSpace,
            kCGImageAlphaNoneSkipFirst);
    
    NSParameterAssert(context);
    
    CGContextSetRenderingIntent(context, kCGRenderingIntentAbsoluteColorimetric);
    
    CGContextConcatCTM(context, CGAffineTransformMakeRotation(0));
    
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image), 
            CGImageGetHeight(image)), image);
    
    CGColorSpaceRelease(genericRGBColorSpace);
    
    CGContextRelease(context);

    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);

    return pxbuffer;
}



- (NSImage *)imageFromWebView
{
    NSRect imageBounds = NSMakeRect(0, 0, self.movieWidth, self.movieHeight);

    NSRect webViewBounds = self.hiddenWebView.bounds;

    // grab the full view
	[self.hiddenWebView lockFocus];
    NSBitmapImageRep * bitmapRep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:webViewBounds];
	[self.hiddenWebView unlockFocus];

    bitmapRep.colorSpaceName = NSDeviceRGBColorSpace;
    
    // crop the view to document size
    NSImage * webImage = [[NSImage alloc] initWithSize:imageBounds.size];
    
    NSRect srcImageBounds = imageBounds;
    srcImageBounds.origin.y = webViewBounds.size.height - self.movieHeight;
    
    // draw to create bitmapImageRep
    [webImage lockFocus];
    [bitmapRep drawInRect:imageBounds fromRect:srcImageBounds operation:NSCompositeCopy
            fraction:1.0f respectFlipped:YES hints:NULL];
    [webImage unlockFocus];

    NSArray * destinationRepresentations = webImage.representations;
    NSBitmapImageRep * destinationBitmapImageRep = destinationRepresentations.firstObject;
    destinationBitmapImageRep.colorSpaceName = NSCalibratedRGBColorSpace;

    // redraw after color space setting
    [webImage lockFocus];
    [bitmapRep drawInRect:imageBounds fromRect:srcImageBounds operation:NSCompositeCopy
            fraction:1.0f respectFlipped:YES hints:NULL];
    [webImage unlockFocus];

    return webImage;
}


@end