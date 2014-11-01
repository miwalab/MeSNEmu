//
//  LMDPadView.m
//  MeSNEmu
//
//  Created by Lucas Menge on 1/4/12.
//  Copyright (c) 2012 Lucas Menge. All rights reserved.
//

#import "LMDPadView.h"

#import "../SNES9XBridge/Snes9xMain.h"

@implementation LMDPadView(Privates)

const int kDPadMaxw = 110;
const int kDPadMinw = 32;
const CGFloat kDPadMidw = (kDPadMaxw-kDPadMinw)/2;

- (IBAction)handleTouches:(id)sender forEvent:(UIEvent*)event
{
  UIView *button = (UIView *)sender;
  UITouch *touch = [[event touchesForView:button] anyObject];
  
  if(touch.phase == UITouchPhaseCancelled || touch.phase == UITouchPhaseEnded || touch == nil)
  {
    //NSLog(@"CANCEL");
    SISetControllerReleaseButton(SI_BUTTON_UP);
    SISetControllerReleaseButton(SI_BUTTON_LEFT);
    SISetControllerReleaseButton(SI_BUTTON_RIGHT);
    SISetControllerReleaseButton(SI_BUTTON_DOWN);
    return;
  }
  
  CGPoint location = [touch locationInView:self];
  
  if(location.x>=0 && location.x<kDPadMidw
     && location.y>=0 && location.y<kDPadMidw)
  {
    //NSLog(@"UP-LEFT");
    SISetControllerPushButton(SI_BUTTON_UP);
    SISetControllerPushButton(SI_BUTTON_LEFT);
    SISetControllerReleaseButton(SI_BUTTON_RIGHT);
    SISetControllerReleaseButton(SI_BUTTON_DOWN);
  }
  else if(location.x>=kDPadMidw && location.x<kDPadMidw+kDPadMinw
          && location.y>=0 && location.y<kDPadMidw)
  {
    //NSLog(@"UP");
    SISetControllerPushButton(SI_BUTTON_UP);
    SISetControllerReleaseButton(SI_BUTTON_LEFT);
    SISetControllerReleaseButton(SI_BUTTON_RIGHT);
    SISetControllerReleaseButton(SI_BUTTON_DOWN);
  }
  else if(location.x>=kDPadMidw+kDPadMinw
          && location.y>=0 && location.y<kDPadMidw)
  {
    //NSLog(@"UP-RIGHT");
    SISetControllerPushButton(SI_BUTTON_UP);
    SISetControllerReleaseButton(SI_BUTTON_LEFT);
    SISetControllerPushButton(SI_BUTTON_RIGHT);
    SISetControllerReleaseButton(SI_BUTTON_DOWN);
  }
  else if(location.x>=0 && location.x<kDPadMidw
          && location.y>=kDPadMidw && location.y<kDPadMidw+kDPadMinw)
  {
    //NSLog(@"LEFT");
    SISetControllerReleaseButton(SI_BUTTON_UP);
    SISetControllerPushButton(SI_BUTTON_LEFT);
    SISetControllerReleaseButton(SI_BUTTON_RIGHT);
    SISetControllerReleaseButton(SI_BUTTON_DOWN);
  }
  else if(location.x>=kDPadMidw+kDPadMinw
          && location.y>=kDPadMidw && location.y<kDPadMidw+kDPadMinw)
  {
    //NSLog(@"RIGHT");
    SISetControllerReleaseButton(SI_BUTTON_UP);
    SISetControllerReleaseButton(SI_BUTTON_LEFT);
    SISetControllerPushButton(SI_BUTTON_RIGHT);
    SISetControllerReleaseButton(SI_BUTTON_DOWN);
  }
  else if(location.x>=0 && location.x<kDPadMidw
          && location.y>=kDPadMidw+kDPadMinw)
  {
    //NSLog(@"DOWN-LEFT");
    SISetControllerReleaseButton(SI_BUTTON_UP);
    SISetControllerPushButton(SI_BUTTON_LEFT);
    SISetControllerReleaseButton(SI_BUTTON_RIGHT);
    SISetControllerPushButton(SI_BUTTON_DOWN);
  }
  else if(location.x>=kDPadMidw && location.x<kDPadMidw+kDPadMinw
          && location.y>=kDPadMidw+kDPadMinw)
  {
    //NSLog(@"DOWN");
    SISetControllerReleaseButton(SI_BUTTON_UP);
    SISetControllerReleaseButton(SI_BUTTON_LEFT);
    SISetControllerReleaseButton(SI_BUTTON_RIGHT);
    SISetControllerPushButton(SI_BUTTON_DOWN);
  }
  else if(location.x>=kDPadMidw+kDPadMinw
          && location.y>=kDPadMidw+kDPadMinw)
  {
    //NSLog(@"DOWN-RIGHT");
    SISetControllerReleaseButton(SI_BUTTON_UP);
    SISetControllerReleaseButton(SI_BUTTON_LEFT);
    SISetControllerPushButton(SI_BUTTON_RIGHT);
    SISetControllerPushButton(SI_BUTTON_DOWN);
  }
  else {
    SISetControllerReleaseButton(SI_BUTTON_UP);
    SISetControllerReleaseButton(SI_BUTTON_LEFT);
    SISetControllerReleaseButton(SI_BUTTON_RIGHT);
    SISetControllerReleaseButton(SI_BUTTON_DOWN);
  }
}

