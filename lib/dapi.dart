import 'dart:async';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class Dapi {
  static const MethodChannel _channel = const MethodChannel('dapi');
  static const EventChannel _successfulConnectionChannel =
      const EventChannel('co.dapi.connect/connect_success_channel');
  static const EventChannel _failureConnectionChannel =
      const EventChannel('co.dapi.connect/connect_failure_channel');
  static const EventChannel _bankRequestChannel =
      const EventChannel('co.dapi.connect/bank_request_channel');
  static const EventChannel _connectDismissedChannel =
      const EventChannel('co.dapi.connect/connect_dismissed_channel');

  static const EventChannel _transferUiDismissedChannel =
      const EventChannel('co.dapi.connect/transfer_ui_dismissed_channel');

  static const EventChannel _transferUiWillSendChannel =
      const EventChannel('co.dapi.connect/transfer_ui_will_send_channel');

  static Stream<ConnectSuccessEvent> get onConnectionSuccessful =>
      _successfulConnectionChannel
          .receiveBroadcastStream()
          .map((event) => ConnectSuccessEvent._fromMap(event));

  static Stream<ConnectFailureEvent> get onConnectionFailure =>
      _failureConnectionChannel
          .receiveBroadcastStream()
          .map((event) => ConnectFailureEvent._fromMap(event));

  static Stream<BankRequestEvent> get onBankRequest => _bankRequestChannel
      .receiveBroadcastStream()
      .map((event) => BankRequestEvent._fromMap(event));

  static Stream<Null> get onConnectDismissed =>
      _connectDismissedChannel.receiveBroadcastStream().map((event) => event);

  static Stream<Null> get onTransferUiDismissed => _transferUiDismissedChannel
      .receiveBroadcastStream()
      .map((event) => event);

  static Stream<TransferUiWillSendEvent> get onTransferUiWillSend =>
      _transferUiWillSendChannel
          .receiveBroadcastStream()
          .map((event) => TransferUiWillSendEvent._fromMap(event));

  static Future<String?> start(String appKey, String clientUserID,
      {DapiConfigurations? configurations}) async {
    try {
      List<dynamic> params = <dynamic>[
        appKey,
        clientUserID,
        configurations?._toMap()
      ];
      final String? error = await _channel.invokeMethod(
          'startWithAppKey:clientUserID:configurations:', params);
      return error;
    } on PlatformException catch (ex) {
      throw DapiSdkException(ex.code, ex.message);
    }
  }

  static void setConfigurations(DapiConfigurations configurations) async {
    try {
      List<dynamic> params = <dynamic>[configurations._toMap()];
      _channel.invokeMethod('setConfigurations:', params);
    } on PlatformException catch (ex) {
      throw DapiSdkException(ex.code, ex.message);
    }
  }

  static Future<DapiConfigurations> configurations() async {
    try {
      final Map mapResult = await _channel.invokeMethod('configurations');
      final DapiConfigurations configurations =
          DapiConfigurations._fromMap(mapResult);
      return configurations;
    } on PlatformException catch (ex) {
      throw DapiSdkException(ex.code, ex.message);
    }
  }

  static void presentConnect() {
    try {
      _channel.invokeMethod('presentConnect');
    } on PlatformException catch (ex) {
      throw DapiSdkException(ex.code, ex.message);
    }
  }

  static void dismissConnect() {
    try {
      _channel.invokeMethod('dismissConnect');
    } on PlatformException catch (ex) {
      throw DapiSdkException(ex.code, ex.message);
    }
  }

  static Future<bool> isStarted() async {
    try {
      final bool isStarted = await _channel.invokeMethod('isStarted');
      return isStarted;
    } on PlatformException catch (ex) {
      throw DapiSdkException(ex.code, ex.message);
    }
  }

  static void setClientUserID(String clientUserID) async {
    try {
      List<dynamic> params = <dynamic>[clientUserID];
      _channel.invokeMethod('setClientUserID:', params);
    } on PlatformException catch (ex) {
      throw DapiSdkException(ex.code, ex.message);
    }
  }

  static Future<String?> clientUserID() async {
    try {
      final String? clientUserID = await _channel.invokeMethod('clientUserID');
      return clientUserID;
    } on PlatformException catch (ex) {
      throw DapiSdkException(ex.code, ex.message);
    }
  }

  static Future<List<DapiConnection>> getConnections() async {
    try {
      final List<dynamic> jsonInstances =
          await _channel.invokeMethod('getConnections');
      List<Map<String, dynamic>> mappedJsonInstances =
          jsonInstances.map((e) => Map<String, dynamic>.from(e)).toList();
      List<DapiConnection> connections =
          mappedJsonInstances.map((e) => DapiConnection._fromMap(e)).toList();
      return connections;
    } on PlatformException catch (ex) {
      throw DapiSdkException(ex.code, ex.message);
    }
  }

  static Future<DapiConnection> _createConnection(
      String jsonConnectionParams) async {
    try {
      List<dynamic> params = <dynamic>[jsonConnectionParams];
      final dynamic jsonInstance =
          await _channel.invokeMethod('createConnection:', params);
      DapiConnection connection = DapiConnection._fromMap(jsonInstance);
      return connection;
    } on PlatformException catch (ex) {
      throw DapiSdkException(ex.code, ex.message);
    }
  }

  static Future<String> _getParameters(String userID) async {
    try {
      List<dynamic> params = <dynamic>[userID];
      final dynamic jsonInstance =
          await _channel.invokeMethod('getParameters:', params);
      String connectionParams = jsonInstance.toString();
      return connectionParams;
    } on PlatformException catch (ex) {
      throw DapiSdkException(ex.code, ex.message);
    }
  }

  static Future<DapiIdentityResponse> _getIdentity(String userID) async {
    try {
      List<dynamic> params = <dynamic>[userID];
      final Map mapResult = await _channel.invokeMethod('getIdentity:', params);
      final DapiIdentityResponse identity =
          DapiIdentityResponse._fromMap(mapResult);
      return identity;
    } on PlatformException catch (ex) {
      throw DapiSdkException(ex.code, ex.message);
    }
  }

  static Future<DapiAccountsResponse> _getAccounts(String userID) async {
    try {
      List<dynamic> params = <dynamic>[userID];
      final Map mapResult = await _channel.invokeMethod('getAccounts:', params);
      final DapiAccountsResponse accounts =
          DapiAccountsResponse._fromMap(mapResult);
      return accounts;
    } on PlatformException catch (ex) {
      throw DapiSdkException(ex.code, ex.message);
    }
  }

  static Future<DapiCardsResponse> _getCards(String userID) async {
    try {
      List<dynamic> params = <dynamic>[userID];
      final Map mapResult = await _channel.invokeMethod('getCards:', params);
      final DapiCardsResponse cards = DapiCardsResponse._fromMap(mapResult);
      return cards;
    } on PlatformException catch (ex) {
      throw DapiSdkException(ex.code, ex.message);
    }
  }

  static Future<DapiTransactionsResponse> _getTransactionsForAccount(
      String userID,
      String accountID,
      DateTime fromDate,
      DateTime toDate) async {
    final List<dynamic> params = [
      userID,
      accountID,
      fromDate.millisecondsSinceEpoch,
      toDate.millisecondsSinceEpoch,
    ];
    try {
      final Map mapResult = await _channel.invokeMethod(
          'getTransactionsForAccount:accountID:startDate:endDate:', params);
      final DapiTransactionsResponse transactions =
          DapiTransactionsResponse._fromMap(mapResult);
      return transactions;
    } on PlatformException catch (ex) {
      throw DapiSdkException(ex.code, ex.message);
    }
  }

  static Future<DapiTransactionsResponse> _getTransactionsForCard(
      String userID, String cardID, DateTime fromDate, DateTime toDate) async {
    final List<dynamic> params = [
      userID,
      cardID,
      fromDate.millisecondsSinceEpoch,
      toDate.millisecondsSinceEpoch,
    ];
    try {
      final Map mapResult = await _channel.invokeMethod(
          'getTransactionsForCard:cardID:startDate:endDate:', params);
      final DapiTransactionsResponse transactions =
          DapiTransactionsResponse._fromMap(mapResult);
      return transactions;
    } on PlatformException catch (ex) {
      throw DapiSdkException(ex.code, ex.message);
    }
  }

  static Future<DapiAccountsMetadataResponse> _getAccountsMetadata(
      String userID) async {
    try {
      List<dynamic> params = <dynamic>[userID];
      final Map mapResult =
          await _channel.invokeMethod('getAccountsMetadata:', params);
      final DapiAccountsMetadataResponse accountsMetaData =
          DapiAccountsMetadataResponse._fromMap(mapResult);
      return accountsMetaData;
    } on PlatformException catch (ex) {
      throw DapiSdkException(ex.code, ex.message);
    }
  }

  static Future<DapiResult> _delete(String userID) async {
    try {
      List<dynamic> params = <dynamic>[userID];
      final Map mapResult = await _channel.invokeMethod('delete:', params);
      final DapiResult result = DapiResult._fromMap(mapResult);
      return result;
    } on PlatformException catch (ex) {
      throw DapiSdkException(ex.code, ex.message);
    }
  }

  static Future<DapiBeneficiariesResponse> _getBeneficiaries(
      String userID) async {
    try {
      List<dynamic> params = <dynamic>[userID];
      final Map mapResult =
          await _channel.invokeMethod('getBeneficiaries:', params);
      final DapiBeneficiariesResponse beneficiaries =
          DapiBeneficiariesResponse._fromMap(mapResult);
      return beneficiaries;
    } on PlatformException catch (ex) {
      throw DapiSdkException(ex.code, ex.message);
    }
  }

  static Future<DapiResult> _createBeneficiary(
      String userID, DapiBeneficiary beneficiary) async {
    try {
      final List<dynamic> params = [
        userID,
        beneficiary._toMap(),
      ];
      final Map mapResult =
          await _channel.invokeMethod('createBeneficiary:beneficiary:', params);
      final DapiResult result = DapiResult._fromMap(mapResult);
      return result;
    } on PlatformException catch (ex) {
      throw DapiSdkException(ex.code, ex.message);
    }
  }

  static Future<CreateTransferResponse> _createTransfer(
    String userID,
    String? accountID,
    DapiBeneficiary? beneficiary,
    double? amount,
    String? remark,
  ) async {
    final List<dynamic> params = [
      userID,
      accountID,
      beneficiary?._toMap(),
      amount,
      remark
    ];
    try {
      final Map mapResult = await _channel.invokeMethod(
          'createTransfer:accountID:beneficiary:amount:remark:', params);
      final CreateTransferResponse result =
          CreateTransferResponse._fromMap(mapResult);
      return result;
    } on PlatformException catch (ex) {
      throw DapiSdkException(ex.code, ex.message);
    }
  }

  static Future<CreateTransferResponse> _createTransferToExistingBeneficiary(
    String userID,
    String accountID,
    String receiverID,
    double amount,
    String? remark,
  ) async {
    final List<dynamic> params = [
      userID,
      accountID,
      receiverID,
      amount,
      remark
    ];
    try {
      final Map mapResult = await _channel.invokeMethod(
          'createTransferToExistingBeneficiary:accountID:receiverID:amount:remark:',
          params);
      final CreateTransferResponse result =
          CreateTransferResponse._fromMap(mapResult);
      return result;
    } on PlatformException catch (ex) {
      throw DapiSdkException(ex.code, ex.message);
    }
  }

  static Future<DapiWireBeneficiariesResponse> _getWireBeneficiaries(
      String userID) async {
    try {
      List<dynamic> params = <dynamic>[userID];
      final Map mapResult =
          await _channel.invokeMethod('getWireBeneficiaries:', params);
      final DapiWireBeneficiariesResponse beneficiaries =
          DapiWireBeneficiariesResponse._fromMap(mapResult);
      return beneficiaries;
    } on PlatformException catch (ex) {
      throw DapiSdkException(ex.code, ex.message);
    }
  }

  static Future<DapiResult> _createWireBeneficiary(
      String userID, DapiWireBeneficiary beneficiary) async {
    try {
      final List<dynamic> params = [
        userID,
        beneficiary._toMap(),
      ];
      final Map mapResult = await _channel.invokeMethod(
          'createWireBeneficiary:beneficiary:', params);
      final DapiResult result = DapiResult._fromMap(mapResult);
      return result;
    } on PlatformException catch (ex) {
      throw DapiSdkException(ex.code, ex.message);
    }
  }

  static Future<CreateTransferResponse> _createWireTransfer(
    String userID,
    String? accountID,
    DapiWireBeneficiary beneficiary,
    double? amount,
    String? remark,
  ) async {
    final List<dynamic> params = [
      userID,
      accountID,
      beneficiary._toMap(),
      amount,
      remark
    ];
    try {
      final Map mapResult = await _channel.invokeMethod(
          'createWireTransfer:accountID:beneficiary:amount:remark:', params);
      final CreateTransferResponse result =
          CreateTransferResponse._fromMap(mapResult);
      return result;
    } on PlatformException catch (ex) {
      throw DapiSdkException(ex.code, ex.message);
    }
  }

  static Future<CreateTransferResponse>
      _createWireTransferToExistingBeneficiary(
    String userID,
    String accountID,
    String receiverID,
    double amount,
    String? remark,
  ) async {
    final List<dynamic> params = [
      userID,
      accountID,
      receiverID,
      amount,
      remark
    ];
    try {
      final Map mapResult = await _channel.invokeMethod(
          'createWireTransferToExistingBeneficiary:accountID:receiverID:amount:remark:',
          params);
      final CreateTransferResponse result =
          CreateTransferResponse._fromMap(mapResult);
      return result;
    } on PlatformException catch (ex) {
      throw DapiSdkException(ex.code, ex.message);
    }
  }
}

