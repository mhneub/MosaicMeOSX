//
//  Mosaic.h
//  MosaicMe_v2
//
//  Created by Marianna Neubauer on 5/10/14.
//  Copyright (c) 2014 Marianna Neubauer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Quartz/Quartz.h>
#import <Cocoa/Cocoa.h>

@interface Mosaic : NSObject
{
	// input parameters
	NSURL * imageURL;
	NSURL * folderURL;
	NSInteger imageSize;
	NSInteger tileSize;
	
	//intermediate parameters
	NSImage * bigImage;
	NSArray * folder;
	NSArray * smallImages;
	int **imageColors;
	
	//output parameters
	NSImage * finalImage;
	
}

- (void) initWithURL: (NSURL *)url folder: (NSURL *) folderURL imageSize: (NSInteger) imSize tileSize: (NSInteger) tSize;
- (NSImage *) getMosaicImage;
- (NSImage *) getBigImage;

@end
