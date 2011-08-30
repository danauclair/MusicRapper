//
//  MusicRapperAppDelegate.m
//  MusicRapper
//
//  Created by Taylor Hughes on 8/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MusicRapperAppDelegate.h"

@implementation MusicRapperAppDelegate

@synthesize window;
@synthesize webView;
@synthesize timer;
@synthesize toggleLastFMItem;

static NSString *PREF_WINDOW_FRAME_FULL = @"windowFrameFull";
static NSString *PREF_WINDOW_FRAME_MINI = @"windowFrameMini";

static CGFloat MINI_HEIGHT = 55.0 + 22.0;
static CGFloat MINI_WIDTH = 440.0;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
  scrobbler = [[Scrobbler alloc] init];
  scrobbler.delegate = self;
  [scrobbler checkForExistingSession];
  
  [self loadMusicPage];

  mini = NO;
  hasLoadedMini = NO;
  
  // Remember initial large size.
  if (![window setFrameUsingName:PREF_WINDOW_FRAME_FULL]) {
    // If this preference hasn't been saved yet, save it now.
    [window saveFrameUsingName:PREF_WINDOW_FRAME_FULL];
  }

  lastAdvanced = 0;
  self.timer = [NSTimer scheduledTimerWithTimeInterval:0.4
                                                target:self
                                              selector:@selector(tick:)
                                              userInfo:nil
                                               repeats:YES];
}

- (void) loadMusicPage {
  NSString *urlText = @"http://music.google.com/";
  [[webView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlText]]];
}
  
- (void) playPause:(id)sender {
  [[webView windowScriptObject] evaluateWebScript:@"SJBpost('playPause');"];
}

- (void) nextSong:(id)sender {
  [[webView windowScriptObject] evaluateWebScript:@"SJBpost('nextSong');"];
}

- (void) previousSong:(id)sender {
  [[webView windowScriptObject] evaluateWebScript:@"SJBpost('prevSong');"];
}

- (void) tick:(id)sender {
  //
  // WARNING: This is pretty crazy. This fixes a bug where the
  // player keeps playing past the end of the song instead of
  // advancing to the next track.
  //
  NSString *javascript = @"(function(){"
    "var convertToSeconds = function(el) {"
      "var time = (el && el.innerHTML) || '';"
      ""
      "var pieces = [];"
      "var rawPieces = time.split(':');"
      "for (var i = 0; i < rawPieces.length; i++) {"
        "var str = rawPieces[i].replace(/\\D+/, '');"
        "if (str != '') {"
          "pieces.push(parseInt(str, 10));"
        "}"
      "}"
      "if (!pieces.length) { return 0; }"
      ""
      "var total = 0;"
      "for (var i = 0; i < pieces.length; i++) {"
        "if (i > 0) { total *= 60; }"
        "total += pieces[i];"
      "}"
      "return total;"
    "};"
    "var currentTime = convertToSeconds(document.getElementById('currentTime'));"
    "var duration = convertToSeconds(document.getElementById('duration'));"
    "var artist = document.getElementById('playerArtist').firstChild.innerHTML;"
    "var title = document.getElementById('playerSongTitle').firstChild.innerHTML;"
    "return {"
      "artist: artist,"
      "title: title,"
      "currentTime: currentTime,"
      "duration: duration,"
      "shouldAdvance: (currentTime && duration && currentTime > duration)"
    "};"
  "})()";

  id result = [[webView windowScriptObject] evaluateWebScript:javascript];

  if (![result isMemberOfClass:[WebUndefined class]]) {
    [self processScriptResult:result];
  }
}

