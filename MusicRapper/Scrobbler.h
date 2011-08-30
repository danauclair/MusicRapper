//
//  Scrobbler.h
//  MusicRapper
//

#import <Foundation/Foundation.h>
#import "FMEngine.h"
#import "SBJson.h"
#import "SongInfo.h"

#define _DEFAULTS_SK_KEY_ @"lastFMSessionKey"
#define _DEFAULTS_USER_KEY_ @"lastFMUsername"

@protocol ScrobblerDelegate <NSObject>;
- (void)shouldRequestUserAuthorization:(NSURL *)url;
- (void)didAuthenticateLastFM:(NSString *)username;
@end

@interface Scrobbler : NSObject {
  id <ScrobblerDelegate> delegate;
  FMEngine *fmEngine;
  SBJsonParser *parser;
  NSString *authToken;
  NSString *sessionKey;
  NSString *username;
  BOOL isEnabled;
}

@property (nonatomic, readonly) BOOL isEnabled;
@property (nonatomic, assign) id <ScrobblerDelegate> delegate;

- (void) checkForExistingSession;
- (void) enable;
- (void) disable;
- (void) startSession;
- (void) tokenCallback:(NSString *)identifier data:(id)data;
- (void) sessionCallback:(NSString *)identifier data:(id)data;
- (void) updateNowPlaying:(SongInfo *)song;
- (void) updateNowPlayingCallback:(NSString *)identifier data:(id)data;
- (void) scrobbleSong:(SongInfo *)song;
- (void) scrobbleSongCallback:(NSString *)identifier data:(id)data;
- (void) finishedAuthenticationWithSessionKey:(NSString *)key username:(NSString *)username;

@end
