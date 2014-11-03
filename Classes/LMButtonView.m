//
//  LMButtonView.m
//  MeSNEmu
//
//  Created by Lucas Menge on 1/11/12.
//  Copyright (c) 2012 Lucas Menge. All rights reserved.
//

#import "LMButtonView.h"

#import "../SNES9XBridge/Snes9xMain.h"

@implementation LMButtonView(Privates)

- (IBAction)handleTouches:(id)sender forEvent:(UIEvent*)event
{
  UIView *button = (UIView *)sender;
  UITouch *touch = [[event touchesForView:button] anyObject];
  if(touch.phase == UITouchPhaseCancelled || touch.phase == UITouchPhaseEnded || touch == nil)
    SISetControllerReleaseButton(_button);
  else
    SISetControllerPushButton(_button);
}

@end

@implementation LMButtonView

@synthesize button = _button;

- (id)init:(int)buttonMap
{
  self = [super init];
  if(self)
  {
    CGFloat border = 0.0;
    CGFloat radius = 4.0;
    CGFloat border2 = 0.0;
    CGFloat radius2 = 4.0;
    CGFloat red = 80/255.0;
    CGFloat green = 80/255.0;
    CGFloat blue = 80/255.0;
    CGFloat alpha = 0.9;
    CGFloat red2 = 255/255.0;
    CGFloat green2 = 255/255.0;
    CGFloat blue2 = 255/255.0;
    CGFloat alpha2 = 1.0;
    
    self.button = buttonMap;
    
    switch (buttonMap) {
      case 0:
        red = 90/255.0;
        green = 90/255.0;
        blue = 90/255.0;
        red2 = 220/255.0;
        green2 = 220/255.0;
        blue2 = 220/255.0;
        self.frame = (CGRect){0,0,60,18};
        self.titleLabel.font = [UIFont boldSystemFontOfSize:10];
        [self setTitle:NSLocalizedString(@"MENU", nil) forState:UIControlStateNormal];
        break;
      case -1:
        red = 90/255.0;
        green = 90/255.0;
        blue = 90/255.0;
        red2 = 220/255.0;
        green2 = 220/255.0;
        blue2 = 220/255.0;
        self.frame = (CGRect){0,0,60,18};
        self.titleLabel.font = [UIFont boldSystemFontOfSize:10];
        [self setTitle:NSLocalizedString(@"CHEAT", nil) forState:UIControlStateNormal];
        break;
      case SI_BUTTON_START:
        self.frame = (CGRect){0,0,60,18};
        self.titleLabel.font = [UIFont boldSystemFontOfSize:10];
        [self setTitle:NSLocalizedString(@"START", nil) forState:UIControlStateNormal];
        break;
      case SI_BUTTON_SELECT:
        self.frame = (CGRect){0,0,60,18};
        self.titleLabel.font = [UIFont boldSystemFontOfSize:10];
        [self setTitle:NSLocalizedString(@"SELECT", nil) forState:UIControlStateNormal];
        break;
      case SI_BUTTON_A:
        red = 66/255.0;
        green = 49/255.0;
        blue = 139/255.0;
        red2 = 236/255.0;
        green2 = 27/255.0;
        blue2 = 111/255.0;
        self.frame = (CGRect){0,0,38.0,38.0};
        radius = (38.0*0.5)-(border*0.5);
        radius2 = (38.0*0.5)-(border2*0.5);
        self.titleLabel.font = [UIFont boldSystemFontOfSize:14];
        //[self setTitle:NSLocalizedString(@"A", nil) forState:UIControlStateNormal];
        break;
      case SI_BUTTON_B:
        red = 66/255.0;
        green = 49/255.0;
        blue = 139/255.0;
        red2 = 237/255.0;
        green2 = 189/255.0;
        blue2 = 19/255.0;
        self.frame = (CGRect){0,0,38.0,38.0};
        radius = (38.0*0.5)-(border*0.5);
        radius2 = (38.0*0.5)-(border2*0.5);
        self.titleLabel.font = [UIFont boldSystemFontOfSize:14];
        //[self setTitle:NSLocalizedString(@"B", nil) forState:UIControlStateNormal];
        break;
      case SI_BUTTON_X:
        red = 131/255.0;
        green = 126/255.0;
        blue = 148/255.0;
        red2 = 15/255.0;
        green2 = 121/255.0;
        blue2 = 145/255.0;
        self.frame = (CGRect){0,0,38.0,38.0};
        radius = (38.0*0.5)-(border*0.5);
        radius2 = (38.0*0.5)-(border2*0.5);
        self.titleLabel.font = [UIFont boldSystemFontOfSize:14];
        //[self setTitle:NSLocalizedString(@"X", nil) forState:UIControlStateNormal];
        break;
      case SI_BUTTON_Y:
        red = 131/255.0;
        green = 126/255.0;
        blue = 148/255.0;
        red2 = 0/255.0;
        green2 = 170/255.0;
        blue2 = 110/255.0;
        self.frame = (CGRect){0,0,38.0,38.0};
        radius = (38.0*0.5)-(border*0.5);
        radius2 = (38.0*0.5)-(border2*0.5);
        self.titleLabel.font = [UIFont boldSystemFontOfSize:14];
        //[self setTitle:NSLocalizedString(@"Y", nil) forState:UIControlStateNormal];
        break;
      case SI_BUTTON_L:
        self.frame = (CGRect){0,0,110.0,20.0};
        self.titleLabel.font = [UIFont boldSystemFontOfSize:14];
        //[self setTitle:NSLocalizedString(@"L", nil) forState:UIControlStateNormal];
        break;
      case SI_BUTTON_R:
        self.frame = (CGRect){0,0,110.0,20.0};
        self.titleLabel.font = [UIFont boldSystemFontOfSize:14];
        //[self setTitle:NSLocalizedString(@"R", nil) forState:UIControlStateNormal];
        break;
    }
    
    //landscape
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(self.frame.size.width, self.frame.size.height), NO, self.currentImage.scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetRGBFillColor(context, red, green, blue, alpha);
    CGContextSetRGBStrokeColor(context, red, green, blue, alpha);
    CGContextSetLineWidth(context, border);
    
    CGRect rrect = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    CGFloat minx = CGRectGetMinX(rrect)+(border/2), midx = CGRectGetMidX(rrect), maxx = CGRectGetMaxX(rrect)-(border/2);
    CGFloat miny = CGRectGetMinY(rrect)+(border/2), midy = CGRectGetMidY(rrect), maxy = CGRectGetMaxY(rrect)-(border/2);
    
    CGContextMoveToPoint(context, minx, midy);
    CGContextAddArcToPoint(context, minx, miny, midx, miny, radius);
    CGContextAddArcToPoint(context, maxx, miny, maxx, midy, radius);
    CGContextAddArcToPoint(context, maxx, maxy, midx, maxy, radius);
    CGContextAddArcToPoint(context, minx, maxy, minx, midy, radius);
    CGContextClosePath(context);
    CGContextDrawPath(context, kCGPathFillStroke);
    CGContextFillPath(context);
    
    _landscapeImage = [UIGraphicsGetImageFromCurrentImageContext() retain];
    
    UIGraphicsEndImageContext();
    
    //portrait
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(self.frame.size.width, self.frame.size.height), NO, self.currentImage.scale);
    CGContextRef context2 = UIGraphicsGetCurrentContext();
    CGContextSetRGBFillColor(context2, red2, green2, blue2, alpha2);
    CGContextSetRGBStrokeColor(context2, red2, green2, blue2, alpha2);
    CGContextSetLineWidth(context2, border2);
    
    CGRect rrect2 = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    CGFloat minx2 = CGRectGetMinX(rrect2)+(border2/2), midx2 = CGRectGetMidX(rrect2), maxx2 = CGRectGetMaxX(rrect2)-(border2/2);
    CGFloat miny2 = CGRectGetMinY(rrect2)+(border2/2), midy2 = CGRectGetMidY(rrect2), maxy2 = CGRectGetMaxY(rrect2)-(border2/2);
    
    CGContextMoveToPoint(context2, minx2, midy2);
    CGContextAddArcToPoint(context2, minx2, miny2, midx2, miny2, radius2);
    CGContextAddArcToPoint(context2, maxx2, miny2, maxx2, midy2, radius2);
    CGContextAddArcToPoint(context2, maxx2, maxy2, midx2, maxy2, radius2);
    CGContextAddArcToPoint(context2, minx2, maxy2, minx2, midy2, radius2);
    CGContextClosePath(context2);
    CGContextDrawPath(context2, kCGPathFillStroke);
    CGContextFillPath(context2);
    
    _portraitImage = [UIGraphicsGetImageFromCurrentImageContext() retain];
    
    UIGraphicsEndImageContext();
    
    [self addTarget:self action:@selector(handleTouches:forEvent:) forControlEvents:UIControlEventAllEvents];
  }
  return self;
}

