#import "DapiPlugin.h"
#import <DapiConnect/DapiConnect.h>

#define NULL_TO_NIL(obj) ({ __typeof__ (obj) __obj = (obj); [__obj isKindOfClass:[NSNull class]] ? nil : obj; })

@interface DapiPlugin () <DPCConnectDelegate,DPCAutoFlowDelegate>

@property (nonatomic, strong) NSMutableDictionary<NSString *, FlutterResult> *selectorResult;
@property (nonatomic, assign) BOOL isDapiStarted;
@property (nonatomic, strong) DPCAutoFlow *autoFlow;


@end

@implementation DapiPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"dapi"
            binaryMessenger:[registrar messenger]];
  DapiPlugin* instance = [[DapiPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
    
    FlutterEventChannel *successfulConnectionEventChannel = [FlutterEventChannel eventChannelWithName:@"co.dapi.connect/connect_success_channel" binaryMessenger:[registrar messenger]];
    instance.successfulConnectionStream = [[SuccessfulConnectionStream alloc] init];
    [successfulConnectionEventChannel setStreamHandler:instance.successfulConnectionStream];
    
    FlutterEventChannel *failureConnectionEventChannel = [FlutterEventChannel eventChannelWithName:@"co.dapi.connect/connect_failure_channel" binaryMessenger:[registrar messenger]];
    instance.failureConnectionStream = [[FailureConnectionStream alloc] init];
    [failureConnectionEventChannel setStreamHandler:instance.failureConnectionStream];
    
    FlutterEventChannel *bankRequestEventChannel = [FlutterEventChannel eventChannelWithName:@"co.dapi.connect/bank_request_channel" binaryMessenger:[registrar messenger]];
    instance.bankRequestStream = [[BankRequestStream alloc] init];
    [bankRequestEventChannel setStreamHandler:instance.bankRequestStream];
    
    FlutterEventChannel *connectDismissedEventChannel = [FlutterEventChannel eventChannelWithName:@"co.dapi.connect/connect_dismissed_channel" binaryMessenger:[registrar messenger]];
    instance.connectDismissedStream = [[ConnectDismissedStream alloc] init];
    [connectDismissedEventChannel setStreamHandler:instance.connectDismissedStream];
    
    FlutterEventChannel *transferUiDismissedEventChannel = [FlutterEventChannel eventChannelWithName:@"co.dapi.connect/transfer_ui_dismissed_channel" binaryMessenger:[registrar messenger]];
    instance.transferUiDismissedStream = [[TransferUiDismissedStream alloc] init];
    [transferUiDismissedEventChannel setStreamHandler:instance.transferUiDismissedStream];
    
    FlutterEventChannel *transferUiWillSendEventChannel = [FlutterEventChannel eventChannelWithName:@"co.dapi.connect/transfer_ui_will_send_channel" binaryMessenger:[registrar messenger]];
    instance.transferUiWillSendStream = [[TransferUiWillSendStream alloc] init];
    [transferUiWillSendEventChannel setStreamHandler:instance.transferUiWillSendStream];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.selectorResult = [NSMutableDictionary dictionary];
    }
    return self;
}


- (void)connectDidFailConnectingToBankID:(nonnull NSString *)bankID withError:(nonnull NSString *)error {
    [self.failureConnectionStream send:@{
        @"bankID": NULL_TO_NIL(bankID),
        @"error": NULL_TO_NIL(error.description)
}];
}

- (void)connectDidSuccessfullyConnectToBankID:(nonnull NSString *)bankID connection:(nonnull DPCBankConnection *)connection {
    [self.successfulConnectionStream send:@{
        @"bankID": NULL_TO_NIL(bankID),
        @"userID": NULL_TO_NIL(connection.userID)
    }];
}

- (void)connectDidRequestBank:(nonnull NSString *)bankName iban:(nonnull NSString *)iban {
    [self.bankRequestStream send:@{
        @"bankName": NULL_TO_NIL(bankName),
        @"iban": NULL_TO_NIL(iban)
    }];
}

- (void)connectDidDismiss {
    [self.connectDismissedStream send: nil];
}


- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    BOOL isImplemented = NO;
    SEL selector = NSSelectorFromString(call.method);
    if ([self respondsToSelector:selector]) {
        isImplemented = YES;
        
        [self.selectorResult setObject:result forKey:call.method];
        
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:selector]];
        invocation.selector = selector;
        invocation.target = self;
        
        /*
         * Indices 0 and 1 indicate the hidden arguments self and _cmd,
         * respectively; you should set these values directly with the target and selector properties.
         * Use indices 2 and greater for the arguments normally passed in a message.
         */
        __block NSUInteger index = 2;
        NSArray<NSObject *> *arguments = call.arguments;
        [arguments enumerateObjectsUsingBlock:^(NSObject * _Nonnull arg, NSUInteger idx, BOOL * _Nonnull stop) {
            [invocation setArgument:&(arg) atIndex:index];
            index++;
        }];
        
        [invocation invoke];
        
        NSMethodSignature *signature = [invocation methodSignature];
        const char *type = [signature methodReturnType];
        
        if (strcmp(type, "v") != 0) {
            void *returnValue;
            [invocation getReturnValue:&returnValue];
            NSObject *resultSet = (__bridge NSObject *)returnValue;
            result(resultSet);
        }
    }
    
    if (!isImplemented) {
        result(FlutterMethodNotImplemented);
    }
}

