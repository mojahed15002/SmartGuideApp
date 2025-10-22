import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
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
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Smart City Guide'**
  String get appTitle;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Smart City Guide'**
  String get welcome;

  /// No description provided for @explorePlaces.
  ///
  /// In en, this message translates to:
  /// **'Explore Places'**
  String get explorePlaces;

  /// No description provided for @nearMe.
  ///
  /// In en, this message translates to:
  /// **'Near Me'**
  String get nearMe;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @logs.
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get logs;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About the App'**
  String get aboutApp;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @explore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get explore;

  /// No description provided for @cityGuideDescription.
  ///
  /// In en, this message translates to:
  /// **'Smart City Guide helps you explore your city easily and discover its landmarks.'**
  String get cityGuideDescription;

  /// No description provided for @logoutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get logoutConfirmation;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @themeApplied.
  ///
  /// In en, this message translates to:
  /// **'Theme updated successfully!'**
  String get themeApplied;

  /// No description provided for @languageApplied.
  ///
  /// In en, this message translates to:
  /// **'Language changed successfully!'**
  String get languageApplied;

  /// No description provided for @visitor.
  ///
  /// In en, this message translates to:
  /// **'visitor'**
  String get visitor;

  /// No description provided for @welcomeVisitor.
  ///
  /// In en, this message translates to:
  /// **'Welcome visitor 👋'**
  String get welcomeVisitor;

  /// No description provided for @chooseLocation.
  ///
  /// In en, this message translates to:
  /// **'Choose Location'**
  String get chooseLocation;

  /// No description provided for @academyStreet.
  ///
  /// In en, this message translates to:
  /// **'Academy Street'**
  String get academyStreet;

  /// No description provided for @sofianStreet.
  ///
  /// In en, this message translates to:
  /// **'Sofian Street'**
  String get sofianStreet;

  /// No description provided for @faisalStreet.
  ///
  /// In en, this message translates to:
  /// **'Faisal Street'**
  String get faisalStreet;

  /// No description provided for @martyrsRoundabout.
  ///
  /// In en, this message translates to:
  /// **'Martyrs Roundabout'**
  String get martyrsRoundabout;

  /// No description provided for @palestineStreet.
  ///
  /// In en, this message translates to:
  /// **'Palestine Street'**
  String get palestineStreet;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search for a place or street...'**
  String get searchHint;

  /// No description provided for @whereAmI.
  ///
  /// In en, this message translates to:
  /// **'Where am I? 📍'**
  String get whereAmI;

  /// No description provided for @viewAllCities.
  ///
  /// In en, this message translates to:
  /// **'View all cities 🏙️'**
  String get viewAllCities;

  /// No description provided for @locationServiceDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location service is disabled'**
  String get locationServiceDisabled;

  /// No description provided for @locationDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied'**
  String get locationDenied;

  /// No description provided for @locationDeniedForever.
  ///
  /// In en, this message translates to:
  /// **'Location permission permanently denied'**
  String get locationDeniedForever;

  /// No description provided for @restaurants.
  ///
  /// In en, this message translates to:
  /// **'Restaurants'**
  String get restaurants;

  /// No description provided for @cafes.
  ///
  /// In en, this message translates to:
  /// **'Cafes'**
  String get cafes;

  /// No description provided for @clothingStores.
  ///
  /// In en, this message translates to:
  /// **'Clothing Stores'**
  String get clothingStores;

  /// No description provided for @sweets.
  ///
  /// In en, this message translates to:
  /// **'Sweets'**
  String get sweets;

  /// No description provided for @hotels.
  ///
  /// In en, this message translates to:
  /// **'Hotels'**
  String get hotels;

  /// No description provided for @touristPlaces.
  ///
  /// In en, this message translates to:
  /// **'Tourist Places'**
  String get touristPlaces;

  /// No description provided for @favoritesTitle.
  ///
  /// In en, this message translates to:
  /// **'Favorites ❤️'**
  String get favoritesTitle;

  /// No description provided for @noFavorites.
  ///
  /// In en, this message translates to:
  /// **'No places added to favorites yet.'**
  String get noFavorites;

  /// No description provided for @addedToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Added to favorites ❤️'**
  String get addedToFavorites;

  /// No description provided for @removedFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Removed from favorites 💔'**
  String get removedFromFavorites;

  /// No description provided for @travelLogsTitle.
  ///
  /// In en, this message translates to:
  /// **'Travel Logs'**
  String get travelLogsTitle;

  /// No description provided for @deleteAllLogsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete all logs'**
  String get deleteAllLogsTooltip;

  /// No description provided for @confirmDeleteAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Deletion 🗑️'**
  String get confirmDeleteAllTitle;

  /// No description provided for @confirmDeleteAllMsg.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete all logs? This action cannot be undone.'**
  String get confirmDeleteAllMsg;

  /// No description provided for @deleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete All'**
  String get deleteAll;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @allLogsDeleted.
  ///
  /// In en, this message translates to:
  /// **'🗑️ All logs deleted'**
  String get allLogsDeleted;

  /// No description provided for @confirmDeleteTripTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Trip Deletion 🗑️'**
  String get confirmDeleteTripTitle;

  /// No description provided for @confirmDeleteTripMsg.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this trip?'**
  String get confirmDeleteTripMsg;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @tripDeleted.
  ///
  /// In en, this message translates to:
  /// **'🗑️ Trip deleted'**
  String get tripDeleted;

  /// No description provided for @tripDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Failed to delete trip:'**
  String get tripDeleteFailed;

  /// No description provided for @cannotLocateDestination.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Unable to locate destination'**
  String get cannotLocateDestination;

  /// No description provided for @mapError.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Error opening map'**
  String get mapError;

  /// No description provided for @unknownPlace.
  ///
  /// In en, this message translates to:
  /// **'Unknown place'**
  String get unknownPlace;

  /// No description provided for @tripDetails.
  ///
  /// In en, this message translates to:
  /// **'Trip Details 🧭'**
  String get tripDetails;

  /// No description provided for @destinationLabel.
  ///
  /// In en, this message translates to:
  /// **'📍 Destination'**
  String get destinationLabel;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'📅 Date'**
  String get dateLabel;

  /// No description provided for @timeLabel.
  ///
  /// In en, this message translates to:
  /// **'🕓 Time'**
  String get timeLabel;

  /// No description provided for @chooseAction.
  ///
  /// In en, this message translates to:
  /// **'Choose an action:'**
  String get chooseAction;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @deleteTrip.
  ///
  /// In en, this message translates to:
  /// **'Delete Trip'**
  String get deleteTrip;

  /// No description provided for @viewOnMap.
  ///
  /// In en, this message translates to:
  /// **'View on Map'**
  String get viewOnMap;

  /// No description provided for @pleaseLoginToViewLogs.
  ///
  /// In en, this message translates to:
  /// **'Please log in to view travel logs.'**
  String get pleaseLoginToViewLogs;

  /// No description provided for @noTripsYet.
  ///
  /// In en, this message translates to:
  /// **'No trips saved yet.'**
  String get noTripsYet;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @signInError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while signing in'**
  String get signInError;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @googleSignInError.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed'**
  String get googleSignInError;

  /// No description provided for @googleUser.
  ///
  /// In en, this message translates to:
  /// **'Google User'**
  String get googleUser;

  /// No description provided for @guestLogin.
  ///
  /// In en, this message translates to:
  /// **'Continue as Guest'**
  String get guestLogin;

  /// No description provided for @guest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guest;

  /// No description provided for @guestLoginError.
  ///
  /// In en, this message translates to:
  /// **'Failed to sign in as guest'**
  String get guestLoginError;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create New Account'**
  String get createAccount;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @createYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Your Account ✨'**
  String get createYourAccount;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @enterFullName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your full name'**
  String get enterFullName;

  /// No description provided for @enterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get enterValidEmail;

  /// No description provided for @shortPassword.
  ///
  /// In en, this message translates to:
  /// **'Password is too short'**
  String get shortPassword;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @enterPhone.
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number'**
  String get enterPhone;

  /// No description provided for @invalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number'**
  String get invalidPhone;

  /// No description provided for @birthDate.
  ///
  /// In en, this message translates to:
  /// **'Birth Date'**
  String get birthDate;

  /// No description provided for @birthNotSelected.
  ///
  /// In en, this message translates to:
  /// **'Birth date not selected'**
  String get birthNotSelected;

  /// No description provided for @selectBirthDate.
  ///
  /// In en, this message translates to:
  /// **'Select birth date'**
  String get selectBirthDate;

  /// No description provided for @choose.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get choose;

  /// No description provided for @accountCreated.
  ///
  /// In en, this message translates to:
  /// **'Account created successfully 🎉'**
  String get accountCreated;

  /// No description provided for @signUpError.
  ///
  /// In en, this message translates to:
  /// **'Error occurred while creating account'**
  String get signUpError;

  /// No description provided for @emailInUse.
  ///
  /// In en, this message translates to:
  /// **'This email is already in use'**
  String get emailInUse;

  /// No description provided for @weakPassword.
  ///
  /// In en, this message translates to:
  /// **'The password is too weak'**
  String get weakPassword;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get alreadyHaveAccount;

  /// No description provided for @countrySaudi.
  ///
  /// In en, this message translates to:
  /// **'Saudi Arabia'**
  String get countrySaudi;

  /// No description provided for @countryUAE.
  ///
  /// In en, this message translates to:
  /// **'United Arab Emirates'**
  String get countryUAE;

  /// No description provided for @countryEgypt.
  ///
  /// In en, this message translates to:
  /// **'Egypt'**
  String get countryEgypt;

  /// No description provided for @countryJordan.
  ///
  /// In en, this message translates to:
  /// **'Jordan'**
  String get countryJordan;

  /// No description provided for @countryKuwait.
  ///
  /// In en, this message translates to:
  /// **'Kuwait'**
  String get countryKuwait;

  /// No description provided for @countryQatar.
  ///
  /// In en, this message translates to:
  /// **'Qatar'**
  String get countryQatar;

  /// No description provided for @countryOman.
  ///
  /// In en, this message translates to:
  /// **'Oman'**
  String get countryOman;

  /// No description provided for @countryBahrain.
  ///
  /// In en, this message translates to:
  /// **'Bahrain'**
  String get countryBahrain;

  /// No description provided for @countryLebanon.
  ///
  /// In en, this message translates to:
  /// **'Lebanon'**
  String get countryLebanon;

  /// No description provided for @countryIraq.
  ///
  /// In en, this message translates to:
  /// **'Iraq'**
  String get countryIraq;

  /// No description provided for @countryPalestine.
  ///
  /// In en, this message translates to:
  /// **'Palestine'**
  String get countryPalestine;

  /// No description provided for @countrySyria.
  ///
  /// In en, this message translates to:
  /// **'Syria'**
  String get countrySyria;

  /// No description provided for @countryYemen.
  ///
  /// In en, this message translates to:
  /// **'Yemen'**
  String get countryYemen;

  /// No description provided for @countryAlgeria.
  ///
  /// In en, this message translates to:
  /// **'Algeria'**
  String get countryAlgeria;

  /// No description provided for @countryMorocco.
  ///
  /// In en, this message translates to:
  /// **'Morocco'**
  String get countryMorocco;

  /// No description provided for @countryTunisia.
  ///
  /// In en, this message translates to:
  /// **'Tunisia'**
  String get countryTunisia;

  /// No description provided for @countryLibya.
  ///
  /// In en, this message translates to:
  /// **'Libya'**
  String get countryLibya;

  /// No description provided for @countrySudan.
  ///
  /// In en, this message translates to:
  /// **'Sudan'**
  String get countrySudan;

  /// No description provided for @countryMauritania.
  ///
  /// In en, this message translates to:
  /// **'Mauritania'**
  String get countryMauritania;

  /// No description provided for @countryTurkey.
  ///
  /// In en, this message translates to:
  /// **'Turkey'**
  String get countryTurkey;

  /// No description provided for @countryUSA.
  ///
  /// In en, this message translates to:
  /// **'United States'**
  String get countryUSA;

  /// No description provided for @countryCanada.
  ///
  /// In en, this message translates to:
  /// **'Canada'**
  String get countryCanada;

  /// No description provided for @countryUK.
  ///
  /// In en, this message translates to:
  /// **'United Kingdom'**
  String get countryUK;

  /// No description provided for @countryFrance.
  ///
  /// In en, this message translates to:
  /// **'France'**
  String get countryFrance;

  /// No description provided for @countryGermany.
  ///
  /// In en, this message translates to:
  /// **'Germany'**
  String get countryGermany;

  /// No description provided for @countrySpain.
  ///
  /// In en, this message translates to:
  /// **'Spain'**
  String get countrySpain;

  /// No description provided for @countryItaly.
  ///
  /// In en, this message translates to:
  /// **'Italy'**
  String get countryItaly;

  /// No description provided for @countryIndia.
  ///
  /// In en, this message translates to:
  /// **'India'**
  String get countryIndia;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results found.'**
  String get noResults;

  /// No description provided for @deleteFromHistory.
  ///
  /// In en, this message translates to:
  /// **'Remove from history'**
  String get deleteFromHistory;

  /// No description provided for @discoverPlaceIn.
  ///
  /// In en, this message translates to:
  /// **'Discover this place in'**
  String get discoverPlaceIn;

  /// No description provided for @openInApp.
  ///
  /// In en, this message translates to:
  /// **'Open it in Smart City Guide'**
  String get openInApp;

  /// No description provided for @citiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Cities'**
  String get citiesTitle;

  /// No description provided for @cityNablus.
  ///
  /// In en, this message translates to:
  /// **'Nablus'**
  String get cityNablus;

  /// No description provided for @cityRamallah.
  ///
  /// In en, this message translates to:
  /// **'Ramallah'**
  String get cityRamallah;

  /// No description provided for @cityJenin.
  ///
  /// In en, this message translates to:
  /// **'Jenin'**
  String get cityJenin;
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
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
