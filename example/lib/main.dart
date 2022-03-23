import 'package:flutter/material.dart';
import 'dart:async';
import 'package:dapi/dapi.dart';

DapiConnection? connection;
String jsonConnectionParams = "{\n" +
    "   \"accessCode\":\"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcHBLZXkiOiIxZDQ1OTJjNGE4ZGQ2ZmY3NTI2MWU1N2ViM2Y4MGM1MThkNzg1N2Q2NjE3NzY5YWYzZjhmMDRiMDU5MGJhY2ViIiwiZXhwIjoxNjQ2MzQ1NzE1LCJpYXQiOjE2NDYzNDU0MTUsImp0aSI6IjJmYTk0NjNlLWI5YzktNGU2My1hMTE2LWRiODFkNWI2M2I2MSIsIm90cCI6InY0dWEzbFlUc1oyUUl3T1l3TEcwL3ZOdkdjUk5udk42MDVGTzJaVEt0NTA9IiwidXVpZCI6IkRBUElCQU5LX0FFX0xJVjozNjA4ZjBjZC0zYTQ2LTRiODAtYTg5Mi1hZTA1N2ViNzAyYWUifQ.LlWOUzAWo8g8iW_KJ51OF00YdattV2ZUptB2SZYfjHE\",\n" +
    "   \"bankId\":\"DAPIBANK_AE_LIV\",\n" +
    "   \"cards\":[\n" +
    "      \n" +
    "   ],\n" +
    "   \"clientUserID\":\"client\",\n" +
    "   \"color\":{\n" +
    "      \"primaryColor\":\"#D51750\",\n" +
    "      \"secondaryColor\":\"#2A2B38\"\n" +
    "   },\n" +
    "   \"connectionID\":\"e0ea19ea-23d7-40b1-8d4c-e11e88823f1b\",\n" +
    "   \"fullLogoPng\":\"https:\\/\\/cdn-dapi.azureedge.net\\/banks-full-logo\\/LIV.png\",\n" +
    "   \"fullName\":\"Liv Sandbox\",\n" +
    "   \"halfLogoPng\":\"https:\\/\\/cdn-dapi.azureedge.net\\/banks-horizontal-logo\\/LIV.png\",\n" +
    "   \"miniLogoPng\":\"https:\\/\\/cdn-dapi.azureedge.net\\/banks-mini-logo\\/LIV.png\",\n" +
    "   \"name\":\"Liv\",\n" +
    "   \"tokenID\":\"2fa9463e-b9c9-4e63-a116-db81d5b63b61\",\n" +
    "   \"userID\":\"U6Kx3\\/if3Ko7FDg9ypVoZmzzEWFMzrsVjVA\\/PNYoyiPF8HGl0CvaSpgnsnVep49H8D2pDEROAc3L24P+s6ZfrQ==\",\n" +
    "   \"userSecret\":\"p1Kvf5bjeuqAHUf9Ftl\\/GyiU08XsHLbYCOu8nrW3\\/fvMNcIYhZTZemd3+zijuC\\/ZThR0zYmcxjFJt2Gn5i\\/xgisoW4qVWbHCh\\/cTpppWOShocatCOFfP43fdO6GHiDp1QhJJBHMh8D9x2e399CrrmcF+WZMzX9qVrdCyrzkFiHNKIziNG3wWLNHbTF1igF7LCPQSbb1LWkF0vXlh0Uo\\/e3dpAhzpgApNc53DGG\\/NxUJ7sNZ2o8jqKx6Qxfm91jFjYfufZYV4rC7NLhiRf4v+RwAVGuhelGKS\\/jiGh\\/P0SFUivlNXWKfeQc3strooS1FHxbYG0OGzEVjQngd2UUSTK8AhS2Kum5Y+58gr\\/V5gh2kncNDV2GPbcqg2gDeKgCElBYb0zN7qSI9apahSVhf2AVD\\/khVLo\\/wilZebQBdWBpvsaQHpi5ysNd9nvL\\/o\\/Xl+hRsQKxwq0YR\\/sbjazSyy6Qu+NrnZCmJnDq2EGHrbPFFlPAx6XtjCUBD9RBpOZUJlkm7Fk+fGWgX5pyAnJncuaJED2GEdQRTE3IPzF1j4YKa7NvxkBrCHm29OmvpYtbf1rlTDC62o8wMw29KNWLBsb2GzOQfGAXLAxgjuYMdL7XMzqRDZ+VgvIBCZWWc2\\/XDdkDiIChtGkskYX955CTz9\\/jdtr6mPcMaANf3IJ8nHYZ8=\"\n" +
    "}";

