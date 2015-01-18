//
//  Controller.h
//  MosaicMe_v2
//
//  Created by Marianna Neubauer on 5/9/14.
//  Copyright (c) 2014 Marianna Neubauer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Quartz/Quartz.h>
#import <Cocoa/Cocoa.h>

#import "Mosaic.h"

@class IKImageView;

@interface Controller : NSObject
{
	// IBOutlets
	IBOutlet IKImageView * mImageView;
	IBOutlet NSWindow * mWindow;
	IBOutlet NSPanel * mPanel;
	IBOutlet NSTextField * mImage;
	IBOutlet NSTextField * mFolder;
	IBOutlet NSMatrix * mImageSize;
	IBOutlet NSMatrix * mTileSize;
	IBOutlet NSTextField * mCustomImageSize;
	IBOutlet NSTextField * mCustomTileSize;
	IBOutlet NSTextField * mCustomImageSizeLabel;
	IBOutlet NSTextField * mCustomTileSizeLabel;
	IBOutlet NSProgressIndicator * mProgressWheel;
	IBOutlet NSPanel * mHelpWindow;
	IBOutlet NSImageView * mHelp;
	
	// intermediate variables
	NSDictionary * mImageProperties;
	NSString * mImageUTType;
	IKSaveOptions * mSaveOptions;
	Mosaic * mosaicImage;
	double transparency;
	BOOL overlay;
	
	// output parameters
	NSURL * imageURL;
	NSURL * folderURL;
	
}

- (IBAction) saveImage: (id)sender;
- (IBAction) openImage: (id)sender;
- (IBAction) doZoom: (id)sender;
- (IBAction) openFolder: (id)sender;
- (IBAction) submit: (id)sender;
- (IBAction) openWindow: (id) sender;
- (IBAction) openPanel: (id) sender;
- (IBAction) overlay: (id) sender;
- (IBAction) quit: (id) sender;
- (IBAction) help: (id) sender;

@end
