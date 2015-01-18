//
//  Controller.m
//  MosaicMe_v2
//
//  Created by Marianna Neubauer on 5/9/14.
//  Copyright (c) 2014 Marianna Neubauer. All rights reserved.
//

#import "Controller.h"
#import "Mosaic.h"

#define ZOOM_IN_FACTOR  1.414214 // doubles the area
#define ZOOM_OUT_FACTOR 0.7071068 // halves the area

@implementation Controller

/**
 * Quit Function
 */
- (IBAction) quit:(id) sender
{
	[NSApp terminate: self];
}


/**
 * initialize GUI
 */
- (void)awakeFromNib
{
	// launch screen image
	NSString *path = [[NSBundle mainBundle] pathForResource: @"title1" ofType: @"png"];
    NSURL *url = [NSURL fileURLWithPath: path];
	
	// initial setting of of image view
    [mImageView setImageWithURL: url];
	[mImageView setCurrentToolMode: IKToolModeMove];
    [mImageView zoomImageToFit: self];
    [mImageView setDelegate: self];
	
	// initial setting of control panel
	[mPanel setFloatingPanel:YES];
	[mImage setEditable: NO];
	[mFolder setEditable: NO];
	
	
	// instantiate mosaic image
	mosaicImage = [[Mosaic alloc] init];
	
	// overlay state
	overlay = NO;
	
}


/**
 * submit button function.
 * Gets parameters form Control Panel (mPanel) and sends it to Mosaic class to build mosaic image.
 */
- (IBAction)submit: (id)sender
{
	// ensures custom text label is black
	[mCustomImageSizeLabel setTextColor:[NSColor blackColor]];
	[mCustomTileSizeLabel setTextColor:[NSColor blackColor]];
	
	// gets image size
	NSInteger imageSize = -1;
	NSInteger imageSizeTag = [[mImageSize selectedCell] tag];
	switch (imageSizeTag)
    {
        case 0:
            imageSize = 8000;
            break;
        case 1:
            imageSize = 4000;
            break;
        case 2:
            imageSize = 2000;
            break;
        case 3:
			imageSize = [mCustomImageSize intValue];
			break;
    }
	
	// gets tile size
	NSInteger tileSize = -1;
	NSInteger tileSizeTag = [[mTileSize selectedCell] tag];
	switch (tileSizeTag)
    {
        case 0:
            tileSize = 50;
            break;
        case 1:
            tileSize = 100;
            break;
        case 2:
            tileSize = 500;
            break;
        case 3:
			tileSize = [mCustomTileSize intValue];
            break;
    }
	
	// warning if there is no image url
	if(!imageURL)
	{
		[mImage setTextColor: [NSColor redColor]];
		[mImage setFont: [NSFont systemFontOfSize:18]];
		[mImage setStringValue: @"!!!"];
	}
	
	// warning if there is no folder url
	if (!folderURL)
	{
		[mFolder setTextColor: [NSColor redColor]];
		[mFolder setFont: [NSFont systemFontOfSize:18]];
		[mFolder setStringValue: @"!!!"];
	}
	
	// warning for bad custom image size
	if (!imageSize || (tileSize > imageSize && imageSizeTag == 3))
	{
		[mCustomImageSizeLabel setTextColor:[NSColor redColor]];
	}
	
	// warning for bad custom tile size
	if (!tileSize || (tileSize > imageSize && tileSizeTag == 3))
	{
		[mCustomTileSizeLabel setTextColor: [NSColor redColor]];
	}
	
	// if all the parameters are avaliable then draw the mosaic
	if(imageURL && folderURL && tileSize > 0 && imageSize > 0 && tileSize < imageSize)
	{
		[mPanel setFloatingPanel:NO];
		[mProgressWheel startAnimation: self];
		[mosaicImage initWithURL:imageURL folder:folderURL imageSize: imageSize tileSize:tileSize];
		[mProgressWheel stopAnimation: self];
		NSImage *finalImage = [mosaicImage getMosaicImage];
		overlay = NO;
		[self displayImage:finalImage];
	}
	
}


/**
 * Open folder action from open folder button in Control Panel.
 */