class DapiConfigurations {
  DapiEnvironment environment;
  List<String> countries;
  Map<String, String>? endpoints;
  Map<String, dynamic>? extraBody;
  Map<String, dynamic>? extraQueryParameters;
  Map<String, dynamic>? extraHeaderFields;
  bool? showLogos = true;
  bool? showExperimentalBanks = false;
  bool? showCloseButton = true;
  bool? showAddButton = false;
  bool? showTransferSuccessfulResult = false;
  bool? showTransferErrorResult = false;
  String? postSuccessfulConnectionLoadingText = "Verifying your account..";

  DapiConfigurations(
      {required this.environment,
      required this.countries,
      this.endpoints,
      this.extraBody,
      this.extraQueryParameters,
      this.extraHeaderFields,
      this.showLogos,
      this.showExperimentalBanks,
      this.showCloseButton,
      this.showAddButton,
      this.showTransferSuccessfulResult,
      this.showTransferErrorResult,
      this.postSuccessfulConnectionLoadingText});

  Map<String, dynamic> _toMap() {
    return {
      "endpoints": this.endpoints,
      "extraBody": this.extraBody,
      "extraQueryParameters": this.extraQueryParameters,
      "extraHeaderFields": this.extraHeaderFields,
      "environment": this.environment.toString().split('.').last.toLowerCase(),
      "countries": this.countries,
      "showLogos": this.showLogos,
      "showExperimentalBanks": this.showExperimentalBanks,
      "showCloseButton": this.showCloseButton,
      "showAddButton": this.showAddButton,
      "showTransferSuccessfulResult": this.showTransferSuccessfulResult,
      "showTransferErrorResult": this.showTransferErrorResult,
      "postSuccessfulConnectionLoadingText":
          this.postSuccessfulConnectionLoadingText
    };
  }