- (void)startWithAppKey:(NSString *)appKey clientUserID:(NSString *)clientUserID configurations:(NSDictionary *)configurations {
    DPCConfigurations *configs = [self nativeConfigurations:configurations];
    [Dapi startWithAppKey:appKey clientUserID:clientUserID configuration:configs completion:^(Dapi * _Nullable dapi, NSError * _Nullable error) {
        if (dapi) {
            self.isDapiStarted = YES;
        }else {
            NSString *resultKey = NSStringFromSelector(_cmd);
            FlutterResult flutterResult = [self.selectorResult objectForKey:resultKey];
            flutterResult(error.description);
        }
    }];
}

- (void) setConfigurations:(NSDictionary<NSString *, id> *)configs {
    DPCConfigurations *configurations = [self nativeConfigurations:configs];
    Dapi.sharedInstance.configurations = configurations;
}

- (void) configurations {
    NSString *resultKey = NSStringFromSelector(_cmd);
    FlutterResult flutterResult = [self.selectorResult objectForKey:resultKey];
    NSDictionary<NSString *, id> *jsConfigurations = [self jsConfigurations:Dapi.sharedInstance.configurations];
    flutterResult(jsConfigurations);
}


- (void)isStarted {
    NSString *resultKey = NSStringFromSelector(_cmd);
    FlutterResult flutterResult = [self.selectorResult objectForKey:resultKey];
    flutterResult([NSNumber numberWithBool:self.isDapiStarted]);
}

- (void)presentConnect {
    [Dapi.sharedInstance presentConnect:self];
}

- (void)dismissConnect {
    [Dapi.sharedInstance dismissConnect];
}

- (void)setClientUserID:(NSString *)clientUserID {
    Dapi.sharedInstance.clientUserID = clientUserID;
}

- (void)clientUserID {
    NSString *resultKey = NSStringFromSelector(_cmd);
    FlutterResult flutterResult = [self.selectorResult objectForKey:resultKey];
    flutterResult(Dapi.sharedInstance.clientUserID);
}

- (NSArray<NSDictionary<NSString *, id> *> *) getConnections {
    NSMutableArray *arrayObjects = [NSMutableArray array];
    [Dapi.sharedInstance.getConnections enumerateObjectsUsingBlock:^(DPCBankConnection * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:@selector(dictionaryRepresentation)]) {
            NSDictionary<NSString *, id> *dictionaryResponse = [obj valueForKey:@"dictionaryRepresentation"];
            [arrayObjects addObject:dictionaryResponse];
        }
    }];
    return arrayObjects;
}

- (void)createConnection:(NSString *)jsonConnectionParameters {
    NSString *resultKey = NSStringFromSelector(_cmd);
    FlutterResult flutterResult = [self.selectorResult objectForKey:resultKey];
    
    NSData *jsonData = [jsonConnectionParameters dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    NSDictionary<NSString *, id> *connectionParams = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&err];
    
    if (err) {
        flutterResult([self flutterErrorFromNSError:err]);
    }
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
    dispatch_async(queue, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [DPCBankConnection create:connectionParams completion:^(DPCBankConnection * _Nullable connection, NSError * _Nullable error) {
                if (error != nil) {
                    flutterResult([self flutterErrorFromNSError:error]);
                } else {
                    NSDictionary<NSString *, id> *dictionaryResponse = [connection valueForKey:@"dictionaryRepresentation"];
                    flutterResult(dictionaryResponse);
                }
            }];
        });
    });
}

- (void)getParameters:(NSString *)userID {
    NSString *resultKey = NSStringFromSelector(_cmd);
    FlutterResult flutterResult = [self.selectorResult objectForKey:resultKey];
    DPCBankConnection *bankConnection = [self bankConnectionForUserID:userID];
    NSDictionary<NSString *, id> *connectionParams = bankConnection.getConnectionParameters;
    
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:connectionParams options:NSJSONWritingPrettyPrinted error:&error];
    
    if (!jsonData) {
        flutterResult([self flutterErrorFromNSError:error]);
    } else {
        NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        flutterResult(json);
    }
}

- (void)getIdentity:(NSString *)userID {
    NSString *resultKey = NSStringFromSelector(_cmd);
    FlutterResult flutterResult = [self.selectorResult objectForKey:resultKey];
    DPCBankConnection *bankConnection = [self bankConnectionForUserID:userID];
    [bankConnection getIdentity:^(DPCIdentity * _Nullable identity, NSError * _Nullable error, NSString * _Nullable operationID) {
        [self respondForDictionaryRepresentableObject:identity error:error result:flutterResult];
    }];
}

