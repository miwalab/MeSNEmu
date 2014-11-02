//
//  LMEmulatorControllerView.m
//  MeSNEmu
//
//  Created by Lucas Menge on 8/28/13.
//  Copyright (c) 2013 Lucas Menge. All rights reserved.
//

#import "LMEmulatorControllerView.h"

#import "../iCade/LMBTControllerView.h"
#import "../SNES9XBridge/Snes9xMain.h"

#import "LMButtonView.h"
#import "LMDPadView.h"
#import "LMPixelView.h"
#import "LMPixelLayer.h"
#import "LMSettingsController.h"

#pragma mark -

@implementation LMEmulatorControllerView

@synthesize optionsButton = _optionsButton;
@synthesize iCadeControlView = _iCadeControlView;
@synthesize viewMode = _viewMode;
- (void)setViewMode:(LMEmulatorControllerViewMode)viewMode
{
  if(_viewMode != viewMode)
  {
    _viewMode = viewMode;
    [self setNeedsLayout];
  }
}

- (void)setControlsHidden:(BOOL)value animated:(BOOL)animated
{
  if(_hideUI != value)
  {
    _hideUI = value;
    [self setNeedsLayout];
    if(animated == YES)
      [UIView animateWithDuration:0.3 animations:^{
        [self layoutIfNeeded];
      }];
    else
      [self layoutIfNeeded];
  }
}

- (void)setMinMagFilter:(NSString*)filter
{
  _pixelView.layer.minificationFilter = filter;
  _pixelView.layer.magnificationFilter = filter;
}

- (void)setPrimaryBuffer
{
  SISetScreen(_imageBuffer);
}

- (void)flipFrontBufferWidth:(int)width height:(int)height
{
  if(_imageBuffer == nil || _565ImageBuffer == nil)
    return;
  
  // make sure we're showing the proper amount of image
  [_pixelView updateBufferCropResWidth:width height:height];
  
  // we use two framebuffers to avoid copy-on-write due to us using UIImage. Little memory overhead, no speed overhead at all compared to that nasty IOSurface and SDK-safe, to boot
  if(((LMPixelLayer*)_pixelView.layer).displayMainBuffer == YES)
  {
    SISetScreen(_imageBufferAlt);
    
    [_pixelView setNeedsDisplay];
    
    ((LMPixelLayer*)_pixelView.layer).displayMainBuffer = NO;
  }
  else
  {
    SISetScreen(_imageBuffer);
    
    [_pixelView setNeedsDisplay];
    
    ((LMPixelLayer*)_pixelView.layer).displayMainBuffer = YES;
  }
}

@end

#pragma mark -

@implementation LMEmulatorControllerView(UIView)

- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if(self)
  {
    self.multipleTouchEnabled = YES;
    _viewMode = LMEmulatorControllerViewModeNormal;
    //_viewMode = LMEmulatorControllerViewModeScreenOnly;
    //_viewMode = LMEmulatorControllerViewModeControllerOnly;
    
    // screen
    _screenView = [[UIView alloc] initWithFrame:(CGRect){0,0,10,10}];
    _screenView.userInteractionEnabled = NO;
    [self addSubview:_screenView];
    
    _pixelView = [[LMPixelView alloc] initWithFrame:(CGRect){0,0,10,10}];
    [_screenView addSubview:_pixelView];
    
    _menuView = [[UIView alloc] initWithFrame:(CGRect){0,0,10,10}];
    [self addSubview:_menuView];
    
    // start / select buttons
    _startButton = [[LMButtonView alloc] init:SI_BUTTON_START];
    [_menuView addSubview:_startButton];
    
    _selectButton = [[LMButtonView alloc] init:SI_BUTTON_SELECT];
    [_menuView addSubview:_selectButton];
    
    // menu button
    _optionsButton = [[LMButtonView alloc] init:0];
    [_menuView addSubview:_optionsButton];
    
    _leftButtonView = [[UIView alloc] initWithFrame:(CGRect){0,0,110,145}];
    [self addSubview:_leftButtonView];
    _rightButtonView = [[UIView alloc] initWithFrame:(CGRect){0,0,110,145}];
    [self addSubview:_rightButtonView];
    
    // ABXY buttons
    _aButton = [[LMButtonView alloc] init:SI_BUTTON_A];
    [_rightButtonView addSubview:_aButton];
    
    _bButton = [[LMButtonView alloc] init:SI_BUTTON_B];
    [_rightButtonView addSubview:_bButton];
    
    _xButton = [[LMButtonView alloc] init:SI_BUTTON_X];
    [_rightButtonView addSubview:_xButton];
    
    _yButton = [[LMButtonView alloc] init:SI_BUTTON_Y];
    [_rightButtonView addSubview:_yButton];
    
    // L/R buttons
    _lButton = [[LMButtonView alloc] init:SI_BUTTON_L];
    [_leftButtonView addSubview:_lButton];
    
    _rButton = [[LMButtonView alloc] init:SI_BUTTON_R];
    [_rightButtonView addSubview:_rButton];
    
    // d-pad
    _dPadView = [[LMDPadView alloc] init];
    [_leftButtonView addSubview:_dPadView];
    
    // iCade support
    _iCadeControlView = [[LMBTControllerView alloc] initWithFrame:CGRectZero];
    [self addSubview:_iCadeControlView];
    _iCadeControlView.active = YES;
    
    // creating our buffers
    _bufferWidth = 512;
    _bufferHeight = 480;
    _bufferHeightExtended = 480;
    
    // RGBA888 format
    unsigned short defaultComponentCount = 4;
    unsigned short bufferBitsPerComponent = 8;
    unsigned int pixelSizeBytes = (_bufferWidth*bufferBitsPerComponent*defaultComponentCount)/8/_bufferWidth;
    if(pixelSizeBytes == 0)
      pixelSizeBytes = defaultComponentCount;
    unsigned int bufferBytesPerRow = _bufferWidth*pixelSizeBytes;
    CGBitmapInfo bufferBitmapInfo = kCGImageAlphaNoneSkipLast;
    
    // BGR 555 format (something weird)
    defaultComponentCount = 3;
    bufferBitsPerComponent = 5;
    pixelSizeBytes = 2;
    bufferBytesPerRow = _bufferWidth*pixelSizeBytes;
    bufferBitmapInfo = kCGImageAlphaNoneSkipFirst|kCGBitmapByteOrder16Little;
    
    if(_imageBuffer == nil)
    {
      _imageBuffer = (unsigned char*)calloc(_bufferWidth*_bufferHeightExtended, pixelSizeBytes);
    }
    if(_imageBufferAlt == nil)
    {
      _imageBufferAlt = (unsigned char*)calloc(_bufferWidth*_bufferHeightExtended, pixelSizeBytes);
    }
    if(_565ImageBuffer == nil)
      _565ImageBuffer = (unsigned char*)calloc(_bufferWidth*_bufferHeightExtended, 2);
    
    [(LMPixelLayer*)_pixelView.layer setImageBuffer:_imageBuffer
                                               width:_bufferWidth
                                              height:_bufferHeight
                                    bitsPerComponent:bufferBitsPerComponent
                                         bytesPerRow:bufferBytesPerRow
                                          bitmapInfo:bufferBitmapInfo];
    [(LMPixelLayer*)_pixelView.layer addAltImageBuffer:_imageBufferAlt];
  }
  return self;
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  
  BOOL fullScreen = [[NSUserDefaults standardUserDefaults] boolForKey:kLMSettingsFullScreen];
  
  UIColor* plasticColor = [UIColor colorWithRed:200/255.0 green:200/255.0 blue:200/255.0 alpha:1.0];
  UIColor* blackColor = [UIColor colorWithRed:100/255.0 green:100/255.0 blue:100/255.0 alpha:1.0];
  UIColor* bcolor = plasticColor;
  
  CGSize size = self.bounds.size;
  int originalWidth = 256;
  int originalHeight = 224;
  if (originalWidth*2<=size.width && originalHeight*2<=size.height) {
    originalWidth = 256*2;
    originalHeight = 224*2;
  }
  
  int width = originalWidth;
  int height = originalHeight;
  
  int screenBorderX = 20;
  int screenBorderY = 10;
  int buttonSpacing = 10;
  
  float controlsAlpha = 1.0;
  
  if(size.height > size.width)
  {
    // portrait
    CGSize screenViewSize = (CGSize){size.width,(int)((size.width*originalHeight)/originalWidth)};
    _screenView.frame = (CGRect){0,0,screenViewSize};
    
    if (size.height-_screenView.frame.size.height-_menuView.frame.size.height-_leftButtonView.frame.size.height>120) {
      screenBorderY = 60;
    }
    if (size.width-_leftButtonView.frame.size.width-_rightButtonView.frame.size.width>120) {
      screenBorderX = 50;
    }
    
    bcolor = plasticColor;
    _menuView.frame = (CGRect){0,0,_optionsButton.frame.size.width+_startButton.frame.size.width+_selectButton.frame.size.width+buttonSpacing*2,_optionsButton.frame.size.height};
    _menuView.frame = (CGRect){(size.width-_menuView.frame.size.width)*0.5,_screenView.frame.origin.y+_screenView.frame.size.height+screenBorderY,_menuView.frame.size};
    _optionsButton.frame = (CGRect){0,0,_optionsButton.frame.size};
    _startButton.frame = (CGRect){_optionsButton.frame.origin.x+_optionsButton.frame.size.width+buttonSpacing,_optionsButton.frame.origin.y,_startButton.frame.size};
    _selectButton.frame = (CGRect){_startButton.frame.origin.x+_startButton.frame.size.width+buttonSpacing,_optionsButton.frame.origin.y,_selectButton.frame.size};
    
    [_optionsButton portrait];
    [_startButton portrait];
    [_selectButton portrait];
    [_dPadView portrait];
    [_lButton portrait];
    [_rButton portrait];
    [_xButton portrait];
    [_yButton portrait];
    [_aButton portrait];
    [_bButton portrait];
  }
  else
  {
    // landscape
    CGSize screenViewSize = (CGSize){(int)((size.height*originalWidth)/originalHeight),size.height};
    _screenView.frame = (CGRect){(int)((size.width-screenViewSize.width)*0.5),0,screenViewSize};
    
    int boffset = (int)((((size.width-_screenView.frame.size.width)*0.5)-_leftButtonView.frame.size.width)*0.5);
    int moffset = (int)((((size.width-_screenView.frame.size.width)*0.5)-_menuView.frame.size.width)*0.5);
    screenBorderX = (boffset>=10) ? boffset : 10;
    screenBorderY = 20;
    buttonSpacing = 12;
    
    bcolor = blackColor;
    _menuView.frame = (CGRect){0,0,_optionsButton.frame.size.width,_optionsButton.frame.size.height+_startButton.frame.size.height+_selectButton.frame.size.height+20};
    _menuView.frame = (CGRect){(moffset>=screenBorderX)?moffset:screenBorderX,screenBorderY,_menuView.frame.size};
    _optionsButton.frame = (CGRect){0,0,_optionsButton.frame.size};
    _startButton.frame = (CGRect){0,_optionsButton.frame.origin.y+_optionsButton.frame.size.height+buttonSpacing,_startButton.frame.size};
    _selectButton.frame = (CGRect){0,_startButton.frame.origin.y+_startButton.frame.size.height+buttonSpacing,_selectButton.frame.size};
    
    [_optionsButton landscape];
    [_startButton landscape];
    [_selectButton landscape];
    [_dPadView landscape];
    [_lButton landscape];
    [_rButton landscape];
    [_xButton landscape];
    [_yButton landscape];
    [_aButton landscape];
    [_bButton landscape];
    
    if(fullScreen == YES && _hideUI == YES)
    {
      controlsAlpha = 0;
    }
  }
  
  if(fullScreen == YES)
  {
    height = _screenView.frame.size.height;
    width = _screenView.frame.size.width;
  }
  _pixelView.frame = (CGRect){(int)((_screenView.frame.size.width-width)*0.5),(int)((_screenView.frame.size.height-height)*0.5),width,height};
  
  _leftButtonView.frame = (CGRect){screenBorderX,size.height-_leftButtonView.frame.size.height-screenBorderY,_leftButtonView.frame.size};
  _rightButtonView.frame = (CGRect){size.width-screenBorderX-_rightButtonView.frame.size.width,_leftButtonView.frame.origin.y,_rightButtonView.frame.size};
  
  _dPadView.frame = (CGRect){0,_leftButtonView.frame.size.height-_dPadView.frame.size.height,_dPadView.frame.size};
  _lButton.frame = (CGRect){0,0, _lButton.frame.size};
  
  _rButton.frame = (CGRect){0,0,_rButton.frame.size};
  _xButton.frame = (CGRect){(int)((_rightButtonView.frame.size.width-_xButton.frame.size.width)*0.5),_dPadView.frame.origin.y,_xButton.frame.size};
  _yButton.frame = (CGRect){0,_dPadView.frame.origin.y+(int)((_dPadView.frame.size.height-_yButton.frame.size.height)*0.5),_yButton.frame.size};
  _aButton.frame = (CGRect){_rightButtonView.frame.size.width-_aButton.frame.size.width,_yButton.frame.origin.y,_aButton.frame.size};
  _bButton.frame = (CGRect){_xButton.frame.origin.x,_rightButtonView.frame.size.height-_bButton.frame.size.height,_bButton.frame.size};
  
  if(_viewMode == LMEmulatorControllerViewModeScreenOnly)
  {
    _pixelView.alpha = 1.0;
    controlsAlpha = 0;
    bcolor = blackColor;
  }
  else if(_viewMode == LMEmulatorControllerViewModeControllerOnly)
  {
    _pixelView.alpha = 0;
    controlsAlpha = 1.0;
  }
  else
  {
    _pixelView.alpha = 1.0;
  }
  
  self.backgroundColor = bcolor;
  _startButton.alpha = controlsAlpha;
  _selectButton.alpha = controlsAlpha;
  _leftButtonView.alpha = controlsAlpha;
  _rightButtonView.alpha = controlsAlpha;
  
}

@end

#pragma mark -

@implementation LMEmulatorControllerView(NSObject)

- (void)dealloc
{
  if(_imageBuffer != nil)
    free(_imageBuffer);
  _imageBuffer = nil;
  
  if(_imageBufferAlt != nil)
    free(_imageBufferAlt);
  _imageBufferAlt = nil;
  
  if(_565ImageBuffer != nil)
    free(_565ImageBuffer);
  _565ImageBuffer = nil;
  
  [_pixelView release];
  _pixelView = nil;
  
  [_startButton release];
  _startButton = nil;
  [_selectButton release];
  _selectButton = nil;
  [_aButton release];
  _aButton = nil;
  [_bButton release];
  _bButton = nil;
  [_yButton release];
  _yButton = nil;
  [_xButton release];
  _xButton = nil;
  [_lButton release];
  _lButton = nil;
  [_rButton release];
  _rButton = nil;
  [_dPadView release];
  _dPadView = nil;
  
  [_iCadeControlView release];
  _iCadeControlView = nil;
  
  [_optionsButton release];
  _optionsButton = nil;
  
  [super dealloc];
}

@end