  static DapiConfigurations _fromMap(Map map) {
    String environment = map['environment'].toString().toLowerCase();
    List<Object?> countries = map['countries'];

    DapiEnvironment dapiEnvironment;
    List<String> dapiCountries = List.empty(growable: true);

    if (environment == "sandbox") {
      dapiEnvironment = DapiEnvironment.SANDBOX;
    } else {
      dapiEnvironment = DapiEnvironment.PRODUCTION;
    }

    countries.forEach((element) {
      dapiCountries.add(element.toString());
    });

    return DapiConfigurations(
        environment: dapiEnvironment,
        countries: dapiCountries,
        showLogos: map['showLogos'],
        showExperimentalBanks: map['showExperimentalBanks'],
        showCloseButton: map['showCloseButton'],
        showAddButton: map['showAddButton'],
        postSuccessfulConnectionLoadingText:
            map['postSuccessfulConnectionLoadingText']);
  }
}

enum DapiEnvironment { PRODUCTION, SANDBOX }

class DapiConnection {
  final String userID;
  final String clientUserID;
  final String bankID;
  final String? swiftCode;
  final String bankShortName;
  final String bankFullName;
  final String? country;
  final String fullLogo;
  final String halfLogo;
  final String miniLogo;
  final List<DapiAccount> accounts;
  final List<DapiCard> cards;