- (void)getAccounts:(NSString *)userID {
    NSString *resultKey = NSStringFromSelector(_cmd);
    FlutterResult flutterResult = [self.selectorResult objectForKey:resultKey];
    DPCBankConnection *bankConnection = [self bankConnectionForUserID:userID];
    [bankConnection getAccounts:^(NSArray<DPCAccount *> * _Nullable accounts, NSError * _Nullable error, NSString * _Nullable operationID) {
        if(error) {
            [self respondForDictionaryRepresentableObject:nil error:error result:flutterResult];
        } else if (accounts.count > 0) {
            NSDictionary<NSString *, id> *dictionaryResponse = [accounts[0] valueForKey:@"dictionaryRepresentation"];
            [self respondForDictionaryRepresentableObject:dictionaryResponse error:error result:flutterResult];
        } else {
            NSDictionary<NSString *, id> *dictionaryResponse = @{@"operationID": operationID};
            [self respondForDictionaryRepresentableObject:dictionaryResponse error:error result:flutterResult];
        }
    }];
}

- (void)getCards:(NSString *)userID {
    NSString *resultKey = NSStringFromSelector(_cmd);
    FlutterResult flutterResult = [self.selectorResult objectForKey:resultKey];
    DPCBankConnection *bankConnection = [self bankConnectionForUserID:userID];
    [bankConnection getCards:^(NSArray<DPCCard *> * _Nullable result, NSError * _Nullable error, NSString * _Nullable operationID) {
        [self respondForDictionaryRepresentableObject:result error:error result:flutterResult];
    }];
}

- (void)getTransactionsForAccount:(NSString *)userID accountID:(NSString *)accountID startDate:(NSNumber *)startDate endDate:(NSNumber *)endDate {
    NSDate *fromDate = [NSDate dateWithTimeIntervalSince1970:startDate.doubleValue/1000];
    NSDate *toDate = [NSDate dateWithTimeIntervalSince1970:endDate.doubleValue/1000];
    
    NSString *resultKey = NSStringFromSelector(_cmd);
    FlutterResult flutterResult = [self.selectorResult objectForKey:resultKey];
    DPCBankConnection *bankConnection = [self bankConnectionForUserID:userID];
    __block DPCAccount *account;
    [bankConnection.accounts enumerateObjectsUsingBlock:^(DPCAccount * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.accountID isEqualToString:accountID]) {
            *stop = YES;
            account = obj;
        }
    }];
    [bankConnection getTransactionsForAccount:account fromDate:fromDate toDate:toDate completion:^(NSArray<DPCTransaction *> * _Nullable transactions, NSError * _Nullable error, NSString * _Nullable operationID) {
        if(error) {
            [self respondForDictionaryRepresentableObject:nil error:error result:flutterResult];
        } else if (transactions.count > 0) {
            NSDictionary<NSString *, id> *dictionaryResponse = [transactions[0] valueForKey:@"dictionaryRepresentation"];
            [self respondForDictionaryRepresentableObject:dictionaryResponse error:error result:flutterResult];
        } else {
            NSDictionary<NSString *, id> *dictionaryResponse = @{@"operationID": operationID};
            [self respondForDictionaryRepresentableObject:dictionaryResponse error:error result:flutterResult];
        }
    }];
}

- (void)getTransactionsForCard:(NSString *)userID cardID:(NSString *)cardID startDate:(NSDate *)startDate endDate:(NSDate *)endDate {
    NSString *resultKey = NSStringFromSelector(_cmd);
    FlutterResult flutterResult = [self.selectorResult objectForKey:resultKey];
    DPCBankConnection *bankConnection = [self bankConnectionForUserID:userID];
    __block DPCCard *card;
    [bankConnection.cards enumerateObjectsUsingBlock:^(DPCCard * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.cardID isEqualToString:cardID]) {
            *stop = YES;
            card = obj;
        }
    }];
    [bankConnection getTransactionsForCard:card fromDate:startDate toDate:endDate completion:^(NSArray<DPCTransaction *> * _Nullable transactions, NSError * _Nullable error, NSString * _Nullable operationID) {
        [self respondForDictionaryRepresentableObject:transactions error:error result:flutterResult];
    }];
}

- (void)getAccountsMetadata:(NSString *)userID {
    NSString *resultKey = NSStringFromSelector(_cmd);
    FlutterResult flutterResult = [self.selectorResult objectForKey:resultKey];
    DPCBankConnection *bankConnection = [self bankConnectionForUserID:userID];
    [bankConnection getAccountMetadata:^(DPCBankMetadata * _Nullable accountsMetadata, NSError * _Nullable error, NSString * _Nullable operationID) {
        [self respondForDictionaryRepresentableObject:accountsMetadata error:error result:flutterResult];
    }];
}

- (void)delete:(NSString *)userID {
    NSString *resultKey = NSStringFromSelector(_cmd);
    FlutterResult flutterResult = [self.selectorResult objectForKey:resultKey];
    DPCBankConnection *bankConnection = [self bankConnectionForUserID:userID];
    [bankConnection delete:^(DPCResult * _Nullable result, NSError * _Nullable error) {
        [self respondForDictionaryRepresentableObject:result error:error result:flutterResult];
    }];
}

