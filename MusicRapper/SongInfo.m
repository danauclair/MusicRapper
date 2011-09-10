//
//  SongInfo.m
//  MusicRapper
//

#import "SongInfo.h"

@implementation SongInfo

@synthesize artist, title, duration, /*album,*/ hasScrobbled, utcTimestamp;

- (id) init {
  self = [super init];
  if (self != nil) {
    hasScrobbled = NO;
    lastTime = 0;
    timeElapsed = 0;;
    utcTimestamp = (int)[[NSDate date] timeIntervalSince1970];
  }
  return self;
}

- (void) dealloc {
  [artist release];
  artist = nil;
  
  [title release];
  title = nil;
  
  //[album release];
  //album = nil;

  [super dealloc];
}

- (void) markTime:(int)currentTime {
  if (duration > 0) {
    int delta = currentTime - lastTime;

    // Only increment time elapsed if a valid single second of natural playback
    // has elapsed. If the user seeks it will be +/- more than 1.
    if (delta == 1) {
      timeElapsed += delta;
    }

    lastTime = currentTime;
  }
}

- (double) percentageCompleted {
  return (double)timeElapsed / (double)duration;
}

- (BOOL) shouldScrobble {
  // A track should only be scrobbled when the following conditions have been met:
  // The track must be longer than 30 seconds.
  // And the track has been played for at least half its duration, or for 4 minutes (whichever occurs earlier.)
  // As soon as these conditions have been met, the scrobble request may be sent at any time. It is often most convenient to send a scrobble request when a track has finished playing.
  if (duration > 30 && ([self percentageCompleted] >= 0.5 || timeElapsed > (60 * 4))) {
    return YES;
  }
  return NO;
}

@end