  DapiConnection(
      {required this.userID,
      required this.clientUserID,
      required this.bankID,
      required this.swiftCode,
      required this.bankShortName,
      required this.bankFullName,
      required this.country,
      required this.fullLogo,
      required this.halfLogo,
      required this.miniLogo,
      required this.accounts,
      required this.cards});

  static DapiConnection _fromMap(Map map) {
    List<dynamic> accountsMap = map['accounts'];
    List<DapiAccount> accounts = [];
    accountsMap.forEach((mapElement) {
      Map map = mapElement as Map;
      accounts.add(DapiAccount._fromMap(map));
    });

    List<dynamic> cardsMap = map['cards'];
    List<DapiCard> cards = [];
    cardsMap.forEach((mapElement) {
      Map map = mapElement as Map;
      cards.add(DapiCard._fromMap(map));
    });

    return DapiConnection(
        userID: map['userID'],
        clientUserID: map['clientUserID'],
        bankID: map['bankID'],
        swiftCode: map['swiftCode'],
        bankShortName: map['bankShortName'],
        bankFullName: map['bankFullName'],
        country: map['country'],
        fullLogo: map['fullLogo'],
        halfLogo: map['halfLogo'],
        miniLogo: map['miniLogo'],
        accounts: accounts,
        cards: cards);
  }

  static Future<DapiConnection> create(String jsonConnectionParams) async {
    return await Dapi._createConnection(jsonConnectionParams);
  }

  Future<String> getParameters() async {
    return await Dapi._getParameters(this.userID);
  }

  Future<DapiIdentityResponse> getIdentity() async {
    return await Dapi._getIdentity(this.userID);
  }

  Future<DapiAccountsResponse> getAccounts() async {
    return await Dapi._getAccounts(this.userID);
  }

  Future<DapiCardsResponse> getCards() async {
    return await Dapi._getCards(this.userID);
  }

  Future<DapiTransactionsResponse> getTransactionsForAccount(
      DapiAccount account, DateTime fromDate, DateTime toDate) async {
    return await Dapi._getTransactionsForAccount(
        this.userID, account.id!, fromDate, toDate);
  }

  Future<DapiTransactionsResponse> getTransactionsForCard(
      DapiCard card, DateTime fromDate, DateTime toDate) async {
    return await Dapi._getTransactionsForCard(
        this.userID, card.id!, fromDate, toDate);
  }

  Future<DapiAccountsMetadataResponse> getAccountsMetadata() async {
    return await Dapi._getAccountsMetadata(this.userID);
  }

  Future<DapiResult> delete() async {
    return await Dapi._delete(this.userID);
  }

  Future<DapiBeneficiariesResponse> getBeneficiaries() async {
    return await Dapi._getBeneficiaries(this.userID);
  }

  Future<DapiResult> createBeneficiary(DapiBeneficiary beneficiary) async {
    return await Dapi._createBeneficiary(this.userID, beneficiary);
  }