- (void)portrait
{
  [self setTitleColor:[UIColor colorWithRed:150/255.0 green:150/255.0 blue:150/255.0 alpha:1.0] forState:UIControlStateNormal];
  [self setTitleColor:[UIColor colorWithRed:180/255.0 green:180/255.0 blue:180/255.0 alpha:1.0] forState:UIControlStateSelected];
  [self setBackgroundImage:_portraitImage forState:UIControlStateNormal];
  UIGraphicsBeginImageContextWithOptions(CGSizeMake(self.frame.size.width, self.frame.size.height), NO, self.currentImage.scale);
  [_portraitImage drawInRect:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
  [_portraitImage drawInRect:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height) blendMode:kCGBlendModeDifference alpha:0.4f];
  [self setBackgroundImage:UIGraphicsGetImageFromCurrentImageContext() forState:UIControlStateSelected];
  UIGraphicsEndImageContext();
}
- (void)landscape
{
  [self setTitleColor:[UIColor colorWithRed:120/255.0 green:120/255.0 blue:120/255.0 alpha:1.0] forState:UIControlStateNormal];
  [self setTitleColor:[UIColor colorWithRed:150/255.0 green:150/255.0 blue:150/255.0 alpha:1.0] forState:UIControlStateSelected];
  [self setBackgroundImage:_landscapeImage forState:UIControlStateNormal];
  UIGraphicsBeginImageContextWithOptions(CGSizeMake(self.frame.size.width, self.frame.size.height), NO, self.currentImage.scale);
  [_landscapeImage drawInRect:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
  [_landscapeImage drawInRect:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height) blendMode:kCGBlendModeDifference alpha:0.4f];
  [self setBackgroundImage:UIGraphicsGetImageFromCurrentImageContext() forState:UIControlStateSelected];
  UIGraphicsEndImageContext();
}

@end