- (void)getBeneficiaries:(NSString *)userID {
    NSString *resultKey = NSStringFromSelector(_cmd);
    FlutterResult flutterResult = [self.selectorResult objectForKey:resultKey];
    DPCBankConnection *bankConnection = [self bankConnectionForUserID:userID];
    [bankConnection getBeneficiaries:^(NSArray<DPCBankBeneficiary *> * _Nullable beneficiaries, NSError * _Nullable error, NSString * _Nullable operationID) {
        if(error) {
            [self respondForDictionaryRepresentableObject:nil error:error result:flutterResult];
        } else if (beneficiaries.count > 0) {
            NSDictionary<NSString *, id> *dictionaryResponse = [beneficiaries[0] valueForKey:@"dictionaryRepresentation"];
            [self respondForDictionaryRepresentableObject:dictionaryResponse error:error result:flutterResult];
        } else {
            NSDictionary<NSString *, id> *dictionaryResponse = @{@"operationID": operationID};
            [self respondForDictionaryRepresentableObject:dictionaryResponse error:error result:flutterResult];
        }
    }];
}

- (void)getWireBeneficiaries:(NSString *)userID {
    NSString *resultKey = NSStringFromSelector(_cmd);
    FlutterResult flutterResult = [self.selectorResult objectForKey:resultKey];
    DPCBankConnection *bankConnection = [self bankConnectionForUserID:userID];
    [bankConnection getWireBeneficiaries:^(NSArray<DPCBankWireBeneficiary *> * _Nullable beneficiaries, NSError * _Nullable error, NSString * _Nullable operationID) {
        if(error) {
            [self respondForDictionaryRepresentableObject:nil error:error result:flutterResult];
        } else if (beneficiaries.count > 0) {
            NSDictionary<NSString *, id> *dictionaryResponse = [beneficiaries[0] valueForKey:@"dictionaryRepresentation"];
            [self respondForDictionaryRepresentableObject:dictionaryResponse error:error result:flutterResult];
        } else {
            NSDictionary<NSString *, id> *dictionaryResponse = @{@"operationID": operationID};
            [self respondForDictionaryRepresentableObject:dictionaryResponse error:error result:flutterResult];
        }
    }];
}

- (void)createBeneficiary:(NSString *)userID beneficiary:(NSDictionary<NSString *, id> *)beneficiary {
    NSString *resultKey = NSStringFromSelector(_cmd);
    FlutterResult flutterResult = [self.selectorResult objectForKey:resultKey];
    DPCBankConnection *bankConnection = [self bankConnectionForUserID:userID];
    DPCBeneficiary *nativeBeneficiary = [self nativeBeneficiaryInfoFromDictionary:beneficiary];
    [bankConnection createBeneficiary:nativeBeneficiary completion:^(DPCResult * _Nullable result, NSError * _Nullable error, NSString * _Nullable operationID) {
                [self respondForDictionaryRepresentableObject:result error:error result:flutterResult];
    }];
}
- (void)createWireBeneficiary:(NSString *)userID beneficiary:(NSDictionary<NSString *, id> *)beneficiary {
    NSString *resultKey = NSStringFromSelector(_cmd);
    FlutterResult flutterResult = [self.selectorResult objectForKey:resultKey];
    DPCBankConnection *bankConnection = [self bankConnectionForUserID:userID];
    DPCWireBeneficiary *nativeBeneficiary = [self nativeWireBeneficiaryInfoFromDictionary:beneficiary];
    [bankConnection createWireBeneficiary:nativeBeneficiary completion:^(DPCResult * _Nullable result, NSError * _Nullable error, NSString * _Nullable operationID) {
                [self respondForDictionaryRepresentableObject:result error:error result:flutterResult];
    }];
}

