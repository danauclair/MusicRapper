//
//  SongInfo.h
//  MusicRapper
//

#import <Foundation/Foundation.h>

@interface SongInfo : NSObject {
  NSString *artist;
  NSString *title;
  //NSString *album;
  int duration;
  int lastTime;
  int timeElapsed;
  BOOL hasScrobbled;
  int utcTimestamp;
}

@property(nonatomic, copy) NSString *artist;
@property(nonatomic, copy) NSString *title;
//@property(nonatomic, copy) NSString *album;
@property(nonatomic) int duration;
@property(nonatomic) BOOL hasScrobbled;
@property(readonly) int utcTimestamp;

-(void)markTime:(int)currentTime;
-(double)percentageCompleted;
-(BOOL)shouldScrobble;

@end