@end

@implementation LMDPadView

- (id)init
{
  self = [super init];
  if(self)
  {
    CGFloat border = 0.0;
    
    self.frame = CGRectMake(0, 0, kDPadMaxw, kDPadMaxw);
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(kDPadMaxw, kDPadMaxw), NO, self.currentImage.scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetRGBFillColor(context, 255/255.0, 255/255.0, 255/255.0, 1.0);
    CGContextSetRGBStrokeColor(context, 255/255.0, 255/255.0, 255/255.0, 1.0);
    CGContextSetLineWidth(context, border);
    
    CGRect rrect = CGRectMake(0, 0, kDPadMaxw, kDPadMaxw);
    CGFloat radius = 4.0;
    CGFloat minx = CGRectGetMinX(rrect)+(border/2), midx = CGRectGetMidX(rrect), maxx = CGRectGetMaxX(rrect)-(border/2);
    CGFloat miny = CGRectGetMinY(rrect)+(border/2), midy = CGRectGetMidY(rrect), maxy = CGRectGetMaxY(rrect)-(border/2);
    
    CGContextMoveToPoint(context, kDPadMidw, kDPadMidw);
    CGContextAddArcToPoint(context, kDPadMidw, miny, midx, miny, radius);
    CGContextAddArcToPoint(context, maxx-kDPadMidw, miny, maxx-kDPadMidw, kDPadMidw, radius);
    CGContextAddLineToPoint(context, maxx-kDPadMidw, kDPadMidw);
    CGContextAddArcToPoint(context, maxx, kDPadMidw, maxx, midy, radius);
    CGContextAddArcToPoint(context, maxx, maxy-kDPadMidw, maxx-kDPadMidw, maxy-kDPadMidw, radius);
    CGContextAddLineToPoint(context, maxx-kDPadMidw, maxy-kDPadMidw);
    CGContextAddArcToPoint(context, maxx-kDPadMidw, maxy, midx, maxy, radius);
    CGContextAddArcToPoint(context, kDPadMidw, maxy, kDPadMidw, maxy-kDPadMidw, radius);
    CGContextAddLineToPoint(context, kDPadMidw, maxy-kDPadMidw);
    CGContextAddArcToPoint(context, minx, maxy-kDPadMidw, minx, midy, radius);
    CGContextAddArcToPoint(context, minx, kDPadMidw, kDPadMidw, kDPadMidw, radius);
    CGContextClosePath(context);
    CGContextDrawPath(context, kCGPathFillStroke);
    CGContextFillPath(context);
    
    [self setImage:UIGraphicsGetImageFromCurrentImageContext() forState:UIControlStateNormal];
    
    UIGraphicsEndImageContext();
    
    [self addTarget:self action:@selector(handleTouches:forEvent:) forControlEvents:UIControlEventAllEvents];
  }
  return self;
}

@end