//
//  ImageElementEditorWebView.m
//  ImageElementEditor
//
//  Created by Douglas Ward on 5/5/18.
//  Copyright © 2018 ArkPhone LLC. All rights reserved.
//

#import "ImageElementEditorWebView.h"
#import "ImageElementEditor.h"

@implementation ImageElementEditorWebView

- (instancetype)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

//==================================================================================
//    initWithCoder:
//==================================================================================

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

//==================================================================================
//    awakeFromNib
//==================================================================================

- (void) awakeFromNib
{
    [super awakeFromNib];

    self.drawsBackground = NO;
    
    [self setAcceptsTouchEvents:NO];

    [self registerForDraggedTypes:@[NSURLPboardType,
            NSFilenamesPboardType,
            NSTIFFPboardType]];
}

//==================================================================================
//    draggingEntered:
//==================================================================================

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    //NSPasteboard *pboard;
    //NSDragOperation sourceDragMask;

    //NSLog(@"draggingEntered");
    
    return NSDragOperationEvery;
}




/*
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;
 
    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];
 
    if ( [[pboard types] containsObject:NSTIFFPboardType] ) {
        if (sourceDragMask & NSDragOperationGeneric) {
            return NSDragOperationGeneric;
        }
    }
    if ( [[pboard types] containsObject:NSFilenamesPboardType] ) {
        if (sourceDragMask & NSDragOperationLink) {
            return NSDragOperationLink;
        } else if (sourceDragMask & NSDragOperationCopy) {
            return NSDragOperationCopy;
        }
    }
    if ( [[pboard types] containsObject:NSURLPboardType] ) {
        if (sourceDragMask & NSDragOperationLink) {
            return NSDragOperationLink;
        } else if (sourceDragMask & NSDragOperationCopy) {
            return NSDragOperationCopy;
        }
    }
    return NSDragOperationNone;
}
*/




- (BOOL)prepareForDragOperation:(id < NSDraggingInfo >)sender
{
    NSPasteboard *pboard;

    pboard = [sender draggingPasteboard];

    if ( [[pboard types] containsObject:NSTIFFPboardType] )
    {
        return YES;
    }
    else if ( [[pboard types] containsObject:NSFilenamesPboardType] )
    {
        return YES;
    }
    else if ( [[pboard types] containsObject:NSURLPboardType] )
    {
        return YES;
    }
    return NO;
}





- (NSDragOperation)draggingUpdated:(id < NSDraggingInfo >)sender
{
    //NSLog(@"draggingUpdated");
    
    return NSDragOperationEvery;
}



//==================================================================================
// performDragOperation:
//==================================================================================

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    if ([sender draggingSource] == nil)
    {
        NSPasteboard *pboard = [sender draggingPasteboard];

        if ( [[pboard types] containsObject:NSFilenamesPboardType] )
        {
            NSURL* fileURL;
            fileURL=[NSURL URLFromPasteboard: [sender draggingPasteboard]];

            [self loadImageFromFileURL:fileURL];
        }
        else if ( [[pboard types] containsObject:NSURLPboardType] )
        {
            NSURL* fileURL;
            fileURL=[NSURL URLFromPasteboard: [sender draggingPasteboard]];
            
            [self loadImageFromURL:fileURL];
        }
        else if ( [[pboard types] containsObject:NSTIFFPboardType] )
        {
            [self getImageFromPasteboard];
        }
    }

    return [super performDragOperation:sender];
}



- (void)loadImageFromURL:(NSURL *)imageURL
{
    NSString * pathExtension = imageURL.pathExtension;

    if ([pathExtension length] > 0)
    {
        [self.imageElementEditor.imageReferenceOptionMatrix selectCellAtRow:0 column:0];    // set link to image option

        NSString * imageURLString = imageURL.absoluteString;

        self.imageElementEditor.imageURLTextField.stringValue = imageURLString;

        NSURLRequest * imageURLRequest = [NSURLRequest requestWithURL:imageURL];
        if (imageURLRequest != NULL)
        {
            [self.mainFrame loadRequest:imageURLRequest];
        }
    }
    else
    {
        NSBeep();
    }
}


- (void)loadImageFromFileURL:(NSURL *)imageURL
{
    NSString * pathExtension = imageURL.pathExtension;

    if ([pathExtension length] > 0)
    {
        [self.imageElementEditor.imageReferenceOptionMatrix selectCellAtRow:0 column:0];    // set link to image option

        NSString * imageURLString = imageURL.absoluteString;

        self.imageElementEditor.imageURLTextField.stringValue = imageURLString;

        NSURLRequest * imageURLRequest = [NSURLRequest requestWithURL:imageURL];
        if (imageURLRequest != NULL)
        {
            [self.mainFrame loadRequest:imageURLRequest];

            if ([[pathExtension lowercaseString] isEqualToString:@"png"] == YES)
            {
                [self.imageElementEditor.imageReferenceOptionMatrix selectCellAtRow:1 column:0];    // set PNG image embed option
            }
            else
            {
                [self.imageElementEditor.imageReferenceOptionMatrix selectCellAtRow:2 column:0];    // set JPEG image embed option
            }
        }
    }
    else
    {
        NSBeep();
    }
}


- (void)getImageFromPasteboard
{
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    NSArray *classArray = @[[NSImage class]];
    NSDictionary *options = @{};
 
    BOOL ok = [pasteboard canReadObjectForClasses:classArray options:options];
    if (ok)
    {
        NSArray * objectsToPaste = [pasteboard readObjectsForClasses:classArray options:options];
        NSImage * clipboardImage = objectsToPaste[0];

        NSArray * imageReps = clipboardImage.representations;

        NSBitmapImageRep * bits = imageReps[0];
        
        NSDictionary * propertiesDictionary = @{};
        NSData * pngImageData = [bits representationUsingType:NSPNGFileType properties:propertiesDictionary];

        [self.imageElementEditor.imageReferenceOptionMatrix selectCellAtRow:2 column:0];    // for clipboard, set PNG image embed option
        
        [self.mainFrame loadData:pngImageData MIMEType:@"image/png" textEncodingName:nil baseURL:nil];

        //[self scalePreviewContentToFit];
        
        //[self updateDocumentImageDictionary];
    }
}


@end
