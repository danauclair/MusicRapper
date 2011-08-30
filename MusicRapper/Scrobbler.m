//
//  Scrobbler.m
//  MusicRapper
//

#import "Scrobbler.h"

@implementation Scrobbler

@synthesize delegate, isEnabled;

- (id) init {
  self = [super init];
  if (self) {
    fmEngine = [[FMEngine alloc] init];
    parser = [[SBJsonParser alloc] init];
    isEnabled = NO;
  }

  return self;
}

- (void) dealloc {
  [fmEngine release];
  fmEngine = nil;

  [parser release];
  parser = nil;
  
  [authToken release];
  authToken = nil;
  
  [sessionKey release];
  sessionKey = nil;
  
  [username release];
  username = nil;
  
  [super dealloc];
}

- (void) checkForExistingSession {
  // see if we have a saved session key and username to use
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSString *sk = nil;
  NSString *user = nil;
  
  if (defaults) {
    sk = [defaults objectForKey:_DEFAULTS_SK_KEY_];
    user = [defaults objectForKey:_DEFAULTS_USER_KEY_];
  }
  
  if (sk && user) {
    NSLog(@"Found existing Last.fm session key: %@ for user: %@.", sk, user);
    [self finishedAuthenticationWithSessionKey:sk username:user];
  }
}

- (void) enable {
  if (isEnabled) {
    return;
  }

  NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:_LASTFM_API_KEY_, @"api_key", nil];
  [fmEngine performMethod:@"auth.getToken"
               withTarget:self
           withParameters:params
                andAction:@selector(tokenCallback:data:)
             useSignature:YES
               httpMethod:POST_TYPE];	
}

- (void) disable {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

  if (defaults) {
    [defaults setObject:nil forKey:_DEFAULTS_SK_KEY_];
    [defaults setObject:nil forKey:_DEFAULTS_USER_KEY_];
    [defaults synchronize];
    NSLog(@"Removed Last.fm session key and username from user defaults.");
  }
  
  authToken = nil;
  sessionKey = nil;
  username = nil;
  isEnabled = NO;
}

- (void) tokenCallback:(NSString *)identifier data:(id)data {
  authToken = [[[parser objectWithData:data] valueForKey:@"token"] retain];
  NSLog(@"Got Last.fm auth token: %@", authToken);
  
  // WebView should now redirect to request authorization from the user for the API.
  NSURL *authURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.last.fm/api/auth/?api_key=%@&token=%@", _LASTFM_API_KEY_, authToken]];
  [self.delegate shouldRequestUserAuthorization:authURL];
}

- (void) startSession {
  NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                          authToken, @"token",
                          _LASTFM_API_KEY_, @"api_key",
                          nil];

  [fmEngine performMethod:@"auth.getSession"
               withTarget:self
           withParameters:params
                andAction:@selector(sessionCallback:data:)
             useSignature:YES
               httpMethod:POST_TYPE];	
}

- (void) sessionCallback:(NSString *)identifier data:(id)data {
  NSDictionary *sessionInfo = [[parser objectWithData:data] valueForKey:@"session"];
  NSString *sk = [sessionInfo valueForKey:@"key"];
  NSString *user = [sessionInfo valueForKey:@"name"];
  NSLog(@"Got Last.fm session key: %@ for user: %@.", sk, user);

  // Persist session key and username in user defaults.
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	if (defaults) {
		[defaults setObject:sk forKey:_DEFAULTS_SK_KEY_];
    [defaults setObject:user forKey:_DEFAULTS_USER_KEY_];
		[defaults synchronize];
	}
  
  [self finishedAuthenticationWithSessionKey:sk username:user];
}

- (void) finishedAuthenticationWithSessionKey:(NSString *)key username:(NSString *)user {
  sessionKey = [key retain];
  username = [user retain];
  
  [self.delegate didAuthenticateLastFM:username];
  
  isEnabled = YES;
}

- (void) updateNowPlaying:(SongInfo *)song {
  [song retain];
  // TODO: Add album parameter if we are ever able to pull it out reliably.
  NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                          song.title, @"track",
                          song.artist, @"artist",
                          [NSString stringWithFormat:@"%d", song.duration], @"duration",
                          sessionKey, @"sk",
                          _LASTFM_API_KEY_, @"api_key",
                          nil];

  [fmEngine performMethod:@"track.updateNowPlaying"
               withTarget:self
           withParameters:params
                andAction:@selector(updateNowPlayingCallback:data:)
             useSignature:YES
               httpMethod:POST_TYPE];
  [song release];
}

- (void) updateNowPlayingCallback:(NSString *)identifier data:(id)data {
  NSLog(@"Updated Now Playing on Last.fm: %@", [parser objectWithData:data]);
}

- (void) scrobbleSong:(SongInfo *)song {
  [song retain];
  // TODO: Add album parameter if we are ever able to pull it out reliably.
  NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                          song.title, @"track",
                          song.artist, @"artist",
                          [NSString stringWithFormat:@"%d", song.duration], @"duration",
                          [NSString stringWithFormat:@"%d", song.utcTimestamp], @"timestamp",
                          sessionKey, @"sk",
                          _LASTFM_API_KEY_, @"api_key",
                          nil];

  [fmEngine performMethod:@"track.scrobble"
               withTarget:self
           withParameters:params
                andAction:@selector(scrobbleSongCallback:data:)
             useSignature:YES
               httpMethod:POST_TYPE];
  [song release];
}

- (void) scrobbleSongCallback:(NSString *)identifier data:(id)data {
   NSLog(@"Scrobbled on Last.fm: %@", [parser objectWithData:data]);
}



@end