  Future<CreateTransferResponse> createTransfer(
    DapiAccount? account,
    DapiBeneficiary beneficiary,
    double? amount,
    String? remark,
  ) async {
    return await Dapi._createTransfer(
        this.userID, account?.id, beneficiary, amount, remark);
  }

  Future<CreateTransferResponse> createTransferToExistingBeneficiary(
    DapiAccount account,
    String beneficiaryID,
    double amount,
    String? remark,
  ) async {
    return await Dapi._createTransferToExistingBeneficiary(
        this.userID, account.id!, beneficiaryID, amount, remark);
  }

  Future<DapiWireBeneficiariesResponse> getWireBeneficiaries() async {
    return await Dapi._getWireBeneficiaries(this.userID);
  }

  Future<DapiResult> createWireBeneficiary(
      DapiWireBeneficiary beneficiary) async {
    return await Dapi._createWireBeneficiary(this.userID, beneficiary);
  }

  Future<CreateTransferResponse> createWireTransfer(
    DapiAccount? account,
    DapiWireBeneficiary beneficiary,
    double? amount,
    String? remark,
  ) async {
    return await Dapi._createWireTransfer(
        this.userID, account?.id, beneficiary, amount, remark);
  }

  Future<CreateTransferResponse> createWireTransferToExistingBeneficiary(
    DapiAccount account,
    String beneficiaryID,
    double amount,
    String? remark,
  ) async {
    return await Dapi._createWireTransferToExistingBeneficiary(
        this.userID, account.id!, beneficiaryID, amount, remark);
  }
}

class DapiIdentityResponse {
  final String? operationID;
  final DapiIdentity? identity;

  DapiIdentityResponse({this.operationID, this.identity});

  static DapiIdentityResponse _fromMap(Map map) {
    return DapiIdentityResponse(
        operationID: map['operationID'],
        identity: DapiIdentity._fromMap(map["identity"]));
  }
}

class DapiIdentity {
  final String? nationality;
  final String? dateOfBirth;
  final List<DapiNumber>? numbers;
  final String? emailAddress;
  final String? name;
  final DapiAddress? address;
  final List<DapiIdentification>? identifications;

  DapiIdentity(
      {this.nationality,
      this.dateOfBirth,
      this.numbers,
      this.emailAddress,
      this.name,
      this.address,
      this.identifications});

  static DapiIdentity _fromMap(Map map) {
    Map<String, dynamic> addressMap = Map<String, dynamic>.from(map['address']);
    List<dynamic>? numbersMap;
    List<dynamic>? identificationsMap;

    DapiAddress? address;
    List<DapiNumber>? numbers = [];
    List<DapiIdentification>? identifications = [];

    try {
      numbersMap = List<dynamic>.from(map['numbers']);
    } catch (e) {}

    try {
      identificationsMap = List<dynamic>.from(map['identifications']);
    } catch (e) {}

    if (addressMap.isNotEmpty) {
      address = DapiAddress._fromMap(addressMap);
    }

    if (numbersMap != null && numbersMap.isNotEmpty) {
      numbersMap.forEach((mapElement) {
        Map map = mapElement as Map;
        numbers.add(DapiNumber._fromMap(map));
      });
    }

    if (identificationsMap != null && identificationsMap.isNotEmpty) {
      identificationsMap.forEach((mapElement) {
        Map map = mapElement as Map;
        identifications.add(DapiIdentification._fromMap(map));
      });
    }

    return DapiIdentity(
        nationality: map['nationality'],
        dateOfBirth: map['dateOfBirth'],
        numbers: numbers,
        emailAddress: map['emailAddress'],
        name: map['name'],
        address: address,
        identifications: identifications);
  }
}

class DapiAccountsResponse {
  final String? operationID;
  final List<DapiAccount>? accounts;

  DapiAccountsResponse({this.operationID, this.accounts});

  static DapiAccountsResponse _fromMap(Map map) {
    List<dynamic> accountsMap = map['accounts'];
    List<DapiAccount> accounts = [];
    accountsMap.forEach((mapElement) {
      Map map = mapElement as Map;
      accounts.add(DapiAccount._fromMap(map));
    });
    return DapiAccountsResponse(
        operationID: map['operationID'], accounts: accounts);
  }
}

class DapiAccount {
  final String? iban;
  final String? number;
  final DapiNamePair? currency;
  final String? type;
  final String? name;
  final String? id;
  final num? balance;

  DapiAccount(
      {this.iban,
      this.number,
      this.currency,
      this.type,
      this.name,
      this.id,
      this.balance});

  static DapiAccount _fromMap(Map map) {
    Map<String, dynamic> currencyMap =
        Map<String, dynamic>.from(map['currency']);

    Map<String, dynamic> balanceMap = Map<String, dynamic>.from(map['balance']);
    return DapiAccount(
        iban: map['iban'],
        number: map['number'],
        currency: DapiNamePair._fromMap(currencyMap),
        type: map['type'],
        name: map['name'],
        id: map['id'],
        balance: balanceMap['amount']);
  }
}