- (void)createTransfer:(NSString *)userID accountID:(NSString *)accountID beneficiary:(NSDictionary<NSString *, id> *)beneficiary amount:(NSNumber *)amount remark:(NSString *)remark {
    double amountValue;
    if (amount && [amount isKindOfClass:[NSNumber class]]) {
        amountValue = [amount doubleValue];
    }else {
        amountValue = 0;
    }
    NSString *resultKey = NSStringFromSelector(_cmd);
    FlutterResult flutterResult = [self.selectorResult objectForKey:resultKey];
    DPCBankConnection *bankConnection = [self bankConnectionForUserID:userID];
    __block DPCAccount *account;
    [bankConnection.accounts enumerateObjectsUsingBlock:^(DPCAccount * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.accountID isEqualToString:accountID]) {
            *stop = YES;
            account = obj;
        }
    }];
    DPCBeneficiary *nativeBeneficiary = [self nativeBeneficiaryInfoFromDictionary:beneficiary];
    BOOL hasAmount = amount.doubleValue != 0 && amount.doubleValue != NSNotFound;
    BOOL hasAccount = account != nil;
   if (hasAccount && hasAmount) {
        [bankConnection createTransferFromAccount:account toBeneficiary:nativeBeneficiary amount:amountValue remark:remark completion:^(DPCAccount * _Nullable account, double amount, NSError * _Nullable error, NSString * _Nullable operationID) {
            if (error) {
                [self respondForDictionaryRepresentableObject:nil error:error result:flutterResult];
            } else {
                [self respondForDictionaryRepresentableObject:
                 @{
                    @"account": account.accountID ?: [NSNull null],
                    @"amount": [NSNumber numberWithDouble:amount],
                    @"operationID": operationID
                 } error:nil result:flutterResult];
            }
        }];
        return;
    } else {
        self.autoFlow = [[DPCAutoFlow alloc] initWithConnection:bankConnection
                                                        account:account
                                                         amount:amount.doubleValue
                                                    beneficiary:nativeBeneficiary
                                                         remark:remark
                                                     completion:^(DPCAccount * _Nonnull account,
                                                                  double amount,
                                                                  NSError * _Nullable error,
                                                                  NSString * _Nullable operationID,
                                                                  ReferenceNumber * _Nullable referenceNumber) {
            
            if (error) {
                [self respondForDictionaryRepresentableObject:nil error:error result:flutterResult];
            } else {
                [self respondForDictionaryRepresentableObject:
                 @{
                    @"account": account.accountID ?: [NSNull null],
                    @"amount": [NSNumber numberWithDouble:amount],
                    @"operationID": operationID
                 } error:nil result:flutterResult];
            }
            self.autoFlow = NULL;
        }];
        
        [self.autoFlow setAutoflowDelegate:self];
        [self.autoFlow present];
    }
}

- (void)createWireTransfer:(NSString *)userID accountID:(NSString *)accountID beneficiary:(NSDictionary<NSString *, id> *)beneficiary amount:(NSNumber *)amount remark:(NSString *)remark {
    double amountValue;
    if (amount && [amount isKindOfClass:[NSNumber class]]) {
        amountValue = [amount doubleValue];
    }else {
        amountValue = 0;
    }
    NSString *resultKey = NSStringFromSelector(_cmd);
    FlutterResult flutterResult = [self.selectorResult objectForKey:resultKey];
    DPCBankConnection *bankConnection = [self bankConnectionForUserID:userID];
    __block DPCAccount *account;
    [bankConnection.accounts enumerateObjectsUsingBlock:^(DPCAccount * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.accountID isEqualToString:accountID]) {
            *stop = YES;
            account = obj;
        }
    }];
    DPCWireBeneficiary *nativeBeneficiary = [self nativeWireBeneficiaryInfoFromDictionary:beneficiary];
    BOOL hasAmount = amount.doubleValue != 0 && amount.doubleValue != NSNotFound;
    BOOL hasAccount = account != nil;
   if (hasAccount && hasAmount) {
       [bankConnection createWireTransferFromAccount:account toWireBeneficiary:nativeBeneficiary amount:amountValue remark:remark completion:^(DPCAccount * _Nullable account, double amount, NSError * _Nullable error, NSString * _Nullable operationID) {
           if (error) {
               [self respondForDictionaryRepresentableObject:nil error:error result:flutterResult];
           } else {
               [self respondForDictionaryRepresentableObject:
                @{
                   @"account": account.accountID ?: [NSNull null],
                   @"amount": [NSNumber numberWithDouble:amount],
                   @"operationID": operationID
                } error:nil result:flutterResult];
           }
       }];
        return;
    } else {
        self.autoFlow = [[DPCAutoFlow alloc] initWithConnection:bankConnection
                                                        account:account
                                                         amount:amount.doubleValue
                                                wireBeneficiary:nativeBeneficiary
                                                         remark:remark
                                                     completion:^(DPCAccount * _Nonnull account,
                                                                  double amount,
                                                                  NSError * _Nullable error,
                                                                  NSString * _Nullable operationID,
                                                                  ReferenceNumber * _Nullable referenceNumber) {
    
            if (error) {
                [self respondForDictionaryRepresentableObject:nil error:error result:flutterResult];
            } else {
                [self respondForDictionaryRepresentableObject:
                 @{
                    @"account": account.accountID ?: [NSNull null],
                    @"amount": [NSNumber numberWithDouble:amount],
                    @"operationID": operationID
                 } error:nil result:flutterResult];
            }
            self.autoFlow = NULL;
        }];
        
        [self.autoFlow setAutoflowDelegate:self];
        [self.autoFlow present];
    }

}