void main() {
  runApp(MyApp());
}

class Button extends StatelessWidget {
  final void Function() onPressed;
  final String text;
  final bool visible;

  const Button(
      {required this.onPressed, required this.text, this.visible = true});

  @override
  Widget build(BuildContext context) {
    Widget button = ElevatedButton(onPressed: onPressed, child: Text(text));
    return Visibility(child: button, visible: visible);
  }
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Dapi Connect'),
        ),
        body: ListView(
          padding: EdgeInsets.all(20),
          children: [
            Button(onPressed: () => startDapi(), text: "Start"),
            Button(
                onPressed: () => setConfigurations(new DapiConfigurations(
                    environment: DapiEnvironment.SANDBOX,
                    countries: List.from({"US"}),
                    showAddButton: true,
                    postSuccessfulConnectionLoadingText: "TestTest")),
                text: "Set Configurations"),
            Button(
                onPressed: () => configurations(), text: "Get Configurations"),
            Button(onPressed: () => isStarted(), text: "Is Started"),
            Button(
                onPressed: () => setClientUserID("newID"),
                text: "Set Client User ID"),
            Button(onPressed: () => clientUserID(), text: "Get Client User ID"),
            Button(onPressed: () => presentConnect(), text: "Present Connect"),
            Button(onPressed: () => getConnections(), text: "Get Connections"),
            Button(
                onPressed: () => createConnection(jsonConnectionParams),
                text: "Create Connection"),
            Button(
                onPressed: () => getParameters(connection!),
                text: "Get Parameters"),
            Button(
                onPressed: () => getIdentity(connection!),
                text: "Get Identity"),
            Button(
                onPressed: () => getAccounts(connection!),
                text: "Get Accounts"),
            Button(onPressed: () => getCards(connection!), text: "Get Cards"),
            Button(
                onPressed: () => getTransactionsForAccount(connection!,
                    DateTime.parse("2021-11-01"), DateTime.parse("2021-12-10")),
                text: "Get Transactions For Account"),
            Button(
                onPressed: () => getTransactionsForCard(connection!,
                    DateTime.parse("2021-05-01"), DateTime.parse("2021-09-10")),
                text: "Get Transactions For Card"),
            Button(
                onPressed: () => getAccountsMetadata(connection!),
                text: "Get Accounts Metadata"),
            Button(
                onPressed: () => getBeneficiaries(connection!),
                text: "Get Beneficiaries"),
            Button(
                onPressed: () => createBeneficiary(connection!),
                text: "Create Beneficiary"),
            Button(
                onPressed: () => createTransfer(connection!),
                text: "Create Transfer"),
            Button(
                onPressed: () =>
                    createTransferToExistingBeneficiary(connection!),
                text: "Create Transfer To Existing Beneficiary"),
            Button(
                onPressed: () => getWireBeneficiaries(connection!),
                text: "Get Wire Beneficiaries"),
            Button(
                onPressed: () => createWireBeneficiary(connection!),
                text: "Create Wire Beneficiary"),
            Button(
                onPressed: () => createWireTransfer(connection!),
                text: "Create Wire Transfer"),
            Button(
                onPressed: () =>
                    createWireTransferToExistingBeneficiary(connection!),
                text: "Create Wire Transfer To Existing Beneficiary"),
            Button(onPressed: () => delete(connection!), text: "Delete"),
          ],
        ),
      ),
    );
  }
}

Future<String?> startDapi() async {
  try {
    return await Dapi.start(
        "APP_KEY",
        "1234ID",
        configurations: new DapiConfigurations(
            environment: DapiEnvironment.SANDBOX,
            countries: List.from({"US", "AE"}),
            showTransferErrorResult: true,
            showTransferSuccessfulResult: true,
            postSuccessfulConnectionLoadingText: "Test.."));
  } on DapiSdkException catch (e) {
    print('Error logged in Example Flutter app $e.');
  }
}

Future<bool?> isStarted() async {
  try {
    bool isStarted = await Dapi.isStarted();
    print(isStarted);
    return isStarted;
  } on DapiSdkException catch (e) {
    print('Error logged in Example Flutter app $e.');
  }
}

void presentConnect() async {
  Dapi.onConnectionSuccessful.listen((m) => print("CONNECTION_SUCCESSFUl"));

  Dapi.onConnectionFailure.listen((m) => print("CONNECTION_FAILED"));

  Dapi.onBankRequest.listen((m) => print("BANK_REQUEST"));

  Dapi.onConnectDismissed.listen((m) => print("CONNECT_DISMISSED"));

  Dapi.presentConnect();
}

void dismissConnect() {
  Dapi.dismissConnect();
}

