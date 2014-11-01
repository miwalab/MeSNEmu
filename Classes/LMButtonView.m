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
    CGFloat radius = 0.0;
    CGFloat red = 255/255.0;
    CGFloat green = 255/255.0;
    CGFloat blue = 255/255.0;
    CGFloat alpha = 1.0;
    
    self.button = buttonMap;
    
    switch (buttonMap) {
      case 0:
        red = 220/255.0;
        green = 220/255.0;
        blue = 220/255.0;
        self.frame = (CGRect){0,0,70,18};
        radius = 4.0;
        self.titleLabel.font = [UIFont boldSystemFontOfSize:10];
        [self setTitle:NSLocalizedString(@"MENU", nil) forState:UIControlStateNormal];
        break;
      case SI_BUTTON_START:
        self.frame = (CGRect){0,0,70,18};
        radius = 4.0;
        self.titleLabel.font = [UIFont boldSystemFontOfSize:10];
        [self setTitle:NSLocalizedString(@"START", nil) forState:UIControlStateNormal];
        break;
      case SI_BUTTON_SELECT:
        self.frame = (CGRect){0,0,70,18};
        radius = 4.0;
        self.titleLabel.font = [UIFont boldSystemFontOfSize:10];
        [self setTitle:NSLocalizedString(@"SELECT", nil) forState:UIControlStateNormal];
        break;
      case SI_BUTTON_A:
        red = 236/255.0;
        green = 27/255.0;
        blue = 111/255.0;
        self.frame = (CGRect){0,0,38.0,38.0};
        radius = (38.0*0.5)-(border*0.5);
        self.titleLabel.font = [UIFont boldSystemFontOfSize:14];
        //[self setTitle:NSLocalizedString(@"A", nil) forState:UIControlStateNormal];
        break;
      case SI_BUTTON_B:
        red = 237/255.0;
        green = 189/255.0;
        blue = 19/255.0;
        self.frame = (CGRect){0,0,38.0,38.0};
        radius = (38.0*0.5)-(border*0.5);
        self.titleLabel.font = [UIFont boldSystemFontOfSize:14];
        //[self setTitle:NSLocalizedString(@"B", nil) forState:UIControlStateNormal];
        break;
      case SI_BUTTON_X:
        red = 15/255.0;
        green = 121/255.0;
        blue = 145/255.0;
        self.frame = (CGRect){0,0,38.0,38.0};
        radius = (38.0*0.5)-(border*0.5);
        self.titleLabel.font = [UIFont boldSystemFontOfSize:14];
        //[self setTitle:NSLocalizedString(@"X", nil) forState:UIControlStateNormal];
        break;
      case SI_BUTTON_Y:
        red = 0/255.0;
        green = 170/255.0;
        blue = 110/255.0;
        self.frame = (CGRect){0,0,38.0,38.0};
        radius = (38.0*0.5)-(border*0.5);
        self.titleLabel.font = [UIFont boldSystemFontOfSize:14];
        //[self setTitle:NSLocalizedString(@"Y", nil) forState:UIControlStateNormal];
        break;
      case SI_BUTTON_L:
        self.frame = (CGRect){0,0,110.0,20.0};
        radius = 4.0;
        self.titleLabel.font = [UIFont boldSystemFontOfSize:14];
        //[self setTitle:NSLocalizedString(@"L", nil) forState:UIControlStateNormal];
        break;
      case SI_BUTTON_R:
        self.frame = (CGRect){0,0,110.0,20.0};
        radius = 4.0;
        self.titleLabel.font = [UIFont boldSystemFontOfSize:14];
        //[self setTitle:NSLocalizedString(@"R", nil) forState:UIControlStateNormal];
        break;
    }
    
    [self setTitleColor:[UIColor colorWithRed:150/255.0 green:150/255.0 blue:150/255.0 alpha:0.8] forState:UIControlStateNormal];
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(self.frame.size.width, self.frame.size.height), NO, self.currentImage.scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetRGBFillColor(context, red, green, blue, alpha);
    CGContextSetRGBStrokeColor(context, 255/255.0, 255/255.0, 255/255.0, 1.0);
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
    
    [self setBackgroundImage:UIGraphicsGetImageFromCurrentImageContext() forState:UIControlStateNormal];
    
    UIGraphicsEndImageContext();
    
    [self addTarget:self action:@selector(handleTouches:forEvent:) forControlEvents:UIControlEventAllEvents];
  }
  return self;
}

@end