- (void)createWireTransferToExistingBeneficiary:(NSString *)userID accountID:(NSString *)accountID receiverID:(NSString *)receiverID amount:(NSNumber *)amount remark:(NSString *)remark {
    double amountValue;
    if (amount && [amount isKindOfClass:[NSNumber class]]) {
        amountValue = [amount doubleValue];
    }else {
        amountValue = 0;
    }
    NSString *resultKey = NSStringFromSelector(_cmd);
    FlutterResult flutterResult = [self.selectorResult objectForKey:resultKey];
    DPCBankConnection *bankConnection = [self bankConnectionForUserID:userID];
    __block DPCAccount *account;
    [bankConnection.accounts enumerateObjectsUsingBlock:^(DPCAccount * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.accountID isEqualToString:accountID]) {
            *stop = YES;
            account = obj;
        }
    }];
    [bankConnection createWireTransferToExistingBeneficiaryFromAccount:account beneficiaryID:receiverID amount:amountValue remark:remark completion:^(DPCAccount * _Nullable account, double amount, NSError * _Nullable error, NSString * _Nullable operationID) {
        if (error) {
            [self respondForDictionaryRepresentableObject:nil error:error result:flutterResult];
        } else {
            [self respondForDictionaryRepresentableObject:
             @{
                @"account": account.accountID ?: [NSNull null],
                @"amount": [NSNumber numberWithDouble:amount],
                @"operationID": operationID
             } error:nil result:flutterResult];
        }
    }];
}

- (void)createTransferToExistingBeneficiary:(NSString *)userID accountID:(NSString *)accountID receiverID:(NSString *)receiverID amount:(NSNumber *)amount remark:(NSString *)remark {
    double amountValue;
    if (amount && [amount isKindOfClass:[NSNumber class]]) {
        amountValue = [amount doubleValue];
    }else {
        amountValue = 0;
    }
    NSString *resultKey = NSStringFromSelector(_cmd);
    FlutterResult flutterResult = [self.selectorResult objectForKey:resultKey];
    DPCBankConnection *bankConnection = [self bankConnectionForUserID:userID];
    __block DPCAccount *account;
    [bankConnection.accounts enumerateObjectsUsingBlock:^(DPCAccount * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.accountID isEqualToString:accountID]) {
            *stop = YES;
            account = obj;
        }
    }];
    [bankConnection createTransferToExistingBeneficiaryFromAccount:account beneficiaryID:receiverID amount:amountValue remark:remark completion:^(DPCAccount * _Nullable account, double amount, NSError * _Nullable error, NSString * _Nullable operationID) {
        if (error) {
            [self respondForDictionaryRepresentableObject:nil error:error result:flutterResult];
        } else {
            [self respondForDictionaryRepresentableObject:
             @{
                @"account": account.accountID ?: [NSNull null],
                @"amount": [NSNumber numberWithDouble:amount],
                @"operationID": operationID
             } error:nil result:flutterResult];
        }
    }];
}


// MARK: - Helper Methods
- (void)respondForDictionaryRepresentableObject:(NSObject *)object error:(NSError *)error result:(FlutterResult)result {
    
    if (error) {
        result([self flutterErrorFromNSError:error]);
    } else if ([object isKindOfClass:[NSArray class]]) {
        NSMutableArray<NSDictionary *> *resultObjectsArray = [NSMutableArray array];
        NSArray *arrayObjects = (NSArray *)object;
        __block NSError *castingError;
        
        [arrayObjects enumerateObjectsUsingBlock:^(id  _Nonnull element, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([element respondsToSelector:@selector(dictionaryRepresentation)]) {
                NSDictionary<NSString *, id> *dictionaryResponse = [element valueForKey:@"dictionaryRepresentation"];
                [resultObjectsArray addObject:dictionaryResponse];
            } else {
                castingError = [NSError errorWithDomain:@"com.dapi.dapiconnect.flutter" code:1012 userInfo:@{NSLocalizedDescriptionKey: @"Couldn't construct JSON representation of native array objects"}];
                *stop = YES;
            }
        }];
        if (castingError) {
            result([self flutterErrorFromNSError:castingError]);
        } else {
            result(resultObjectsArray);
        }
    } else {
        if ([object respondsToSelector:@selector(dictionaryRepresentation)]) {
            NSDictionary<NSString *, id> *dictionaryResponse = [object valueForKey:@"dictionaryRepresentation"];
            result(dictionaryResponse);
        } else if ([object isKindOfClass:[NSDictionary class]]) {
            result(object);
        } else {
            NSError *castingError = [NSError errorWithDomain:@"com.dapi.dapiconnect.flutter" code:1012 userInfo:@{NSLocalizedDescriptionKey: @"Couldn't construct JSON representation of native array objects"}];
            result([self flutterErrorFromNSError:castingError]);
        }
    }
}

- (FlutterError *)flutterErrorFromNSError:(NSError *)error {
    FlutterError *flutterError = [FlutterError errorWithCode:[NSString stringWithFormat:@"%@", [@(error.code) stringValue]] message:error.description details:nil];
    return flutterError;
}