class DapiCardsResponse {
  final String? operationID;
  final List<DapiCard>? cards;

  DapiCardsResponse({this.operationID, this.cards});

  static DapiCardsResponse _fromMap(Map map) {
    List<dynamic> cardsMap = map['cards'];
    List<DapiCard> cards = [];
    cardsMap.forEach((mapElement) {
      Map map = mapElement as Map;
      cards.add(DapiCard._fromMap(map));
    });
    return DapiCardsResponse(operationID: map['operationID'], cards: cards);
  }
}

class DapiCard {
  final String? cardNumber;
  final String? creditLimit;
  final DapiNamePair? currency;
  final String? type;
  final String? name;
  final String? id;
  final String? expiryDate;
  final String? status;
  final CreditBalance? balance;

  DapiCard(
      {this.cardNumber,
      this.creditLimit,
      this.currency,
      this.type,
      this.name,
      this.id,
      this.expiryDate,
      this.status,
      this.balance});

  static DapiCard _fromMap(Map map) {
    Map<String, dynamic> currencyMap =
        Map<String, dynamic>.from(map['currency']);

    Map<String, dynamic> balanceMap = Map<String, dynamic>.from(map['balance']);

    return DapiCard(
        cardNumber: map['cardNumber'],
        creditLimit: map['creditLimit'],
        currency: DapiNamePair._fromMap(currencyMap),
        type: map['type'],
        name: map['name'],
        id: map['id'],
        expiryDate: map['expiryDate'],
        status: map['status'],
        balance: CreditBalance._fromMap(balanceMap));
  }
}

class DapiTransactionsResponse {
  final String? operationID;
  final List<DapiTransaction>? transactions;

  DapiTransactionsResponse({this.operationID, this.transactions});

  static DapiTransactionsResponse _fromMap(Map map) {
    List<dynamic> transactionsMap = map['transactions'];
    List<DapiTransaction> transactions = [];
    transactionsMap.forEach((mapElement) {
      Map map = mapElement as Map;
      transactions.add(DapiTransaction._fromMap(map));
    });
    return DapiTransactionsResponse(
        operationID: map["operationID"], transactions: transactions);
  }
}

class DapiTransaction {
  final double? beforeAmount;
  final double? afterAmount;
  final double? amount;
  final DapiNamePair? currency;
  final DateTime? date;
  final String? description;
  final String? details;
  final String? type;

  DapiTransaction(
      {this.beforeAmount,
      this.afterAmount,
      this.amount,
      this.currency,
      this.date,
      this.description,
      this.details,
      this.type});

  static DapiTransaction _fromMap(Map map) {
    Map<String, dynamic> currencyMap =
        Map<String, dynamic>.from(map['currency']);
    DapiNamePair currency = DapiNamePair._fromMap(currencyMap);

    String stringDate = map['date'];
    DateTime date = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSZ").parse(stringDate);

    return DapiTransaction(
      beforeAmount: map['beforeAmount'].toDouble(),
      afterAmount: map['afterAmount'].toDouble(),
      amount: map['amount'].toDouble(),
      currency: currency,
      date: date,
      description: map['description'],
      details: map['details'],
      type: map['type'],
    );
  }
}

class DapiAccountsMetadataResponse {
  final String? operationID;
  final DapiAccountsMetadata? metadata;

  DapiAccountsMetadataResponse({this.operationID, this.metadata});

  static DapiAccountsMetadataResponse _fromMap(Map map) {
    return DapiAccountsMetadataResponse(
        operationID: map['operationID'],
        metadata: DapiAccountsMetadata._fromMap(map["accountsMetadata"]));
  }
}

class DapiAccountsMetadata {
  final String? swiftCode;
  final String? sortCode;
  final String? bankName;
  final String? branchName;
  final String? branchAddress;
  final DapiValuePair? beneficiaryCoolDownPeriod;
  final DapiValuePair? transactionRange;
  final DapiNamePair? country;
  final bool? isCreateBeneficiaryEndpointRequired;
  final bool? willNewlyAddedBeneficiaryExistBeforeCoolDownPeriod;

  DapiAccountsMetadata(
      {this.swiftCode,
      this.sortCode,
      this.bankName,
      this.branchName,
      this.branchAddress,
      this.beneficiaryCoolDownPeriod,
      this.transactionRange,
      this.country,
      this.isCreateBeneficiaryEndpointRequired,
      this.willNewlyAddedBeneficiaryExistBeforeCoolDownPeriod});

