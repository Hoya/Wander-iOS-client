// UIImage+Resize.h
// Created by Trevor Harmon on 8/5/09.
// Free for personal or commercial use, with or without modification.
// No warranty is expressed or implied.

// Extends the UIImage class to support resizing/cropping
@interface UIImage (Resize)
- (UIImage *)croppedImage:(CGRect)bounds;
- (UIImage *)thumbnailImage:(NSInteger)thumbnailSize
          transparentBorder:(NSUInteger)borderSize
               cornerRadius:(NSUInteger)cornerRadius
       interpolationQuality:(CGInterpolationQuality)quality;
- (UIImage *)resizedImage:(CGSize)newSize
     interpolationQuality:(CGInterpolationQuality)quality;
- (UIImage *)resizedImageWithContentMode:(UIViewContentMode)contentMode
                                  bounds:(CGSize)bounds
                    interpolationQuality:(CGInterpolationQuality)quality;
- (UIImage *)resizedImageByScalingProportionally:(CGSize)targetSize;
@end

static double calcHeightFromWidth(float width, float height, float targetWidth)
{
	float newWidthPercentage = (100 * targetWidth) / width;
	float newHeight = (height * newWidthPercentage) / 100;
	
	return ceil(newHeight);
}

static double calcWidthFromHeight(float width, float height, float targetHeight)
{
	float newHeightPercentage = (100 * targetHeight) / height;
	float newWidth = (width * newHeightPercentage) / 100;
	
	return ceil(newWidth);
}