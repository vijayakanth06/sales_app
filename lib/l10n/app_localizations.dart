import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ta.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ta'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'HomeSales Tracker'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navGroups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get navGroups;

  /// No description provided for @navPersons.
  ///
  /// In en, this message translates to:
  /// **'Persons'**
  String get navPersons;

  /// No description provided for @navQuick.
  ///
  /// In en, this message translates to:
  /// **'Quick Sale'**
  String get navQuick;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @btnSave.
  ///
  /// In en, this message translates to:
  /// **'SAVE'**
  String get btnSave;

  /// No description provided for @btnCalculate.
  ///
  /// In en, this message translates to:
  /// **'CALCULATE'**
  String get btnCalculate;

  /// No description provided for @btnCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get btnCancel;

  /// No description provided for @btnAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get btnAdd;

  /// No description provided for @btnEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get btnEdit;

  /// No description provided for @btnDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get btnDelete;

  /// No description provided for @btnAddProduct.
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get btnAddProduct;

  /// No description provided for @btnAddGroup.
  ///
  /// In en, this message translates to:
  /// **'Add Group'**
  String get btnAddGroup;

  /// No description provided for @btnAddPerson.
  ///
  /// In en, this message translates to:
  /// **'Add Person'**
  String get btnAddPerson;

  /// No description provided for @labelPaid.
  ///
  /// In en, this message translates to:
  /// **'PAID'**
  String get labelPaid;

  /// No description provided for @labelPartial.
  ///
  /// In en, this message translates to:
  /// **'PARTIAL'**
  String get labelPartial;

  /// No description provided for @labelUnpaid.
  ///
  /// In en, this message translates to:
  /// **'NOT PAID'**
  String get labelUnpaid;

  /// No description provided for @labelCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get labelCash;

  /// No description provided for @labelGpay.
  ///
  /// In en, this message translates to:
  /// **'GPay'**
  String get labelGpay;

  /// No description provided for @labelOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get labelOther;

  /// No description provided for @labelBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get labelBalance;

  /// No description provided for @labelTotalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get labelTotalAmount;

  /// No description provided for @labelTodayRevenue.
  ///
  /// In en, this message translates to:
  /// **'Today Revenue'**
  String get labelTodayRevenue;

  /// No description provided for @labelTodayCollected.
  ///
  /// In en, this message translates to:
  /// **'Today Collected'**
  String get labelTodayCollected;

  /// No description provided for @labelTodayBalance.
  ///
  /// In en, this message translates to:
  /// **'Today Balance'**
  String get labelTodayBalance;

  /// No description provided for @labelQuickSales.
  ///
  /// In en, this message translates to:
  /// **'Quick Sales'**
  String get labelQuickSales;

  /// No description provided for @labelOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get labelOutstanding;

  /// No description provided for @labelProducts.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get labelProducts;

  /// No description provided for @labelGroups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get labelGroups;

  /// No description provided for @labelPersons.
  ///
  /// In en, this message translates to:
  /// **'Persons'**
  String get labelPersons;

  /// No description provided for @labelLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get labelLanguage;

  /// No description provided for @labelExport.
  ///
  /// In en, this message translates to:
  /// **'Export / Import'**
  String get labelExport;

  /// No description provided for @labelAppInfo.
  ///
  /// In en, this message translates to:
  /// **'App Info'**
  String get labelAppInfo;

  /// No description provided for @labelSellingPrice.
  ///
  /// In en, this message translates to:
  /// **'Selling Price'**
  String get labelSellingPrice;

  /// No description provided for @labelCostPrice.
  ///
  /// In en, this message translates to:
  /// **'Cost Price'**
  String get labelCostPrice;

  /// No description provided for @labelProductName.
  ///
  /// In en, this message translates to:
  /// **'Product Name'**
  String get labelProductName;

  /// No description provided for @labelPersonName.
  ///
  /// In en, this message translates to:
  /// **'Person Name'**
  String get labelPersonName;

  /// No description provided for @labelGroupName.
  ///
  /// In en, this message translates to:
  /// **'Group Name'**
  String get labelGroupName;

  /// No description provided for @labelPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get labelPhone;

  /// No description provided for @labelAge.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get labelAge;

  /// No description provided for @labelPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get labelPaymentMethod;

  /// No description provided for @labelAmountPaid.
  ///
  /// In en, this message translates to:
  /// **'Amount Paid'**
  String get labelAmountPaid;

  /// No description provided for @labelNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get labelNotes;

  /// No description provided for @labelBulkOrders.
  ///
  /// In en, this message translates to:
  /// **'Bulk Orders'**
  String get labelBulkOrders;

  /// No description provided for @labelCustomerName.
  ///
  /// In en, this message translates to:
  /// **'Customer Name'**
  String get labelCustomerName;

  /// No description provided for @labelDeliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Delivery Address'**
  String get labelDeliveryAddress;

  /// No description provided for @labelStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get labelStatus;

  /// No description provided for @labelPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get labelPending;

  /// No description provided for @labelDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get labelDelivered;

  /// No description provided for @labelCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get labelCancelled;

  /// No description provided for @labelFactory.
  ///
  /// In en, this message translates to:
  /// **'Factory'**
  String get labelFactory;

  /// No description provided for @labelSite.
  ///
  /// In en, this message translates to:
  /// **'Site'**
  String get labelSite;

  /// No description provided for @labelShop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get labelShop;

  /// No description provided for @labelOtherType.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get labelOtherType;

  /// No description provided for @labelCalculate.
  ///
  /// In en, this message translates to:
  /// **'Calculate'**
  String get labelCalculate;

  /// No description provided for @labelPerson.
  ///
  /// In en, this message translates to:
  /// **'Person'**
  String get labelPerson;

  /// No description provided for @labelGroup.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get labelGroup;

  /// No description provided for @labelDateFrom.
  ///
  /// In en, this message translates to:
  /// **'From Date'**
  String get labelDateFrom;

  /// No description provided for @labelDateTo.
  ///
  /// In en, this message translates to:
  /// **'To Date'**
  String get labelDateTo;

  /// No description provided for @labelTotalBought.
  ///
  /// In en, this message translates to:
  /// **'Total Bought'**
  String get labelTotalBought;

  /// No description provided for @labelTotalPaid.
  ///
  /// In en, this message translates to:
  /// **'Total Paid'**
  String get labelTotalPaid;

  /// No description provided for @labelSettlements.
  ///
  /// In en, this message translates to:
  /// **'Settlements'**
  String get labelSettlements;

  /// No description provided for @labelNetBalance.
  ///
  /// In en, this message translates to:
  /// **'Net Balance'**
  String get labelNetBalance;

  /// No description provided for @labelGrossProfit.
  ///
  /// In en, this message translates to:
  /// **'Gross Profit'**
  String get labelGrossProfit;

  /// No description provided for @labelRecordPayment.
  ///
  /// In en, this message translates to:
  /// **'Record Payment'**
  String get labelRecordPayment;

  /// No description provided for @labelShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get labelShare;

  /// No description provided for @labelTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get labelTransactions;

  /// No description provided for @labelNoData.
  ///
  /// In en, this message translates to:
  /// **'No data found'**
  String get labelNoData;

  /// No description provided for @labelToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get labelToday;

  /// No description provided for @labelActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get labelActive;

  /// No description provided for @labelInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get labelInactive;

  /// No description provided for @msgSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Saved successfully!'**
  String get msgSaveSuccess;

  /// No description provided for @msgNoProducts.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one product'**
  String get msgNoProducts;

  /// No description provided for @msgEnterAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter amount'**
  String get msgEnterAmount;

  /// No description provided for @msgConfirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get msgConfirmDelete;

  /// No description provided for @msgExportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Data exported successfully'**
  String get msgExportSuccess;

  /// No description provided for @msgImportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Data imported successfully'**
  String get msgImportSuccess;

  /// No description provided for @labelSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get labelSelectAll;

  /// No description provided for @labelDeselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect All'**
  String get labelDeselectAll;

  /// No description provided for @labelGroupTotal.
  ///
  /// In en, this message translates to:
  /// **'Group Total'**
  String get labelGroupTotal;

  /// No description provided for @labelIndividual.
  ///
  /// In en, this message translates to:
  /// **'Individual'**
  String get labelIndividual;

  /// No description provided for @labelQuickSale.
  ///
  /// In en, this message translates to:
  /// **'Quick Sale'**
  String get labelQuickSale;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ta':
      return AppLocalizationsTa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