  static DapiAccountsMetadata _fromMap(Map map) {
    Map<String, dynamic> beneficiaryCoolDownPeriodMap =
        Map<String, dynamic>.from(map['beneficiaryCoolDownPeriod']);
    Map<String, dynamic> transactionRangeMap =
        Map<String, dynamic>.from(map['transactionRange']);
    Map<String, dynamic> countryMap = Map<String, dynamic>.from(map['country']);
    return DapiAccountsMetadata(
        swiftCode: map['swiftCode'],
        sortCode: map['sortCode'],
        bankName: map['bankName'],
        branchName: map['branchName'],
        branchAddress: map['branchAddress'],
        beneficiaryCoolDownPeriod:
            DapiValuePair._fromMap(beneficiaryCoolDownPeriodMap),
        transactionRange: DapiValuePair._fromMap(transactionRangeMap),
        country: DapiNamePair._fromMap(countryMap),
        isCreateBeneficiaryEndpointRequired:
            map['isCreateBeneficiaryEndpointRequired'],
        willNewlyAddedBeneficiaryExistBeforeCoolDownPeriod:
            map['willNewlyAddedBeneficiaryExistBeforeCoolDownPeriod']);
  }
}

class DapiWireBeneficiariesResponse {
  final String? operationID;
  final List<WireBeneficiary>? beneficiaries;

  DapiWireBeneficiariesResponse({this.operationID, this.beneficiaries});

  static DapiWireBeneficiariesResponse _fromMap(Map map) {
    List<dynamic> beneficiariesMap = map['beneficiaries'];
    List<WireBeneficiary> beneficiaries = [];
    beneficiariesMap.forEach((mapElement) {
      Map map = mapElement as Map;
      beneficiaries.add(WireBeneficiary._fromMap(map));
    });
    return DapiWireBeneficiariesResponse(
        operationID: map["operationID"], beneficiaries: beneficiaries);
  }
}

class WireBeneficiary {
  final String? name;
  final String? bankName;
  final String? accountNumber;
  final String? type;
  final String? status;
  final String? id;
  final String? routingNumber;
  final DapiAddress? address;

  WireBeneficiary(
      {this.name,
      this.bankName,
      this.accountNumber,
      this.type,
      this.status,
      this.id,
      this.routingNumber,
      this.address});

  static WireBeneficiary _fromMap(Map map) {
    Map<String, dynamic> addressMap = Map<String, dynamic>.from(map['address']);
    DapiAddress? address;
    if (addressMap.isNotEmpty) {
      address = DapiAddress._fromMap(addressMap);
    }
    return WireBeneficiary(
        name: map['name'],
        accountNumber: map['accountNumber'],
        bankName: map['bankName'],
        type: map['type'],
        status: map['status'],
        id: map['id'],
        routingNumber: map['routingNumber'],
        address: address);
  }
}

class DapiBeneficiariesResponse {
  final String? operationID;
  final List<Beneficiary>? beneficiaries;

  DapiBeneficiariesResponse({this.operationID, this.beneficiaries});

  static DapiBeneficiariesResponse _fromMap(Map map) {
    List<dynamic> beneficiariesMap = map['beneficiaries'];
    List<Beneficiary> beneficiaries = [];
    beneficiariesMap.forEach((mapElement) {
      Map map = mapElement as Map;
      beneficiaries.add(Beneficiary._fromMap(map));
    });
    return DapiBeneficiariesResponse(
        operationID: map["operationID"], beneficiaries: beneficiaries);
  }
}

class Beneficiary {
  final String? name;
  final String? accountNumber;
  final String? iban;
  final String? type;
  final String? status;
  final String? id;

  Beneficiary(
      {this.name,
      this.accountNumber,
      this.iban,
      this.type,
      this.status,
      this.id});

  static Beneficiary _fromMap(Map map) {
    return Beneficiary(
      name: map['name'],
      accountNumber: map['accountNumber'],
      iban: map['iban'],
      type: map['type'],
      status: map['status'],
      id: map['id'],
    );
  }
}

class DapiNamePair {
  final String? code;
  final String? name;

  DapiNamePair({this.code, this.name});

  static DapiNamePair _fromMap(Map<String, dynamic> map) {
    return DapiNamePair(code: map['code'], name: map['name']);
  }
}

class DapiValuePair {
  final String? unit;
  final num? value;

  DapiValuePair({this.unit, this.value});

  static DapiValuePair _fromMap(Map<String, dynamic> map) {
    return DapiValuePair(unit: map['unit'], value: map['value']);
  }
}

class CreditBalance {
  final String? amountDue;
  final String? availableBalance;
  final String? dueDate;
  final String? outstandingBalance;

  CreditBalance(
      {this.amountDue,
      this.availableBalance,
      this.dueDate,
      this.outstandingBalance});

  static CreditBalance _fromMap(Map<String, dynamic> map) {
    return CreditBalance(
        amountDue: map['amountDue'],
        availableBalance: map['availableBalance'],
        dueDate: map['dueDate'],
        outstandingBalance: map['outstandingBalance']);
  }
}

class DapiNumber {
  final String? type;
  final String? value;

  DapiNumber({this.type, this.value});

  static DapiNumber _fromMap(Map map) {
    return DapiNumber(type: map['type'], value: map['value']);
  }
}

class DapiIdentification {
  final String? type;
  final String? value;

  DapiIdentification({this.type, this.value});

  static DapiIdentification _fromMap(Map map) {
    return DapiIdentification(type: map['type'], value: map['value']);
  }
}

