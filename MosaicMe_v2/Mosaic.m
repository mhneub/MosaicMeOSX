//
//  Mosaic.m
//  MosaicMe_v2
//
//  Created by Marianna Neubauer on 5/10/14.
//  Copyright (c) 2014 Marianna Neubauer. All rights reserved.
//

#import "Mosaic.h"
#import <math.h>

@implementation Mosaic

/**
  * Initialize the mosaic with input parameters from the front panel.
  */
- (void) initWithURL: (NSURL *)url folder: (NSURL *) furl imageSize: (NSInteger) imSize tileSize: (NSInteger) tSize
{
	
	// keep track of changes
	int drawNewImage = 0;
	NSInteger oldImSize = imageSize;
	
	// change image if it is not the same
	if (![url isEqual: imageURL] || imSize != imageSize)
	{
		imageURL = url;
		imageSize = imSize;
		NSImage *inputImage = [[NSImage alloc] initWithContentsOfURL: url];
		[self setBigImage: inputImage];
		drawNewImage ++;
	}
	
	// if tile size is 1 then produce bigImage and stop Mosaic Algorithm
	if(tSize == 1)
	{
		finalImage = bigImage;
		return;
	}
	
	// change folder of images if it is not the same
	if(![furl isEqual: folderURL] || (oldImSize/tSize) != (imageSize/tileSize))
	{
		folderURL = furl;
		tileSize = tSize;
		NSError *error = nil;
		folder = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:furl
											   includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLNameKey, nil]
																  options:NSDirectoryEnumerationSkipsHiddenFiles
																	error:&error];
		[self setImageArray];
		drawNewImage++;
	}
	
	// make new mosaic if there are any changes
	if (drawNewImage > 0)
	{
		[self draw];
	}
}


/**
 * Resizes large image and assigned it to bigImage property
 */
- (void) setBigImage: (NSImage *) inputImage
{
	NSSize originalSize = [inputImage size];
	NSSize size;
	if (originalSize.width >= originalSize.height)
	{
		size = NSMakeSize(imageSize, imageSize * originalSize.height/originalSize.width);
	}
	else
	{
		size = NSMakeSize(imageSize  * originalSize.width/originalSize.height, imageSize);
	}
	bigImage = [self imageResize:inputImage newSize:size];
}


/**
 * Make an array for small images and their average colors
 */
- (void) setImageArray
{
	NSSize smallImageSize = NSMakeSize(imageSize/tileSize, imageSize/tileSize);
	
	// make array of small images
	int n = (int)[folder count];
	imageColors = malloc(n * 3 * sizeof(int *));
	NSMutableArray *images = [[NSMutableArray alloc] init];
	
	// iterate over url adresses
	int i;
	int ind = 0;
	@autoreleasepool{
		for(i = 0; i < n; i++){
			
			//get url
			NSImage *image = [[NSImage alloc] initWithContentsOfURL: [folder objectAtIndex:i]];
			
			if(![image isValid])
				continue;
			
			//resize image
			NSImage *smallImage = [self cropCentralSquareOfImage:image toSize:smallImageSize];

			
			//add image to array
			[images addObject: smallImage];
			
			// make bitmap
			NSBitmapImageRep *imageRep = [[NSBitmapImageRep alloc] initWithData:[smallImage TIFFRepresentation]];
			int width = (int)[imageRep pixelsWide];
			int height = (int)[imageRep pixelsHigh];
			int rowBytes = (int)[imageRep bytesPerRow];
			unsigned char *pixels = [imageRep bitmapData];
			
			// get average colors
			int *colors = [self meanColor: pixels ColumnStart: 0 Width: width RowStart: 0 Height: height rowLength: rowBytes Format: rowBytes/width];
			imageColors[ind ++] = colors;
		}
	}
	
	smallImages = images;
}


/**
 * Make the mosaic image
 */
- (void) draw
{
	// images exist
	int n = (int)[smallImages count];
	if(n < 1 || ![bigImage isValid])
		return;
	
	// make bitmap of large image
	NSBitmapImageRep *imageRep = [[NSBitmapImageRep alloc] initWithData:[bigImage TIFFRepresentation]];
	int width = (int)[imageRep pixelsWide];
	int height = (int)[imageRep pixelsHigh];
	int rowBytes = (int)[imageRep bytesPerRow];
	unsigned char *pixels = [imageRep bitmapData];
	
	// initialize arrays for iterative overwriting
	int *colorDifference = malloc(n * sizeof(int));
	int *sortedColorDifference = malloc(n * sizeof(int));
	
	// initialize final image
	NSSize size = [bigImage size]; //redundant
	finalImage = [[NSImage alloc] initWithSize:size];
	[finalImage lockFocus];
	
	//iterate over tiles
	NSSize smallImageSize = [[smallImages objectAtIndex:0] size];
	int step = (int)imageSize/tileSize;
	int lastrow = floor(height/smallImageSize.height);
	int lastcol = floor(width/smallImageSize.width);
	for (int i = 0; i < lastrow; i++)
	{
		for (int j = 0; j < lastcol; j++)
		{
			// get mean color of large image sections
			int * colors = [self meanColor: pixels ColumnStart:j*step Width:step RowStart:i*step Height:step rowLength: rowBytes Format: rowBytes/width];
			
			int red = colors[0]; int green = colors[1]; int blue = colors[2];
			
			// find difference in colors between large image section and small images
			
			for (int k = 0; k < n; k++)
			{
				int red1 = imageColors[k][0];
				int green1 = imageColors[k][1];
				int blue1 = imageColors[k][2];
				colorDifference[k] = abs(red - red1) + abs(green - green1) + abs(blue - blue1);
			}
			
			// pick which small image to place in large image section
			
			memcpy(sortedColorDifference, colorDifference, n*sizeof(int));
			[self shellSort: sortedColorDifference arraySize: n];
			//semi-random assignment
			int r = arc4random_uniform(5);
			int index = [self linearSearch: colorDifference number: sortedColorDifference[r] length:n];
			NSImage *smallImage = [smallImages objectAtIndex:index];
			
			//draw small image into tile of large image
			NSPoint point = {j*step, height - (i+1)*step};
			[smallImage drawAtPoint:point fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0];
			
			free(colors);
		}
		
		//NSLog(@"step: %d", i);
	}
	
	// free int arrays
	free(sortedColorDifference); free(colorDifference);
	
	// finish drawing
	[finalImage unlockFocus];
}