- (DPCBeneficiary *)nativeBeneficiaryInfoFromDictionary:(NSDictionary<NSString *,id> *)beneficiaryInfoDictionary {
    DPCBeneficiary *beneficiary = [[DPCBeneficiary alloc] init];
    NSDictionary<NSString *, id> *lineAddressDictionary = [beneficiaryInfoDictionary objectForKey:@"linesAddress"];
    beneficiary.linesAddress = [[DPCLinesAddress alloc] initWithDictionary:lineAddressDictionary];
    beneficiary.accountNumber = [beneficiaryInfoDictionary objectForKey:@"accountNumber"];
    beneficiary.name = [beneficiaryInfoDictionary objectForKey:@"name"];
    beneficiary.bankName = [beneficiaryInfoDictionary objectForKey:@"bankName"];
    beneficiary.swiftCode = [beneficiaryInfoDictionary objectForKey:@"swiftCode"];
    beneficiary.iban = [beneficiaryInfoDictionary objectForKey:@"iban"];
    beneficiary.phoneNumber = [beneficiaryInfoDictionary objectForKey:@"phoneNumber"];
    beneficiary.country = [beneficiaryInfoDictionary objectForKey:@"country"];
    beneficiary.branchAddress = [beneficiaryInfoDictionary objectForKey:@"branchAddress"];
    beneficiary.branchName = [beneficiaryInfoDictionary objectForKey:@"branchName"];
    return beneficiary;
}

- (DPCWireBeneficiary *)nativeWireBeneficiaryInfoFromDictionary:(NSDictionary<NSString *,id> *)beneficiaryInfoDictionary {
    DPCWireBeneficiary *beneficiary = [[DPCWireBeneficiary alloc] init];
    NSDictionary<NSString *, id> *lineAddressDictionary = [beneficiaryInfoDictionary objectForKey:@"linesAddress"];
    beneficiary.linesAddress = [[DPCLinesAddress alloc] initWithDictionary:lineAddressDictionary];
    beneficiary.accountNumber = [beneficiaryInfoDictionary objectForKey:@"accountNumber"];
    beneficiary.name = [beneficiaryInfoDictionary objectForKey:@"name"];
    beneficiary.country = [beneficiaryInfoDictionary objectForKey:@"country"];
    beneficiary.receiverType = [beneficiaryInfoDictionary objectForKey:@"receiverType"];
    beneficiary.routingNumber = [beneficiaryInfoDictionary objectForKey:@"routingNumber"];
    beneficiary.nickname = [beneficiaryInfoDictionary objectForKey:@"nickname"];
    beneficiary.receiverAccountType = [beneficiaryInfoDictionary objectForKey:@"receiverAccountType"];
    beneficiary.firstName = [beneficiaryInfoDictionary objectForKey:@"firstName"];
    beneficiary.lastName = [beneficiaryInfoDictionary objectForKey:@"lastName"];
    beneficiary.zipCode = [beneficiaryInfoDictionary objectForKey:@"zipCode"];
    beneficiary.state = [beneficiaryInfoDictionary objectForKey:@"state"];
    beneficiary.city = [beneficiaryInfoDictionary objectForKey:@"city"];
    return beneficiary;
}

- (DPCConfigurations *)nativeConfigurations:(NSDictionary<NSString *, id> *)configs {
    NSArray *countries = [configs objectForKey:@"countries"];
    NSString *environment = [configs objectForKey:@"environment"];
    
    DPCConfigurations *configurations = [[DPCConfigurations alloc] initWithCountries:countries environment:environment];
    
    NSDictionary<NSString *, NSDictionary<NSString *, NSString *> *> *endPointExtraHeaderFields = [configs objectForKey:@"endPointExtraHeaderFields"];
    NSDictionary<NSString *, NSDictionary<NSString *, id> *> *endPointExtraBody = [configs objectForKey:@"endPointExtraBody"];
    NSDictionary<NSString *, NSString *> *endpoints = [configs objectForKey:@"endpoints"];

    configurations.endPointExtraHeaderFields = endPointExtraHeaderFields;
    configurations.endPointExtraBody = endPointExtraBody;
    configurations.endpoints = endpoints;
    NSNumber *showCloseButton = [configs objectForKey:@"showCloseButton"];
    NSNumber *showLogos = [configs objectForKey:@"showLogos"];
    NSNumber *showAddButton = [configs objectForKey:@"showAddButton"];
    NSNumber *showTransferSuccessfulResult = [configs objectForKey:@"showTransferSuccessfulResult"];
    NSNumber *showTransferErrorResult = [configs objectForKey:@"showTransferErrorResult"];
    NSString *postSuccessfulConnectionLoadingText = [configs objectForKey:@"postSuccessfulConnectionLoadingText"];
    
    if (NULL_TO_NIL(showCloseButton) != nil) {
        configurations.showCloseButton = showCloseButton.boolValue;
    }
    
    if (NULL_TO_NIL(showLogos) != nil) {
        configurations.showLogos = showLogos.boolValue;
    }
    
    if (NULL_TO_NIL(showAddButton) != nil) {
        configurations.showAddAccountButton = showAddButton.boolValue;
    }
    
    if (NULL_TO_NIL(showTransferSuccessfulResult) != nil) {
        configurations.showTransferSuccessfulResult = showTransferSuccessfulResult.boolValue;
    }
    
    if (NULL_TO_NIL(showTransferErrorResult) != nil) {
        configurations.showTransferErrorResult = showTransferErrorResult.boolValue;
    }
    
    if (NULL_TO_NIL(postSuccessfulConnectionLoadingText) != nil) {
        configurations.postSuccessfulConnectionLoadingText = postSuccessfulConnectionLoadingText;
    }

    return configurations;
}