class DapiAddress {
  final String? flat;
  final String? building;
  final String? area;
  final String? poBox;
  final String? city;
  final String? state;
  final String? country;
  final String? full;

  DapiAddress(
      {this.flat,
      this.building,
      this.area,
      this.poBox,
      this.city,
      this.state,
      this.country,
      this.full});

  static DapiAddress _fromMap(Map<String, dynamic> map) {
    return DapiAddress(
      flat: map['flat'],
      building: map['building'],
      area: map['area'],
      poBox: map['poBox'],
      city: map['city'],
      state: map['state'],
      country: map['country'],
      full: map['full'],
    );
  }
}

class DapiBeneficiary {
  final DapiLineAddress? address;
  final String? accountNumber;
  final String? name;
  final String? bankName;
  final String? swiftCode;
  final String? iban;
  final String? phoneNumber;
  final String? country;
  final String? branchAddress;
  final String? branchName;

  DapiBeneficiary(
      {this.address,
      this.accountNumber,
      this.name,
      this.bankName,
      this.swiftCode,
      this.iban,
      this.phoneNumber,
      this.country,
      this.branchAddress,
      this.branchName});

  Map<String, dynamic> _toMap() {
    return {
      "address": address?._toMap(),
      "accountNumber": accountNumber,
      "name": name,
      "bankName": bankName,
      "swiftCode": swiftCode,
      "iban": iban,
      "phoneNumber": phoneNumber,
      "country": country,
      "branchAddress": branchAddress,
      "branchName": branchName,
    };
  }
}

class DapiWireBeneficiary {
  final DapiLineAddress? address;
  final String? name;
  final String? firstName;
  final String? lastName;
  final String? nickname;
  final String? city;
  final String? state;
  final String? country;
  final String? zipCode;
  final String? receiverType;
  final String? receiverAccountType;
  final String? routingNumber;
  final String? accountNumber;

  DapiWireBeneficiary({
    this.address,
    this.name,
    this.firstName,
    this.lastName,
    this.nickname,
    this.city,
    this.state,
    this.country,
    this.zipCode,
    this.receiverType,
    this.receiverAccountType,
    this.routingNumber,
    this.accountNumber,
  });

  Map<String, dynamic> _toMap() {
    return {
      "address": address?._toMap(),
      "name": name,
      "firstName": firstName,
      "lastName": lastName,
      "nickname": nickname,
      "city": city,
      "state": state,
      "country": country,
      "zipCode": zipCode,
      "receiverType": receiverType,
      "receiverAccountType": receiverAccountType,
      "routingNumber": routingNumber,
      "accountNumber": accountNumber
    };
  }
}

class DapiLineAddress {
  final String? line1;
  final String? line2;
  final String? line3;

  DapiLineAddress({this.line1, this.line2, this.line3});

  Map<String, dynamic> _toMap() {
    return {
      "line1": line1,
      "line2": line2,
      "line3": line3,
    };
  }

  static DapiLineAddress _fromMap(Map<String, dynamic> map) {
    return DapiLineAddress(
        line1: map['line1'], line2: map['line2'], line3: map['line3']);
  }
}

class CreateTransferResponse {
  final String? operationID;
  final String? accountID;
  final num? amount;

  CreateTransferResponse({
    this.operationID,
    this.accountID,
    this.amount,
  });

  static CreateTransferResponse _fromMap(Map map) {
    return CreateTransferResponse(
      operationID: map['operationID'],
      accountID: map['account'],
      amount: map['amount'],
    );
  }
}

class DapiResult {
  final String? operationID;

  DapiResult({this.operationID});

  static DapiResult _fromMap(Map map) {
    return DapiResult(operationID: map['operationID']);
  }
}

class ConnectSuccessEvent {
  final String? bankID;
  final String? userID;

  ConnectSuccessEvent({this.bankID, this.userID});

  static ConnectSuccessEvent _fromMap(Map map) {
    return ConnectSuccessEvent(bankID: map['bankID'], userID: map['userID']);
  }
}

class BankRequestEvent {
  final String? bankName;
  final String? iban;

  BankRequestEvent({this.bankName, this.iban});

  static BankRequestEvent _fromMap(Map map) {
    return BankRequestEvent(bankName: map['bankID'], iban: map['userID']);
  }
}

class ConnectFailureEvent {
  final String? bankID;
  final String? error;

  ConnectFailureEvent({this.bankID, this.error});

  static ConnectFailureEvent _fromMap(Map map) {
    return ConnectFailureEvent(bankID: map['bankID'], error: map['error']);
  }
}

class TransferUiWillSendEvent {
  final num? amount;
  final String? accountID;

  TransferUiWillSendEvent({this.amount, this.accountID});

  static TransferUiWillSendEvent _fromMap(Map map) {
    return TransferUiWillSendEvent(
        amount: map['amount'], accountID: map['account']);
  }
}

class DapiSdkException implements Exception {
  final String? code;
  final String? message;

  DapiSdkException(this.code, this.message);

  @override
  String toString() => 'PlatformException($code, $message)';
}