/**
  * Return the Mosaic image
  */
- (NSImage *) getMosaicImage
{
	return finalImage;
}

- (NSImage *) getBigImage
{
	return bigImage;
}


/***************************************************************************************
 ***************************************************************************************
 
 							HELPER FUNCTIONS
 
 ***************************************************************************************
 **************************************************************************************/

/**
 * Resizes image bitmaps and returns a resized NSImage
 * Code taken from Stack Overflow: http://stackoverflow.com/questions/11949250/how-to-resize-nsimage
 */
- (NSImage *)imageResize:(NSImage*)anImage newSize:(NSSize)newSize {
    
	NSImage *sourceImage = anImage;
    [sourceImage setScalesWhenResized:YES];
	
    // Report an error if the source isn't a valid image
    if (![sourceImage isValid]){
        return nil;
    } else {
		
		// instantiate new image
        NSImage *newImage = [[NSImage alloc] initWithSize: newSize];
		
		// draw big image in new image
        [newImage lockFocus];
        [sourceImage setSize: newSize];
        [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
        [sourceImage drawAtPoint:NSZeroPoint fromRect:CGRectMake(0, 0, newSize.width, newSize.height) operation:NSCompositeCopy fraction:1.0];
        [newImage unlockFocus];
		
		//return image
        return newImage;
    }
    
}


/**
 * Crops central square of an image. This is used for the tile images.
 */
- (NSImage *)cropCentralSquareOfImage:(NSImage *)image toSize:(CGSize)size
{
	// initialize coordinates and source image rectangle
	double x, y;
	CGRect sourceRect;
	
	// instantiate cropped image
	NSImage *cropped = [[NSImage alloc] initWithSize: size];
	
	// draw cropped image
	[cropped lockFocus];
	
	// get coordinates of central square of source image
	if (image.size.width > image.size.height)
	{
		x = (image.size.width - image.size.height) / 2.0;
		y = 0;
		sourceRect = CGRectMake(x, y, image.size.height, image.size.height);
	}
	else
	{
		double x = 0;
		double y = (image.size.height - image.size.width) / 2.0;
		sourceRect = CGRectMake(x, y, image.size.width, image.size.width);
	}
	
	[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
	[image drawInRect:CGRectMake(0, 0, size.width, size.height) fromRect:sourceRect operation:NSCompositeCopy fraction:1.0];
	[cropped unlockFocus];
	
    return cropped;
}

/**
 * Find the average color of an image or section of an image.
 * Used http://stackoverflow.com/questions/5562095/average-color-value-of-uiimage-in-objective-c for conceptual help
 */
- (int *) meanColor:(unsigned char *)pixels ColumnStart:(int) x0 Width:(int) x1 RowStart:(int) y0 Height:(int) y1 rowLength:(int) rowBytes Format:(int) format
{
	// iterate over pixels
	int row, col;
	int red = 0, green = 0, blue = 0;
	for (row = y0; row < y0 + y1; row++)
	{
		unsigned char *rowStart = (unsigned char*)(pixels + (row * rowBytes) + x0*format);
		unsigned char *nextChannel = rowStart;
		
		//add channel values to colors
		for (col = x0; col < x0 + x1; col++)
		{
			red += *nextChannel;
			nextChannel++;
			green += *nextChannel;
			nextChannel++;
			blue += *nextChannel;
			nextChannel++;
			if (format == 4)
				nextChannel++;
		}
	}
	
	//divide color values by pixel area
	int area = y1 * x1;
	red /= area;
	green /= area;
	blue /= area;
	
	// make RGB array for return value
	int *colors = malloc(3 * sizeof(int));
	colors[0] = red;
	colors[1] = green;
	colors[2] = blue;
	return colors;
}


/**
 * Shell sort and array of integers
 * Got this from http://www.dreamincode.net/forums/topic/14799-fastest-sorting-algorithms-in-c/
 */
-(void) shellSort:(int *) numbers arraySize:(int) array_size
{
	int i, j, increment, temp;
	increment = 3;
	while (increment > 0)
	{
		for (i=0; i < array_size; i++)
		{
			j = i;
			temp = numbers[i];
			while ((j >= increment) && (numbers[j - increment] > temp))
			{
				numbers[j] = numbers[j - increment];
				j = j - increment;
			}
			numbers[j] = temp;
		}
		if (increment/2 != 0)
			increment = increment/2;
		else if (increment == 1)
			increment = 0;
		else
			increment = 1;
	}
}


/**
 * Find index of element in an array
 */
-(int) linearSearch:(int*) array number:(int) n length:(int) len
{
	int result = -1;
	int i;
	for (i = 0; i < len; i++)
	{
		if(array[i] == n)
		{
			result = i;
			break;
		}
	}
	return result;
}

@end