- (NSDictionary<NSString *, id> *)jsConfigurations:(DPCConfigurations *)configs {
    return @{
        @"countries": configs.countries ?: [NSNull null],
        @"environment": configs.environment ?: [NSNull null],
        @"endpoints": configs.endpoints ?: [NSNull null],
        @"endPointExtraQueryItems": configs.endPointExtraQueryItems ?: [NSNull null],
        @"endPointExtraHeaderFields": configs.endPointExtraHeaderFields ?: [NSNull null],
        @"endPointExtraBody": configs.endPointExtraBody ?: [NSNull null],
        @"showCloseButton": [NSNumber numberWithBool:configs.showCloseButton],
        @"showLogos": [NSNumber numberWithBool:configs.showCloseButton],
        @"showAddButton": [NSNumber numberWithBool:configs.showAddAccountButton],
        @"showTransferSuccessfulResult": [NSNumber numberWithBool:configs.showTransferSuccessfulResult],
        @"showTransferErrorResult": [NSNumber numberWithBool:configs.showTransferErrorResult],

    };
}

- (DPCBankConnection *)bankConnectionForUserID:(NSString *)userID {
    __block DPCBankConnection *bankConnection;
    [Dapi.sharedInstance.getConnections enumerateObjectsUsingBlock:^(DPCBankConnection * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.userID isEqualToString:userID]) {
            *stop = YES;
            bankConnection = obj;
        }
    }];
    
    return bankConnection;
}

- (void)autoFlow:(nonnull DPCAutoFlow *)autoFlow willTransferAmount:(double)amount fromAccount:(nonnull DPCAccount *)senderAccount { 
    [self.transferUiWillSendStream send:@{
        @"amount": [NSNumber numberWithDouble:amount],
        @"account": NULL_TO_NIL(senderAccount.accountID)
    }];

}

@end

@implementation SuccessfulConnectionStream {
    FlutterEventSink _eventSink;
}

- (FlutterError *_Nullable)onListenWithArguments:(id _Nullable)arguments eventSink:(FlutterEventSink)events {
    _eventSink = events;
    return nil;
}

- (void)send:(NSDictionary *)data {
    if (_eventSink) {
        _eventSink(data);
    }
}

- (FlutterError *_Nullable)onCancelWithArguments:(id _Nullable)arguments {
    _eventSink = nil;
    return nil;
}

@end

@implementation FailureConnectionStream {
    FlutterEventSink _eventSink;
}

- (FlutterError *_Nullable)onListenWithArguments:(id _Nullable)arguments eventSink:(FlutterEventSink)events {
    _eventSink = events;
    return nil;
}

- (void)send:(NSDictionary *)data {
    if (_eventSink) {
        _eventSink(data);
    }
}

- (FlutterError *_Nullable)onCancelWithArguments:(id _Nullable)arguments {
    _eventSink = nil;
    return nil;
}

@end

@implementation BankRequestStream {
    FlutterEventSink _eventSink;
}

- (FlutterError *_Nullable)onListenWithArguments:(id _Nullable)arguments eventSink:(FlutterEventSink)events {
    _eventSink = events;
    return nil;
}

- (void)send:(NSDictionary *)data {
    if (_eventSink) {
        _eventSink(data);
    }
}

- (FlutterError *_Nullable)onCancelWithArguments:(id _Nullable)arguments {
    _eventSink = nil;
    return nil;
}

@end

@implementation ConnectDismissedStream {
    FlutterEventSink _eventSink;
}

- (FlutterError *_Nullable)onListenWithArguments:(id _Nullable)arguments eventSink:(FlutterEventSink)events {
    _eventSink = events;
    return nil;
}

- (void)send:(NSDictionary *)data {
    if (_eventSink) {
        _eventSink(data);
    }
}

- (FlutterError *_Nullable)onCancelWithArguments:(id _Nullable)arguments {
    _eventSink = nil;
    return nil;
}

@end

@implementation TransferUiDismissedStream {
    FlutterEventSink _eventSink;
}

- (FlutterError *_Nullable)onListenWithArguments:(id _Nullable)arguments eventSink:(FlutterEventSink)events {
    _eventSink = events;
    return nil;
}

- (void)send:(NSDictionary *)data {
    if (_eventSink) {
        _eventSink(data);
    }
}

- (FlutterError *_Nullable)onCancelWithArguments:(id _Nullable)arguments {
    _eventSink = nil;
    return nil;
}

@end

@implementation TransferUiWillSendStream {
    FlutterEventSink _eventSink;
}

- (FlutterError *_Nullable)onListenWithArguments:(id _Nullable)arguments eventSink:(FlutterEventSink)events {
    _eventSink = events;
    return nil;
}

- (void)send:(NSDictionary *)data {
    if (_eventSink) {
        _eventSink(data);
    }
}

- (FlutterError *_Nullable)onCancelWithArguments:(id _Nullable)arguments {
    _eventSink = nil;
    return nil;
}

@end
