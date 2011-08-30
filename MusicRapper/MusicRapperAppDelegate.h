//
//  MusicRapperAppDelegate.h
//  MusicRapper
//
//  Created by Taylor Hughes on 8/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import "SongInfo.h"
#import "Scrobbler.h"

@interface MusicRapperAppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate, ScrobblerDelegate> {
@private
  NSWindow *window;
  WebView *webView;
  NSMenuItem *toggleLastFMItem;

  BOOL mini;
  BOOL hasLoadedMini;

  SongInfo *currentSong;
  Scrobbler *scrobbler;

  NSTimer *timer;
  NSTimeInterval lastAdvanced;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet WebView *webView;
@property (retain) NSTimer *timer;
@property (assign) IBOutlet NSMenuItem *toggleLastFMItem;

- (void) tick:(id)sender;
- (void) playPause:(id)sender;
- (void) nextSong:(id)sender;
- (void) previousSong:(id)sender;
- (void) processScriptResult:(WebScriptObject *)result;
- (void) loadMusicPage;

- (IBAction) toggleMiniPlayer:(id)sender;
- (IBAction) toggleLastFM:(id)sender;

@end