void setConfigurations(DapiConfigurations configurations) {
  Dapi.setConfigurations(configurations);
}

Future<DapiConfigurations> configurations() async {
  DapiConfigurations config = await Dapi.configurations();
  print(config);
  return config;
}

void setClientUserID(String clientUserID) {
  Dapi.setClientUserID(clientUserID);
}

Future<String?> clientUserID() async {
  String? id = await Dapi.clientUserID();
  print(id);
  return id;
}

Future<List<DapiConnection>?> getConnections() async {
  try {
    List<DapiConnection> connections = await Dapi.getConnections();
    if (connections.isNotEmpty) {
      connection = connections.first;
    }
    print(connections.toString());
    return connections;
  } on DapiSdkException catch (e) {
    print('Error logged in Example Flutter app $e.');
  }
}

Future<DapiIdentityResponse?> getIdentity(DapiConnection connection) async {
  try {
    DapiIdentityResponse identityResponse = await connection.getIdentity();
    print(identityResponse.identity!.emailAddress);
    return identityResponse;
  } on DapiSdkException catch (e) {
    print('Error logged in Example Flutter app $e.');
  }
}

Future<DapiAccountsResponse?> getAccounts(DapiConnection connection) async {
  try {
    DapiAccountsResponse accountsResponse = await connection.getAccounts();
    print(accountsResponse.accounts![1].id);
    return accountsResponse;
  } on DapiSdkException catch (e) {
    print('Error logged in Example Flutter app $e.');
  }
}

Future<DapiCardsResponse?> getCards(DapiConnection connection) async {
  try {
    DapiCardsResponse cardsResponse = await connection.getCards();
    print(cardsResponse.cards!.first.id);
    return cardsResponse;
  } on DapiSdkException catch (e) {
    print('Error logged in Example Flutter app $e.');
  }
}

Future<DapiTransactionsResponse?> getTransactionsForAccount(
    DapiConnection connection, DateTime fromDate, DateTime toDate) async {
  try {
    DapiTransactionsResponse transactionsResponse = await connection
        .getTransactionsForAccount(connection.accounts.first, fromDate, toDate);
    print(transactionsResponse.transactions!.first.amount);
    return transactionsResponse;
  } on DapiSdkException catch (e) {
    print('Error logged in Example Flutter app $e.');
  }
}

Future<DapiTransactionsResponse?> getTransactionsForCard(
    DapiConnection connection, DateTime fromDate, DateTime toDate) async {
  try {
    DapiTransactionsResponse transactionsResponse = await connection
        .getTransactionsForCard(connection.cards.first, fromDate, toDate);
    print(transactionsResponse.transactions!.first.amount);
    return transactionsResponse;
  } on DapiSdkException catch (e) {
    print('Error logged in Example Flutter app $e.');
  }
}

Future<DapiAccountsMetadataResponse?> getAccountsMetadata(
    DapiConnection connection) async {
  try {
    DapiAccountsMetadataResponse accountsMetadataResponse =
        await connection.getAccountsMetadata();
    print(accountsMetadataResponse.metadata?.swiftCode);
    return accountsMetadataResponse;
  } on DapiSdkException catch (e) {
    print('Error logged in Example Flutter app $e.');
  }
}

Future<DapiResult?> delete(DapiConnection connection) async {
  try {
    DapiResult result = await connection.delete();
    print(result);
    return result;
  } on DapiSdkException catch (e) {
    print('Error logged in Example Flutter app $e.');
  }
}

Future<DapiBeneficiariesResponse?> getBeneficiaries(
    DapiConnection connection) async {
  try {
    DapiBeneficiariesResponse beneficiariesResponse =
        await connection.getBeneficiaries();
    print(beneficiariesResponse.beneficiaries!.first.id);
    return beneficiariesResponse;
  } on DapiSdkException catch (e) {
    print('Error logged in Example Flutter app $e.');
  }
}

Future<DapiResult?> createBeneficiary(DapiConnection connection) async {
  try {
    DapiResult result =
        await connection.createBeneficiary(getSandboxBeneficiary());
    print(result.operationID);
    return result;
  } on DapiSdkException catch (e) {
    print('Error logged in Example Flutter app $e.');
  }
}

Future<CreateTransferResponse?> createTransfer(
    DapiConnection connection) async {
  try {
    Dapi.onTransferUiDismissed.listen((m) => print("TRANSFER_UI_DISMISSED"));
    Dapi.onTransferUiWillSend.listen((m) => print("TRANSFER_UI_WILL_SEND"));
    CreateTransferResponse result =
        await connection.createTransfer(null, getSandboxBeneficiary(), 0, null);
    print(result.accountID);
    return result;
  } on DapiSdkException catch (e) {
    print('Error logged in Example Flutter app $e.');
  }
}