-(IBAction)openFolder: (id)sender
{
	// create open dialogue window and send to front
	[mPanel setFloatingPanel:NO];
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	
	// open dialogue settings
	[openPanel setCanChooseDirectories:YES];
	[openPanel setCanChooseFiles:NO];
	[openPanel setAllowsMultipleSelection:NO];
	
	// action when OK is pressed
	[openPanel beginSheetModalForWindow:mWindow completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton)
        {
			// get url
			folderURL = [[openPanel URLs] objectAtIndex:0];
			
			// display url in Control Panel
			[mFolder setTextColor:[NSColor blackColor]];
			[mFolder setFont: [NSFont systemFontOfSize:9]];
			[mFolder setStringValue:[folderURL absoluteString]];
			
			// send control Panel to front
			[mPanel setFloatingPanel:YES];
        }
    }];
}


/**
 * Open image action from open image button in Control Panel.
 */
- (IBAction)openImage: (id)sender
{
	// create open dialogue window and send to front
	[mPanel setFloatingPanel:NO];
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    
	// allowed selectable filetypes
    NSString *extensions = @"tiff/tif/TIFF/TIF/jpg/jpeg/JPG/JPEG";
    NSArray *types = [extensions pathComponents];
	
    // open dialogue settings
    [openPanel setAllowedFileTypes:types];
	[openPanel setCanChooseDirectories:NO];
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel setCanSelectHiddenExtension:YES];
	
	// action when OK is pressed
    [openPanel beginSheetModalForWindow:mWindow completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton)
        {
			// get url
			imageURL = [[openPanel URLs] objectAtIndex:0];
			
			// display url in Control Panel
			[mImage setTextColor:[NSColor blackColor]];
			[mImage setFont: [NSFont systemFontOfSize:9]];
			[mImage setStringValue:[imageURL absoluteString]];
			
			// send control Panel to front
			[mPanel setFloatingPanel:YES];
        }
    }];
	
}


/**
 * Save Mosaic Image method
 */
- (void)savePanelDidEnd: (NSSavePanel *)sheet
             returnCode: (NSInteger)returnCode
{
    // save the image
    
    if (returnCode == NSOKButton)
    {
        NSString *newUTType = [mSaveOptions imageUTType];
        CGImageRef image;
		
        // get the current image from the image view
        image = [mImageView image];
        
        if (image)
        {
            // use ImageIO to save the image in the user specified format
            NSURL *url = [sheet URL];
            CGImageDestinationRef dest = CGImageDestinationCreateWithURL((__bridge CFURLRef)url, (__bridge CFStringRef)newUTType, 1, NULL);
            
            if (dest)
            {
                CGImageDestinationAddImage(dest, image, (__bridge CFDictionaryRef)[mSaveOptions imageProperties]);
                CGImageDestinationFinalize(dest);
                CFRelease(dest);
            }
        } else
        {
            return;
        }
    }
}


/**
 * Save Image action from save menu item
 */
- (IBAction)saveImage: (id)sender
{
	
    // allowed file types
	NSString *extensions = @"tiff/tif/TIFF/TIF/jpg/jpeg/JPG/JPEG";
    NSArray *types = [extensions pathComponents];
	
	// create save panel
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    mSaveOptions = [[IKSaveOptions alloc] initWithImageProperties: mImageProperties
                                                      imageUTType: mImageUTType];
    
	// save panel settings
    [mSaveOptions addSaveOptionsAccessoryViewToSavePanel:savePanel];
	[savePanel setAllowedFileTypes:types];
    [savePanel setCanSelectHiddenExtension:YES];
	
	// save image if OK is pressed
    [savePanel beginSheetModalForWindow:mWindow completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton)
            [self savePanelDidEnd:savePanel returnCode:result];
    }];
	
    
}


/**
 * Zoom Action from UI Controls in window and in menu
 */
- (IBAction)doZoom: (id)sender
{
	
    NSInteger zoom;
    CGFloat   zoomFactor;
	
	// get zoom tag from interface
    if ([sender isKindOfClass:[NSSegmentedControl class]])
        zoom = [sender selectedSegment];
    else
        zoom = [sender tag];
	
    switch (zoom)
    {
		// zoom out
        case 0:
            zoomFactor = [mImageView zoomFactor];
            [mImageView setZoomFactor: zoomFactor * ZOOM_OUT_FACTOR];
            break;
		// zoom in
        case 1:
            zoomFactor = [mImageView zoomFactor];
            [mImageView setZoomFactor: zoomFactor * ZOOM_IN_FACTOR];
            break;
		// zoom to actual size
        case 2:
            [mImageView zoomImageToActualSize: self];
            break;
		// zoom to fit
        case 3:
            [mImageView zoomImageToFit: self];
            break;
    }
}


