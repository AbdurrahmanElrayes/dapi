package co.dapi.dapi;

import android.app.Activity;
import android.app.Application;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;

import org.jetbrains.annotations.NotNull;

import java.lang.reflect.Type;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

import co.dapi.connect.core.base.Dapi;
import co.dapi.connect.core.callbacks.OnDapiConnectListener;
import co.dapi.connect.core.callbacks.OnDapiTransferListener;
import co.dapi.connect.data.endpoint_models.DapiAccountsResponse;
import co.dapi.connect.data.endpoint_models.DapiCardsResponse;
import co.dapi.connect.data.models.DapiBeneficiary;
import co.dapi.connect.data.models.DapiConfigurations;
import co.dapi.connect.data.models.DapiConnection;
import co.dapi.connect.data.models.DapiEndpoints;
import co.dapi.connect.data.models.DapiEnvironment;
import co.dapi.connect.data.models.DapiError;
import co.dapi.connect.data.models.DapiWireBeneficiary;
import co.dapi.connect.data.models.LinesAddress;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import kotlin.Unit;
import kotlin.jvm.functions.Function1;

/**
 * DapiPlugin
 */
public class DapiPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware {
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private MethodChannel channel;
    private Application application;
    private Activity activity;
    private EventChannel.EventSink connectionSuccessfulEvents;
    private EventChannel.EventSink connectionFailureEvents;
    private EventChannel.EventSink bankRequestEvents;
    private EventChannel.EventSink connectDismissedEvents;
    private EventChannel.EventSink transferUiDismissedEvents;
    private EventChannel.EventSink transferUiWillSendEvents;
    private final OnDapiConnectListener connectListener = new OnDapiConnectListener() {
        @Override
        public void onDismissed() {
            if (connectDismissedEvents != null) {
                connectDismissedEvents.success(null);
            }
        }

        @Override
        public void onConnectionSuccessful(@NonNull DapiConnection connection) {
            if (activity != null && connectionSuccessfulEvents != null) {
                activity.runOnUiThread(() -> {
                    HashMap<String, Object> data = new HashMap<>();
                    data.put("bankID", connection.getBankId());
                    data.put("userID", connection.getUserID());
                    connectionSuccessfulEvents.success(data);
                });
            }
        }

        @Override
        public void onConnectionFailure(@NonNull DapiError error, @Nullable String bankID) {
            if (connectionFailureEvents != null) {
                HashMap<String, Object> data = new HashMap<>();
                data.put("bankID", bankID);
                data.put("error", error.getMessage());
                connectionFailureEvents.success(data);
            }
        }

        @Override
        public void onBankRequest(@NonNull String bankName, @NonNull String iban) {
            if (bankRequestEvents != null) {
                HashMap<String, Object> data = new HashMap<>();
                data.put("bankName", bankName);
                data.put("iban", iban);
                bankRequestEvents.success(data);
            }
        }

    };

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "dapi");
        channel.setMethodCallHandler(this);

        EventChannel successfulConnectionChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), "co.dapi.connect/connect_success_channel");
        EventChannel failureConnectionChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), "co.dapi.connect/connect_failure_channel");
        EventChannel bankRequestChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), "co.dapi.connect/bank_request_channel");
        EventChannel connectDismissedChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), "co.dapi.connect/connect_dismissed_channel");
        EventChannel transferUiDismissedChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), "co.dapi.connect/transfer_ui_dismissed_channel");
        EventChannel transferUiWillSendChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), "co.dapi.connect/transfer_ui_will_send_channel");

        final SuccessfulConnectionStreamHandler successfulConnectionStreamHandler = new SuccessfulConnectionStreamHandler();
        final FailureConnectionStreamHandler failureConnectionStreamHandler = new FailureConnectionStreamHandler();
        final BankRequestStreamHandler bankRequestStreamHandler = new BankRequestStreamHandler();
        final ConnectDismissedStreamHandler connectDismissedStreamHandler = new ConnectDismissedStreamHandler();
        final TransferUiDismissedStreamHandler transferUiDismissedStreamHandler = new TransferUiDismissedStreamHandler();
        final TransferUiWillSendStreamHandler transferUiWillSendStreamHandler = new TransferUiWillSendStreamHandler();

        successfulConnectionChannel.setStreamHandler(successfulConnectionStreamHandler);
        failureConnectionChannel.setStreamHandler(failureConnectionStreamHandler);
        bankRequestChannel.setStreamHandler(bankRequestStreamHandler);
        connectDismissedChannel.setStreamHandler(connectDismissedStreamHandler);
        transferUiDismissedChannel.setStreamHandler(transferUiDismissedStreamHandler);
        transferUiWillSendChannel.setStreamHandler(transferUiWillSendStreamHandler);
    }

    @Override
    public void onAttachedToActivity(@NonNull @NotNull ActivityPluginBinding binding) {
        activity = binding.getActivity();
        application = activity.getApplication();
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        application = null;
        activity = null;
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull @NotNull ActivityPluginBinding binding) {
        activity = binding.getActivity();
        application = activity.getApplication();
    }

    @Override
    public void onDetachedFromActivity() {
        application = null;
        activity = null;
    }

    @SuppressWarnings("unchecked")
    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        List<Object> args = (List<Object>) call.arguments;
        switch (call.method) {
            case "startWithAppKey:clientUserID:configurations:":
                Map<String, Object> configurations = null;
                if (args.size() > 2 && args.get(2) != null) {
                    configurations = (Map<String, Object>) args.get(2);
                }
                start((String) args.get(0), (String) args.get(1), configurations, result);
                break;
            case "isStarted":
                isStarted(result);
                break;
            case "setConfigurations:":
                setConfigurations((Map<String, Object>) args.get(0));
                break;
            case "configurations":
                configurations(result);
                break;
            case "presentConnect":
                presentConnect();
                break;
            case "dismissConnect":
                dismissConnect();
                break;
            case "setClientUserID:":
                setClientUserID((String) args.get(0));
                break;
            case "clientUserID":
                clientUserID(result);
                break;
            case "getConnections":
                getConnections(result);
                break;
            case "createConnection:":
                createConnection((String) args.get(0), result);
                break;
            case "getParameters:":
                getParameters((String) args.get(0),result);
                break;
            case "getIdentity:":
                getIdentity((String) args.get(0), result);
                break;
            case "getAccounts:":
                getAccounts((String) args.get(0), result);
                break;
            case "getCards:":
                getCards((String) args.get(0), result);
                break;
            case "getTransactionsForAccount:accountID:startDate:endDate:":
                getTransactionsForAccount((String) args.get(0), (String) args.get(1), (Long) args.get(2), (Long) args.get(3), result);
                break;
            case "getTransactionsForCard:cardID:startDate:endDate:":
                getTransactionsForCard((String) args.get(0), (String) args.get(1), (Long) args.get(2), (Long) args.get(3), result);
                break;
            case "getAccountsMetadata:":
                getAccountsMetaData((String) args.get(0), result);
                break;
            case "delete:":
                delete((String) args.get(0), result);
                break;
            case "getBeneficiaries:":
                getBeneficiaries((String) args.get(0), result);
                break;
            case "createBeneficiary:beneficiary:":
                createBeneficiary((String) args.get(0), (HashMap<String, Object>) args.get(1), result);
                break;
            case "createTransfer:accountID:beneficiary:amount:remark:":
                String accountID = null;
                HashMap<String, Object> beneficiary = null;
                double amount = 0.0;
                String remark = null;
                if (args.size() > 1 && args.get(1) != null) {
                    accountID = (String) args.get(1);
                }
                if (args.size() > 2 && args.get(2) != null) {
                    beneficiary = (HashMap<String, Object>) args.get(2);
                }
                if (args.size() > 3 && args.get(3) != null) {
                    amount = (double) args.get(3);
                }
                if (args.size() > 4 && args.get(4) != null) {
                    remark = (String) args.get(4);
                }
                createTransfer((String) args.get(0), accountID, beneficiary, amount, remark, result);
                break;
            case "createTransferToExistingBeneficiary:accountID:receiverID:amount:remark:":
                createTransferToExistingBeneficiary((String) args.get(0), (String) args.get(1), (String) args.get(2), (double) args.get(3), (String) args.get(4), result);
                break;
            case "getWireBeneficiaries:":
                getWireBeneficiaries((String) args.get(0), result);
                break;
            case "createWireBeneficiary:beneficiary:":
                createWireBeneficiary((String) args.get(0), (HashMap<String, Object>) args.get(1), result);
                break;
            case "createWireTransfer:accountID:beneficiary:amount:remark:":
                String wireAccountId = null;
                HashMap<String, Object> wireBeneficiary = null;
                double wireAmount = 0.0;
                String wireRemark = null;
                if (args.size() > 1 && args.get(1) != null) {
                    wireAccountId = (String) args.get(1);
                }
                if (args.size() > 2 && args.get(2) != null) {
                    wireBeneficiary = (HashMap<String, Object>) args.get(2);
                }
                if (args.size() > 3 && args.get(3) != null) {
                    wireAmount = (double) args.get(3);
                }
                if (args.size() > 4 && args.get(4) != null) {
                    wireRemark = (String) args.get(4);
                }
                createWireTransfer((String) args.get(0), wireAccountId, wireBeneficiary, wireAmount, wireRemark, result);
                break;
            case "createWireTransferToExistingBeneficiary:accountID:receiverID:amount:remark:":
                createWireTransferToExistingBeneficiary((String) args.get(0), (String) args.get(1), (String) args.get(2), (double) args.get(3), (String) args.get(4), result);
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
    }

    private void start(String appKey, String clientUserID, Map<String, Object> configurationsMap, Result result) {
        DapiConfigurations configurations = getConfigurationsFromMap(configurationsMap);
        Dapi.start(application, appKey, clientUserID, configurations, () -> Unit.INSTANCE, (error) -> {
            result.error("-100", error.getMessage(), getMap(error));
            return Unit.INSTANCE;
        });
    }

    public void setConfigurations(Map<String, Object> configurationsMap) {
        Dapi.setConfigurations(getConfigurationsFromMap(configurationsMap));
    }

    public void configurations(Result result) {
        result.success(getMap(Dapi.getConfigurations()));
    }

    private void presentConnect() {
        Dapi.presentConnect();
    }

    private void isStarted(Result result) {
        result.success(Dapi.isStarted());
    }

    private void dismissConnect() {
        Dapi.dismissConnect();
    }

    public void setClientUserID(String clientUserID) {
        Dapi.setClientUserID(clientUserID);
    }

    public void clientUserID(Result result) {
        result.success(Dapi.getClientUserID());
    }

    private void getConnections(Result result) {
        Dapi.getConnections(connections -> {
            ArrayList<HashMap<String, Object>> connectionsArray = getBridgeConnections(connections);
            Log.i("DapiSDK", "Connections: " + connectionsArray.size());
            result.success(connectionsArray);
            return Unit.INSTANCE;
        }, error -> {
            result.error("-200", error.getMessage(), error);
            return Unit.INSTANCE;
        });
    }

    private void createConnection(String jsonConnectionParams, Result result) {
        DapiConnection.create(jsonConnectionParams, connection -> {
            result.success(getBridgeConnection(connection));
            return Unit.INSTANCE;
        }, error ->{
            result.error("-201", error.getMessage(), error);
            return Unit.INSTANCE;
        });
    }

    private void getParameters(String userID, Result result) {
        getOperatingConnection(userID, connection -> {
            result.success(connection.getParameters());
            return null;
        }, error -> {
            result.error("-202", error.getMessage(), getMap(error));
            return Unit.INSTANCE;
        });
    }

    private void getIdentity(String userID, Result result) {
        getOperatingConnection(userID, connection -> {
            connection.getIdentity(identity -> {
                result.success(getMap(identity));
                return Unit.INSTANCE;
            }, error -> {
                result.error("-300", error.getMessage(), getMap(error));
                return Unit.INSTANCE;
            });
            return null;
        }, error -> {
            result.error("-300", error.getMessage(), getMap(error));
            return Unit.INSTANCE;
        });
    }

    private void getAccounts(String userID, Result result) {
        getOperatingConnection(userID, connection -> {
            connection.getAccounts(accounts -> {
                result.success(getMap(accounts));
                return Unit.INSTANCE;
            }, error -> {
                result.error("-301", error.getMessage(), getMap(error));
                return Unit.INSTANCE;
            });
            return Unit.INSTANCE;
        }, error -> {
            result.error("-301", error.getMessage(), getMap(error));
            return Unit.INSTANCE;
        });
    }

    private void getCards(String userID, Result result) {
        getOperatingConnection(userID, connection -> {
            connection.getCards(cards -> {
                result.success(getMap(cards));
                return Unit.INSTANCE;
            }, error -> {
                result.error("-302", error.getMessage(), getMap(error));
                return Unit.INSTANCE;
            });
            return null;
        }, error -> {
            result.error("-302", error.getMessage(), getMap(error));
            return Unit.INSTANCE;
        });
    }

    public void getTransactionsForAccount(
            String userID,
            String accountID,
            long startDate,
            long endDate,
            Result result
    ) {
        Date startDateObject = new Date(startDate);
        Date endDateObject = new Date(endDate);

        getOperatingConnection(userID, connection -> {
            DapiAccountsResponse.DapiAccount account = getDapiAccount(accountID, connection);
            connection.getTransactions(account, startDateObject, endDateObject, transactions -> {
                result.success(getMap(transactions));
                return Unit.INSTANCE;
            }, error -> {
                result.error("-303", error.getMessage(), getMap(error));
                return Unit.INSTANCE;
            });
            return null;
        }, error -> {
            result.error("-303", error.getMessage(), getMap(error));
            return Unit.INSTANCE;
        });
    }

    public void getTransactionsForCard(
            String userID,
            String cardID,
            long startDate,
            long endDate,
            Result result
    ) {
        Date startDateObject = new Date(startDate);
        Date endDateObject = new Date(endDate);

        getOperatingConnection(userID, connection -> {
            DapiCardsResponse.DapiCard card = getDapiCard(cardID, connection);
            connection.getTransactions(card, startDateObject, endDateObject, transactions -> {
                result.success(getMap(transactions));
                return Unit.INSTANCE;
            }, error -> {
                result.error("-304", error.getMessage(), getMap(error));
                return Unit.INSTANCE;
            });
            return Unit.INSTANCE;
        }, error -> {
            result.error("-304", error.getMessage(), getMap(error));
            return Unit.INSTANCE;
        });
    }

    private void getAccountsMetaData(String userID, Result result) {
        getOperatingConnection(userID, connection -> {
            connection.getAccountsMetaData(metadata -> {
                result.success(getMap(metadata));
                return Unit.INSTANCE;
            }, error -> {
                result.error("-400", error.getMessage(), getMap(error));
                return Unit.INSTANCE;
            });
            return Unit.INSTANCE;
        }, error -> {
            result.error("-400", error.getMessage(), getMap(error));
            return Unit.INSTANCE;
        });
    }

    private void delete(
            String userID,
            Result result
    ) {
        getOperatingConnection(userID, connection -> {
            connection.delete(delink -> {
                result.success(getMap(delink));
                return Unit.INSTANCE;
            }, error -> {
                result.error("-500", error.getMessage(), getMap(error));
                return Unit.INSTANCE;
            });
            return null;
        }, error -> {
            result.error("-500", error.getMessage(), getMap(error));
            return Unit.INSTANCE;
        });
    }

    private void getBeneficiaries(String userID, Result result) {
        getOperatingConnection(userID, connection -> {
            connection.getBeneficiaries(beneficiaries -> {
                result.success(getMap(beneficiaries));
                return Unit.INSTANCE;
            }, error -> {
                result.error("-600", error.getMessage(), getMap(error));
                return Unit.INSTANCE;
            });
            return Unit.INSTANCE;
        }, error -> {
            result.error("-600", error.getMessage(), getMap(error));
            return Unit.INSTANCE;
        });
    }

    private void createBeneficiary(
            String userID,
            HashMap<String, Object> beneficiaryMap
            , Result result) {
        getOperatingConnection(userID, connection -> {
            connection.createBeneficiary(getBeneficiary(beneficiaryMap), createBeneficiary -> {
                result.success(getMap(createBeneficiary));
                return Unit.INSTANCE;
            }, error -> {
                result.error("-601", error.getMessage(), getMap(error));
                return Unit.INSTANCE;
            });
            return Unit.INSTANCE;
        }, error -> {
            result.error("-601", error.getMessage(), getMap(error));
            return Unit.INSTANCE;
        });
    }

    private void createTransfer(
            String userID,
            String accountID,
            HashMap<String, Object> beneficiaryMap,
            double amount,
            String remark,
            Result result
    ) {
        setTransferListener(result);
        getOperatingConnection(userID, connection -> {
            DapiAccountsResponse.DapiAccount account = getDapiAccount(accountID, connection);
            DapiBeneficiary beneficiary = getBeneficiary(beneficiaryMap);
            connection.createTransfer(account, beneficiary, amount, remark);
            return Unit.INSTANCE;
        }, error -> {
            result.error("-602", error.getMessage(), error);
            return Unit.INSTANCE;
        });
    }

    private void createTransferToExistingBeneficiary(
            String userID,
            String accountID,
            String receiverID,
            double amount,
            String remark,
            Result result
    ) {
        setTransferListener(result);
        getOperatingConnection(userID, connection -> {
            DapiAccountsResponse.DapiAccount account = getDapiAccount(accountID, connection);
            connection.createTransferToExistingBeneficiary(account, receiverID, amount, remark);
            return Unit.INSTANCE;
        }, error -> {
            result.error("-603", error.getMessage(), error);
            return Unit.INSTANCE;
        });
    }

    private void getWireBeneficiaries(String userID, Result result) {
        getOperatingConnection(userID, connection -> {
            connection.getWireBeneficiaries(beneficiaries -> {
                result.success(getMap(beneficiaries));
                return Unit.INSTANCE;
            }, error -> {
                result.error("-700", error.getMessage(), getMap(error));
                return Unit.INSTANCE;
            });
            return Unit.INSTANCE;
        }, error -> {
            result.error("-700", error.getMessage(), getMap(error));
            return Unit.INSTANCE;
        });
    }

    private void createWireBeneficiary(
            String userID,
            HashMap<String, Object> beneficiaryMap
            , Result result) {
        getOperatingConnection(userID, connection -> {
            connection.createWireBeneficiary(getWireBeneficiary(beneficiaryMap), createBeneficiary -> {
                result.success(getMap(createBeneficiary));
                return Unit.INSTANCE;
            }, error -> {
                result.error("-701", error.getMessage(), getMap(error));
                return Unit.INSTANCE;
            });
            return Unit.INSTANCE;
        }, error -> {
            result.error("-701", error.getMessage(), getMap(error));
            return Unit.INSTANCE;
        });
    }

    private void createWireTransfer(
            String userID,
            String accountID,
            HashMap<String, Object> beneficiaryMap,
            double amount,
            String remark,
            Result result
    ) {
        setTransferListener(result);
        getOperatingConnection(userID, connection -> {
            DapiAccountsResponse.DapiAccount account = getDapiAccount(accountID, connection);
            DapiWireBeneficiary beneficiary = getWireBeneficiary(beneficiaryMap);
            connection.createWireTransfer(beneficiary, account, amount, remark);
            return Unit.INSTANCE;
        }, error -> {
            result.error("-702", error.getMessage(), error);
            return Unit.INSTANCE;
        });
    }

    private void createWireTransferToExistingBeneficiary(
            String userID,
            String accountID,
            String receiverID,
            double amount,
            String remark,
            Result result
    ) {
        setTransferListener(result);
        getOperatingConnection(userID, connection -> {
            DapiAccountsResponse.DapiAccount account = getDapiAccount(accountID, connection);
            connection.createWireTransferToExistingBeneficiary(account, receiverID, amount, remark);
            return Unit.INSTANCE;
        }, error -> {
            result.error("-703", error.getMessage(), error);
            return Unit.INSTANCE;
        });
    }


    @SuppressWarnings({"ConstantConditions", "unchecked"})
    private DapiConfigurations getConfigurationsFromMap(Map<String, Object> configurations) {
        if (configurations == null) {
            return null;
        }
        HashMap<String, Object> extraQueryParameters;
        HashMap<String, Object> extraHeaderFields;
        HashMap<String, Object> extraBody;
        DapiEndpoints endpoints;
        DapiEnvironment environment;
        String[] countries;
        boolean showLogos = true;
        boolean showExperimentalBanks = false;
        boolean showCloseButton = true;
        boolean showAddButton = false;
        boolean showTransferSuccessfulResult = true;
        boolean showTransferErrorResult = true;
        String postSuccessfulConnectionLoadingText = "Verifying your account..";


        if (configurations.get("countries") != null) {
            ArrayList<String> countriesList = (ArrayList<String>) configurations.get("countries");
            countries = new String[countriesList.size()];
            for (int i = 0; i < countriesList.size(); i++)
                countries[i] = countriesList.get(i);
        } else {
            countries = new String[]{};
        }

        if (configurations.get("showLogos") != null) {
            showLogos = (boolean) configurations.get("showLogos");
        }

        if (configurations.get("showExperimentalBanks") != null) {
            showExperimentalBanks = (boolean) configurations.get("showExperimentalBanks");
        }

        if (configurations.get("showCloseButton") != null) {
            showCloseButton = (boolean) configurations.get("showCloseButton");
        }

        if (configurations.get("showAddButton") != null) {
            showAddButton = (boolean) configurations.get("showAddButton");
        }

        if (configurations.get("showTransferSuccessfulResult") != null) {
            showTransferSuccessfulResult = (boolean) configurations.get("showTransferSuccessfulResult");
        }

        if (configurations.get("showTransferErrorResult") != null) {
            showTransferErrorResult = (boolean) configurations.get("showTransferErrorResult");
        }

        if (configurations.get("postSuccessfulConnectionLoadingText") != null) {
            postSuccessfulConnectionLoadingText = (String) configurations.get("postSuccessfulConnectionLoadingText");
        }

        if (configurations.get("extraQueryParameters") != null) {
            extraQueryParameters = (HashMap<String, Object>) configurations.get("extraQueryParameters");
        } else {
            extraQueryParameters = new HashMap<>();
        }

        if (configurations.get("extraHeaderFields") != null) {
            extraHeaderFields = (HashMap<String, Object>) configurations.get("extraHeaderFields");
        } else {
            extraHeaderFields = new HashMap<>();
        }

        if (configurations.get("extraBody") != null) {
            extraBody = (HashMap<String, Object>) configurations.get("extraBody");
        } else {
            extraBody = new HashMap<>();
        }

        if (configurations.get("environment") != null) {
            String environmentString = (String) configurations.get("environment");
            if (environmentString.toLowerCase(Locale.ROOT).equals("sandbox")) {
                environment = DapiEnvironment.SANDBOX;
            } else {
                environment = DapiEnvironment.PRODUCTION;
            }
        } else {
            environment = DapiEnvironment.PRODUCTION;
        }

        if (configurations.get("endpoints") != null) {
            endpoints = getDapiEndpoints(configurations);
        } else {
            endpoints = new DapiEndpoints();
        }

        return new DapiConfigurations(
                endpoints,
                extraBody,
                extraQueryParameters,
                extraHeaderFields,
                environment,
                countries,
                showLogos,
                showExperimentalBanks,
                showCloseButton,
                showAddButton,
                postSuccessfulConnectionLoadingText,
                showTransferSuccessfulResult,
                showTransferErrorResult
        );
    }

    @SuppressWarnings({"unchecked", "ConstantConditions"})
    private DapiEndpoints getDapiEndpoints(Map<String, Object> configurations) {
        if (configurations.get("endpoints") == null) {
            return new DapiEndpoints();
        }
        Map<String, Object> endpointsMap = (Map<String, Object>) configurations.get("endpoints");
        String exchangeToken;
        String getIdentity;
        String getAccounts;
        String getCards;
        String getTransactions;
        String accountMetaData;
        String delete;
        String createTransfer;
        String createTransferToExistingBeneficiary;
        String createBeneficiary;
        String getBeneficiaries;
        String createWireTransfer;
        String createWireTransferToExistingBeneficiary;
        String createWireBeneficiary;
        String getWireBeneficiaries;

        if (endpointsMap.containsKey("exchangeToken")) {
            exchangeToken = (String) endpointsMap.get("exchangeToken");
        } else {
            exchangeToken = DapiEndpoints.GET_CARDS_ENDPOINT;
        }

        if (endpointsMap.containsKey("getIdentity")) {
            getIdentity = (String) endpointsMap.get("getIdentity");
        } else {
            getIdentity = DapiEndpoints.GET_IDENTITY_ENDPOINT;
        }

        if (endpointsMap.containsKey("getAccounts")) {
            getAccounts = (String) endpointsMap.get("getAccounts");
        } else {
            getAccounts = DapiEndpoints.GET_ACCOUNTS_ENDPOINT;
        }

        if (endpointsMap.containsKey("getCards")) {
            getCards = (String) endpointsMap.get("getCards");
        } else {
            getCards = DapiEndpoints.GET_CARDS_ENDPOINT;
        }

        if (endpointsMap.containsKey("getTransactions")) {
            getTransactions = (String) endpointsMap.get("getTransactions");
        } else {
            getTransactions = DapiEndpoints.GET_TRANSACTIONS_ENDPOINT;
        }

        if (endpointsMap.containsKey("getAccountMetadata")) {
            accountMetaData = (String) endpointsMap.get("getAccountMetadata");
        } else {
            accountMetaData = DapiEndpoints.ACCOUNTS_META_DATA_ENDPOINT;
        }

        if (endpointsMap.containsKey("delete")) {
            delete = (String) endpointsMap.get("delete");
        } else {
            delete = DapiEndpoints.DELETE_CONNECTION_ENDPOINT;
        }

        if (endpointsMap.containsKey("createTransfer")) {
            createTransfer = (String) endpointsMap.get("createTransfer");
        } else {
            createTransfer = DapiEndpoints.CREATE_TRANSFER_AUTOFLOW_ENDPOINT;
        }

        if (endpointsMap.containsKey("createTransferToExistingBeneficiary")) {
            createTransferToExistingBeneficiary = (String) endpointsMap.get("createTransferToExistingBeneficiary");
        } else {
            createTransferToExistingBeneficiary = DapiEndpoints.CREATE_TRANSFER_TO_EXISTING_BENEFICIARY_ENDPOINT;
        }

        if (endpointsMap.containsKey("createBeneficiary")) {
            createBeneficiary = (String) endpointsMap.get("createBeneficiary");
        } else {
            createBeneficiary = DapiEndpoints.CREATE_BENEFICIARY_ENDPOINT;
        }

        if (endpointsMap.containsKey("getBeneficiaries")) {
            getBeneficiaries = (String) endpointsMap.get("getBeneficiaries");
        } else {
            getBeneficiaries = DapiEndpoints.GET_BENEFICIARIES_ENDPOINT;
        }

        if (endpointsMap.containsKey("createWireTransfer")) {
            createWireTransfer = (String) endpointsMap.get("createWireTransfer");
        } else {
            createWireTransfer = DapiEndpoints.CREATE_WIRE_TRANSFER_ENDPOINT;
        }

        if (endpointsMap.containsKey("createWireTransferToExistingBeneficiary")) {
            createWireTransferToExistingBeneficiary = (String) endpointsMap.get("createWireTransferToExistingBeneficiary");
        } else {
            createWireTransferToExistingBeneficiary = DapiEndpoints.CREATE_WIRE_TRANSFER_TO_EXISTING_BENEFICIARY_ENDPOINT;
        }

        if (endpointsMap.containsKey("createWireBeneficiary")) {
            createWireBeneficiary = (String) endpointsMap.get("createWireBeneficiary");
        } else {
            createWireBeneficiary = DapiEndpoints.CREATE_WIRE_BENEFICIARY_ENDPOINT;
        }

        if (endpointsMap.containsKey("getWireBeneficiaries")) {
            getWireBeneficiaries = (String) endpointsMap.get("getWireBeneficiaries");
        } else {
            getWireBeneficiaries = DapiEndpoints.GET_WIRE_BENEFICIARIES_ENDPOINT;
        }

        return new DapiEndpoints(
                getIdentity,
                getAccounts,
                getTransactions,
                accountMetaData,
                createTransfer,
                createTransferToExistingBeneficiary,
                createBeneficiary,
                getBeneficiaries,
                delete,
                getCards,
                exchangeToken,
                getWireBeneficiaries,
                createWireBeneficiary,
                createWireTransfer,
                createWireTransferToExistingBeneficiary
        );
    }


    @SuppressWarnings({"unchecked", "ConstantConditions"})
    private DapiBeneficiary getBeneficiary(HashMap<String, Object> beneficiaryMap) {
        if (beneficiaryMap == null) {
            return null;
        }
        HashMap<String, Object> linesMap = (HashMap<String, Object>) beneficiaryMap.get("address");
        String line1 = (String) linesMap.get("line1");
        String line2 = (String) linesMap.get("line2");
        String line3 = (String) linesMap.get("line3");
        LinesAddress linesAddress = new LinesAddress(
                line1,
                line2,
                line3
        );
        String accountNumber = (String) beneficiaryMap.get("accountNumber");
        String name = (String) beneficiaryMap.get("name");
        String bankName = (String) beneficiaryMap.get("bankName");
        String swiftCode = (String) beneficiaryMap.get("swiftCode");
        String iban = (String) beneficiaryMap.get("iban");
        String phoneNumber = (String) beneficiaryMap.get("phoneNumber");
        String country = (String) beneficiaryMap.get("country");
        String branchAddress = (String) beneficiaryMap.get("branchAddress");
        String branchName = (String) beneficiaryMap.get("branchName");
        String nickname = (String) beneficiaryMap.get("nickname");

        return new DapiBeneficiary(
                linesAddress,
                accountNumber,
                name,
                bankName,
                swiftCode,
                iban,
                country,
                branchAddress,
                branchName,
                phoneNumber,
                nickname
        );
    }

    @SuppressWarnings({"unchecked", "ConstantConditions"})
    private DapiWireBeneficiary getWireBeneficiary(HashMap<String, Object> beneficiaryMap) {
        if (beneficiaryMap == null) {
            return null;
        }

        HashMap<String, Object> linesMap = (HashMap<String, Object>) beneficiaryMap.get("address");
        String line1 = (String) linesMap.get("line1");
        String line2 = (String) linesMap.get("line2");
        String line3 = (String) linesMap.get("line3");
        LinesAddress linesAddress = new LinesAddress(
                line1,
                line2,
                line3
        );

        String name = (String) beneficiaryMap.get("name");
        String firstName = (String) beneficiaryMap.get("firstName");
        String lastName = (String) beneficiaryMap.get("lastName");
        String nickname = (String) beneficiaryMap.get("nickname");
        String city = (String) beneficiaryMap.get("city");
        String state = (String) beneficiaryMap.get("state");
        String country = (String) beneficiaryMap.get("country");
        String zipCode = (String) beneficiaryMap.get("zipCode");
        String receiverType = (String) beneficiaryMap.get("receiverType");
        String receiverAccountType = (String) beneficiaryMap.get("receiverAccountType");
        String routingNumber = (String) beneficiaryMap.get("routingNumber");
        String accountNumber = (String) beneficiaryMap.get("accountNumber");


        return new DapiWireBeneficiary(
                name,
                firstName,
                lastName,
                nickname,
                linesAddress,
                city,
                state,
                country,
                zipCode,
                receiverType,
                receiverAccountType,
                routingNumber,
                accountNumber
        );
    }

    @SuppressWarnings("ConstantConditions")
    private DapiAccountsResponse.DapiAccount getDapiAccount(String accountID, DapiConnection connection) {
        for (DapiAccountsResponse.DapiAccount account : connection.getAccounts()) {
            if (account.getId().equals(accountID)) {
                return account;
            }
        }
        return null;
    }

    @SuppressWarnings("ConstantConditions")
    private DapiCardsResponse.DapiCard getDapiCard(String cardID, DapiConnection connection) {
        for (DapiCardsResponse.DapiCard card : connection.getCards()) {
            if (card.getId().equals(cardID)) {
                return card;
            }
        }
        return null;
    }

    private void getOperatingConnection(String userID, Function1<? super DapiConnection, Unit> onSuccess, Function1<? super DapiError, Unit> onFailure) {
        Dapi.getConnections(connections -> {
            for (DapiConnection connection : connections) {
                if (connection.getUserID().equals(userID)) {
                    onSuccess.invoke(connection);
                    break;
                }
            }
            return Unit.INSTANCE;
        }, error -> {
            onFailure.invoke(error);
            return Unit.INSTANCE;
        });
    }

    private void setTransferListener(Result result) {
        Dapi.setTransferListener(new OnDapiTransferListener() {
            @Override
            public void willTransferAmount(double sentAmount, @NotNull DapiAccountsResponse.DapiAccount senderAccount) {
                if (transferUiWillSendEvents != null) {
                    HashMap<String, Object> data = new HashMap<>();
                    data.put("account", senderAccount.getId());
                    data.put("amount", sentAmount);
                    transferUiWillSendEvents.success(data);
                }
            }

            @Override
            public void onTransferSuccess(@NotNull DapiAccountsResponse.DapiAccount senderAccount, double sentAmount, @org.jetbrains.annotations.Nullable String reference, @org.jetbrains.annotations.Nullable String operationID) {
                HashMap<String, Object> data = new HashMap<>();
                data.put("account", senderAccount.getId());
                data.put("amount", sentAmount);
                data.put("operationID", operationID);
                result.success(data);
            }

            @Override
            public void onTransferFailure(@org.jetbrains.annotations.Nullable DapiAccountsResponse.DapiAccount account, @NotNull DapiError error) {
                result.error("-602", error.getMessage(), getMap(error));
            }

            @Override
            public void onUiDismissed() {
                if (transferUiDismissedEvents != null) {
                    transferUiDismissedEvents.success(null);
                }
            }
        });
    }

    @NonNull
    private ArrayList<HashMap<String, Object>> getBridgeConnections(List<DapiConnection> connections) {
        ArrayList<HashMap<String, Object>> connectionsArray = new ArrayList<>();
        for (DapiConnection connection : connections) {
            HashMap<String, Object> connectionMap = getBridgeConnection(connection);
            connectionsArray.add(connectionMap);
        }
        return connectionsArray;
    }

    @NonNull
    private HashMap<String, Object> getBridgeConnection(DapiConnection connection) {
        HashMap<String, Object> connectionMap = new HashMap<>();
        connectionMap.put("userID", connection.getUserID());
        connectionMap.put("clientUserID", connection.getClientUserID());
        connectionMap.put("bankID", connection.getBankId());
        connectionMap.put("swiftCode", connection.getSwiftCode());
        connectionMap.put("bankShortName", connection.getName());
        connectionMap.put("bankFullName", connection.getFullName());
        connectionMap.put("country", connection.getCountry());
        connectionMap.put("fullLogo", connection.getFullLogoPng());
        connectionMap.put("halfLogo", connection.getHalfLogoPng());
        connectionMap.put("miniLogo", connection.getMiniLogoPng());
        connectionMap.put("accounts", getBridgeAccounts(connection));
        connectionMap.put("cards", getBridgeCards(connection));
        return connectionMap;
    }

    @SuppressWarnings("ConstantConditions")
    @NonNull
    private ArrayList<HashMap<String, Object>> getBridgeCards(DapiConnection connection) {
        ArrayList<HashMap<String, Object>> resultCardMapArray = new ArrayList<>();
        for (DapiCardsResponse.DapiCard card : connection.getCards()) {
            HashMap<String, Object> currencyMap = new HashMap<>();
            currencyMap.put("code", card.getCurrency().getCode());
            currencyMap.put("name", card.getCurrency().getName());

            HashMap<String, Object> balanceMap = new HashMap<>();
            balanceMap.put("amountDue", String.valueOf(card.getBalance().getAmountDue()));
            balanceMap.put("availableBalance", String.valueOf(card.getBalance().getAvailableBalance()));
            balanceMap.put("dueDate", card.getBalance().getDueDate());
            balanceMap.put("outstandingBalance", String.valueOf(card.getBalance().getOutstandingBalance()));


            HashMap<String, Object> cardMap = new HashMap<>();
            cardMap.put("cardNumber", card.getCardNumber());
            cardMap.put("creditLimit", String.valueOf(card.getCreditLimit()));
            cardMap.put("currency", currencyMap);
            cardMap.put("type", card.getType());
            cardMap.put("name", card.getName());
            cardMap.put("id", card.getId());
            cardMap.put("expiryDate", card.getExpiryDate());
            cardMap.put("status", card.getStatus());
            cardMap.put("balance", balanceMap);
            resultCardMapArray.add(cardMap);
        }
        return resultCardMapArray;
    }

    @SuppressWarnings("ConstantConditions")
    @NonNull
    private ArrayList<HashMap<String, Object>> getBridgeAccounts(DapiConnection connection) {
        ArrayList<HashMap<String, Object>> resultAccountMapArray = new ArrayList<>();
        for (DapiAccountsResponse.DapiAccount account : connection.getAccounts()) {
            HashMap<String, Object> currencyMap = new HashMap<>();
            currencyMap.put("code", account.getCurrency().getCode());
            currencyMap.put("name", account.getCurrency().getName());

            HashMap<String, Object> accountMap = new HashMap<>();
            accountMap.put("iban", account.getIban());
            accountMap.put("number", account.getNumber());
            accountMap.put("currency", currencyMap);
            accountMap.put("type", account.getType());
            accountMap.put("name", account.getName());
            accountMap.put("id", account.getId());
            accountMap.put("balance", getMap(account.getBalance()));
            resultAccountMapArray.add(accountMap);
        }
        return resultAccountMapArray;
    }

    private Map<String, Object> getMap(Object object) {
        Gson gson = new Gson();
        String json = gson.toJson(object);
        Type type = new TypeToken<Map<String, Object>>() {
        }.getType();
        return gson.fromJson(json, type);
    }

    class SuccessfulConnectionStreamHandler implements EventChannel.StreamHandler {
        @Override
        public void onListen(Object arguments, EventChannel.EventSink events) {
            DapiPlugin.this.connectionSuccessfulEvents = events;
            Dapi.setConnectListener(DapiPlugin.this.connectListener);
        }

        @Override
        public void onCancel(Object arguments) {
            Dapi.setConnectListener(null);
        }
    }

    class FailureConnectionStreamHandler implements EventChannel.StreamHandler {
        @Override
        public void onListen(Object arguments, EventChannel.EventSink events) {
            DapiPlugin.this.connectionFailureEvents = events;
            Dapi.setConnectListener(DapiPlugin.this.connectListener);
        }

        @Override
        public void onCancel(Object arguments) {
            Dapi.setConnectListener(null);
        }
    }

    class BankRequestStreamHandler implements EventChannel.StreamHandler {
        @Override
        public void onListen(Object arguments, EventChannel.EventSink events) {
            DapiPlugin.this.bankRequestEvents = events;
            Dapi.setConnectListener(DapiPlugin.this.connectListener);
        }

        @Override
        public void onCancel(Object arguments) {
            Dapi.setConnectListener(null);
        }
    }

    class ConnectDismissedStreamHandler implements EventChannel.StreamHandler {
        @Override
        public void onListen(Object arguments, EventChannel.EventSink events) {
            DapiPlugin.this.connectDismissedEvents = events;
            Dapi.setConnectListener(DapiPlugin.this.connectListener);
        }

        @Override
        public void onCancel(Object arguments) {
            Dapi.setConnectListener(null);
        }
    }

    class TransferUiDismissedStreamHandler implements EventChannel.StreamHandler {
        @Override
        public void onListen(Object arguments, EventChannel.EventSink events) {
            DapiPlugin.this.transferUiDismissedEvents = events;
        }

        @Override
        public void onCancel(Object arguments) {

        }
    }

    class TransferUiWillSendStreamHandler implements EventChannel.StreamHandler {
        @Override
        public void onListen(Object arguments, EventChannel.EventSink events) {
            DapiPlugin.this.transferUiWillSendEvents = events;
        }

        @Override
        public void onCancel(Object arguments) {

        }
    }

}