Future<CreateTransferResponse?> createTransferToExistingBeneficiary(
    DapiConnection connection) async {
  try {
    DapiBeneficiariesResponse? beneficiariesResponse =
        await getBeneficiaries(connection);
    CreateTransferResponse result =
        await connection.createTransferToExistingBeneficiary(
            connection.accounts.first,
            beneficiariesResponse!.beneficiaries!.first.id!,
            2.0,
            null);
    print(result.accountID);
    return result;
  } on DapiSdkException catch (e) {
    print('Error logged in Example Flutter app $e.');
  }
}

Future<DapiWireBeneficiariesResponse?> getWireBeneficiaries(
    DapiConnection connection) async {
  try {
    DapiWireBeneficiariesResponse beneficiariesResponse =
        await connection.getWireBeneficiaries();
    print(beneficiariesResponse.beneficiaries!.first.routingNumber);
    return beneficiariesResponse;
  } on DapiSdkException catch (e) {
    print('Error logged in Example Flutter app $e.');
  }
}

Future<DapiResult?> createWireBeneficiary(DapiConnection connection) async {
  try {
    DapiResult result =
        await connection.createWireBeneficiary(getSandboxWireBeneficiary());
    print(result.operationID);
    return result;
  } on DapiSdkException catch (e) {
    print('Error logged in Example Flutter app $e.');
  }
}

Future<CreateTransferResponse?> createWireTransfer(
    DapiConnection connection) async {
  try {
    Dapi.onTransferUiDismissed.listen((m) => print("TRANSFER_UI_DISMISSED"));
    Dapi.onTransferUiWillSend.listen((m) => print("TRANSFER_UI_WILL_SEND"));
    CreateTransferResponse result = await connection.createWireTransfer(
        null, getSandboxWireBeneficiary(), 0, "remark");
    print(result.accountID);
    return result;
  } on DapiSdkException catch (e) {
    print('Error logged in Example Flutter app $e.');
  }
}

Future<CreateTransferResponse?> createWireTransferToExistingBeneficiary(
    DapiConnection connection) async {
  try {
    DapiWireBeneficiariesResponse? beneficiariesResponse =
        await getWireBeneficiaries(connection);
    CreateTransferResponse result =
        await connection.createWireTransferToExistingBeneficiary(
            connection.accounts.first,
            beneficiariesResponse!.beneficiaries!.first.id!,
            99.0,
            "remark");
    print(result.accountID);
    return result;
  } on DapiSdkException catch (e) {
    print('Error logged in Example Flutter app $e.');
  }
}

DapiBeneficiary getSandboxBeneficiary() {
  DapiLineAddress lineAddress = DapiLineAddress(
      line1: "baniyas road", line2: "dubai", line3: "united arab emirates");

  return DapiBeneficiary(
      address: lineAddress,
      accountNumber: "1623404370879825504324",
      name: "name",
      bankName: "bankName",
      swiftCode: "DAPIBANK",
      iban: "DAPIBANKAEENBD1623404370879825504324",
      country: "AE",
      branchAddress: "branchAddress",
      branchName: "branchName",
      phoneNumber: "xxxxxxxxxxx");
}

DapiWireBeneficiary getSandboxWireBeneficiary() {
  DapiLineAddress lineAddress = DapiLineAddress(
      line1: "2400 bruce street UCA stadium park bld 6", line2: "", line3: "");

  DapiWireBeneficiary beneficiary = new DapiWireBeneficiary(
      address: lineAddress,
      accountNumber: "1234567654321",
      name: "TestAccount",
      country: "US",
      receiverType: "retail",
      routingNumber: "953349354",
      nickname: "OmarChase",
      receiverAccountType: "checking",
      firstName: "Omar",
      lastName: "Agoor",
      zipCode: "72305",
      state: "Arkansas",
      city: "Conway");

  return beneficiary;
}

Future<DapiConnection?> createConnection(String jsonConnectionParams) async {
  try {
    DapiConnection connection =
        await DapiConnection.create(jsonConnectionParams);
    print(connection.bankID);
    return connection;
  } on DapiSdkException catch (e) {
    print('Error logged in Example Flutter app $e.');
  }
}

Future<String?> getParameters(DapiConnection connection) async {
  try {
    String params = await connection.getParameters();
    print(params);
    jsonConnectionParams = params;
    return params;
  } on DapiSdkException catch (e) {
    print('Error logged in Example Flutter app $e.');
  }
}