- (void) processScriptResult:(WebScriptObject *)result {
  // Results from JS object. It would be nice to have the album to scrobble as well, but it isn't easily available.
  // TODO: Is there anything else to check and replace besides &amp;s? Cocoa does not provide a great way to do this automatically.
  NSString *artist = [[result valueForKey:@"artist"] stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
  NSString *title = [[result valueForKey:@"title"] stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
  NSNumber *duration = [result valueForKey:@"duration"];
  NSNumber *currentTime = [result valueForKey:@"currentTime"];
  BOOL shouldForceAdvance = [[result valueForKey:@"shouldAdvance"] isEqualTo:[NSNumber numberWithInt:1]];
  
  // Check if a track change has occured...
  if (![currentSong.title isEqualToString:title] || ![currentSong.artist isEqualToString:artist]) {
    NSLog(@"Song Change: %@ - %@", artist, title);

    [currentSong release];
    currentSong = [[SongInfo alloc] init];
    currentSong.artist = artist;
    currentSong.title = title;
    currentSong.duration = [duration intValue]; // this usually isn't ready yet
    
    // update now playing
    if (scrobbler.isEnabled) {
      [scrobbler updateNowPlaying:currentSong];
    }
  } else {
    // allow duration to be set later since it shows up late to the party
    if (currentSong.duration != [duration intValue]) {
      currentSong.duration = [duration intValue];
    }

    // increment elapsed time within SongInfo if necessary
    [currentSong markTime:[currentTime intValue]];

    // scrobble the song to last.fm if we can
    if (scrobbler.isEnabled && !currentSong.hasScrobbled && [currentSong shouldScrobble]) {
      [scrobbler scrobbleSong:currentSong];
      currentSong.hasScrobbled = YES;
    }
  }

  // Don't attempt to hit "Next" a bunch of times in a row.
  NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
  if (shouldForceAdvance && now - lastAdvanced > 4.0) {
    NSLog(@"Advanced to the next track using magic.");
    [self nextSong:self];
    lastAdvanced = now;
  }
}

- (void) setMini:(BOOL)shouldBeMini {
  mini = shouldBeMini;
  
  if (mini) {
    [[window contentView] setAutoresizesSubviews:NO];
    [window setShowsResizeIndicator:NO];

    // Hasn't been loaded yet. Attempt to laod from preference.
    BOOL loadedFromPref = [window setFrameUsingName:PREF_WINDOW_FRAME_MINI];

    if (!hasLoadedMini) {
      hasLoadedMini = YES;

      NSRect miniRect = [window frame];
      // Always set the height and width in case this ever changes.
      miniRect.size.height = MINI_HEIGHT;
      miniRect.size.width = MINI_WIDTH;
      [window setFrame:miniRect display:YES];

      if (!loadedFromPref) {
        [window saveFrameUsingName:PREF_WINDOW_FRAME_MINI];
      }
    }
  } else {
    [window setFrameUsingName:PREF_WINDOW_FRAME_FULL];

    [[window contentView] setAutoresizesSubviews:YES];
    [window setShowsResizeIndicator:YES];
  }
}

- (IBAction) toggleMiniPlayer:(id)sender {
  [self setMini:!mini];
}

- (BOOL) windowShouldZoom:(NSWindow*)window toFrame:(NSRect)frame {
  [self toggleMiniPlayer:self];
  return NO;
}

- (void) windowDidResize:(NSNotification *)notification {
  if (!mini) {
    [window saveFrameUsingName:PREF_WINDOW_FRAME_FULL];
  }
}

- (void) windowDidMove:(NSNotification *)notification {
  if (!mini) {
    [window saveFrameUsingName:PREF_WINDOW_FRAME_FULL];
  } else {
    [window saveFrameUsingName:PREF_WINDOW_FRAME_MINI];
  }
}

- (IBAction) toggleLastFM:(id)sender {
  if (scrobbler.isEnabled) {
    [scrobbler disable];
    toggleLastFMItem.title = @"Connect to Last.fm";
  } else {
    [scrobbler enable];
  }
}

- (void) shouldRequestUserAuthorization:(NSURL *)url {
  // Redirect user to the authroization page and wait until webView loads
  // the grant access page to call the API and get a session key.
  [webView setFrameLoadDelegate:self];
  [[webView mainFrame] loadRequest:[NSURLRequest requestWithURL:url]];
}

- (void) webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
  // Detect if user accepted Last.fm auth... this kind of sucks
  NSString *javascript = @"(function(){"
    "return { location: window.location.href };"
  "})()";
  NSData *result = [[webView windowScriptObject] evaluateWebScript:javascript];
  NSString *location = [result valueForKey:@"location"];
  
  // If it was a successful auth, make request to get session key & reload Google music.
  if ([location isEqualToString:@"http://www.last.fm/api/grantaccess"]) {
    [scrobbler startSession];
    [self loadMusicPage];
  }
}

- (void) didAuthenticateLastFM:(NSString *)username {
  toggleLastFMItem.title = [@"Logout " stringByAppendingString:username];
}

@end
