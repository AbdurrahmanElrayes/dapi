#import <Flutter/Flutter.h>
#import <DapiConnect/DapiConnect.h>

@class SuccessfulConnectionStream;
@class FailureConnectionStream;
@class BankRequestStream;
@class ConnectDismissedStream;
@class TransferUiDismissedStream;
@class TransferUiWillSendStream;


@interface DapiPlugin : NSObject<FlutterPlugin>
    @property SuccessfulConnectionStream *successfulConnectionStream;
    @property FailureConnectionStream *failureConnectionStream;
    @property BankRequestStream *bankRequestStream;
    @property ConnectDismissedStream *connectDismissedStream;
    @property TransferUiDismissedStream *transferUiDismissedStream;
    @property TransferUiWillSendStream *transferUiWillSendStream;


@end

@interface SuccessfulConnectionStream : NSObject <FlutterStreamHandler>
- (void)send:(NSDictionary *)data;
@end

@interface FailureConnectionStream : NSObject <FlutterStreamHandler>
- (void)send:(NSDictionary *)data;
@end

@interface BankRequestStream : NSObject <FlutterStreamHandler>
- (void)send:(NSDictionary *)data;
@end

@interface ConnectDismissedStream : NSObject <FlutterStreamHandler>
- (void)send:(NSDictionary *)data;
@end

@interface TransferUiDismissedStream : NSObject <FlutterStreamHandler>
- (void)send:(NSDictionary *)data;
@end

@interface TransferUiWillSendStream : NSObject <FlutterStreamHandler>
- (void)send:(NSDictionary *)data;
@end