/**
 * Opens Mosaic Window if it is closed
 */
- (IBAction) openWindow: (id) sender
{
	if(![mWindow isVisible])
		[mWindow makeKeyAndOrderFront: mWindow];
}


/**
 * Opens Control panel if it is closed
 */
- (IBAction) openPanel: (id) sender
{
	if(![mPanel isVisible])
		[mPanel makeKeyAndOrderFront: mPanel];
}


/**
 * Overlays original image over mosaic images.
 * Inputs from toolbar
 * Can increase and decrease the opacity of the overlayed image
 */
- (IBAction) overlay: (id) sender;
{
	// get mosaic and original image
	NSImage *finalImage = [mosaicImage getMosaicImage];
	NSImage *bigImage = [mosaicImage getBigImage];
	
	// if either image is nil then stop the action
	if(!finalImage || !bigImage)
		return;
	
	// instantiate the overlay image
	NSImage *overlayImage = [[NSImage alloc] initWithSize: [finalImage size]];
	
	// get tag
	NSInteger tag;
	if ([sender isKindOfClass:[NSSegmentedControl class]])
        tag = [sender selectedSegment];
    else
        tag = [sender tag];
	
	switch (tag)
	{
		// toggle overlay on or off
		case 0:
			if (overlay)
			{
				transparency = 0;
				overlay = NO;
			}
			else
			{
				transparency = 0.5;
				overlay = YES;
			}
			break;
		// make original image more opaque
		case 1:
			if(!overlay || transparency >= 1.0)
				return;
			transparency += 0.1;
			break;
		// make mosaic image more opaque
		case 2:
			if(!overlay || transparency <= 0.0)
				return;
			transparency -= 0.1;
			break;
	}

	// draw the overlay image
	[overlayImage lockFocus];
	[finalImage drawAtPoint:NSZeroPoint fromRect:CGRectMake(0, 0, overlayImage.size.width, overlayImage.size.height) operation:NSCompositeCopy fraction:(1.0-transparency)];
	[bigImage drawAtPoint:NSZeroPoint fromRect:CGRectMake(0, 0, overlayImage.size.width, overlayImage.size.height) operation:NSCompositePlusDarker fraction:transparency];
	[overlayImage unlockFocus];
	
	// display the overlay image
	[self displayImage: overlayImage];
}


/**
 * Show image in Mosaic Window image view
 */
- (void)displayImage: (NSImage *) image
{
	// check image is valid
	if(![image isValid])
		return;
	
	// image fits to screen
	mImageView.autoresizes = YES;
	
	// get input image
	CGImageSourceRef sourceRef = CGImageSourceCreateWithData((__bridge CFDataRef)[image TIFFRepresentation], NULL);
	CGImageRef imageRef =  CGImageSourceCreateImageAtIndex(sourceRef, 0, NULL);
	mImageProperties = nil;
	
	// display input image
	[mImageView setImage: imageRef imageProperties: mImageProperties];
	
	// release references
	CFRelease(sourceRef);
	CGImageRelease(imageRef);
	
}


/**
 * Displays help window
 */
- (IBAction) help: (id) sender
{
	// if help window already displayed, return
	if([mHelpWindow isVisible])
		return;
	
	// get help image
	NSString *path = [[NSBundle mainBundle] pathForResource: @"help" ofType: @"png"];
    NSURL *url = [NSURL fileURLWithPath: path];
	NSImage *helpImage = [[NSImage alloc] initWithContentsOfURL: url];
	if (![helpImage isValid])
	{
		return;
	}
	
	// display help image in new window
	[mHelp setImage: helpImage];
	[mHelp setImageScaling: NSImageScaleProportionallyUpOrDown];
	[mHelpWindow makeKeyAndOrderFront: mHelpWindow];
}

@end

