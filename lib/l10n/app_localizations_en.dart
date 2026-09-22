// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Restaurant App';

  @override
  String get loginTitle => 'Welcome Back';

  @override
  String get loginSubtitle => 'Login to your account';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get loginButton => 'Login';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get registerHere => 'Register Here';

  @override
  String get registerTitle => 'Create Account';

  @override
  String get registerSubtitle => 'Sign up to get started';

  @override
  String get name => 'Full Name';

  @override
  String get registerButton => 'Register';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get loginHere => 'Login Here';

  @override
  String get menu => 'Menu';

  @override
  String get add => 'Add';

  @override
  String get orders => 'Orders';

  @override
  String get profile => 'Profile';

  @override
  String get home => 'Home';

  @override
  String get cart => 'Cart';

  @override
  String get addCategory => 'Add Category';

  @override
  String get emptyMenu => 'Your menu is empty.';

  @override
  String get noItemsInCategory => 'No items in this category.';

  @override
  String get addImages => 'Add Images';

  @override
  String get images => 'Images';

  @override
  String get language => 'Language';

  @override
  String get arabic => 'Arabic';

  @override
  String get english => 'English';

  @override
  String get logout => 'Logout';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get createCategory => 'Create Category';

  @override
  String get itemNameAr => 'Item Name (Arabic)';

  @override
  String get itemNameEn => 'Item Name (English)';

  @override
  String get categoryNameAr => 'Category Name (Arabic)';

  @override
  String get categoryNameEn => 'Category Name (English)';

  @override
  String get descAr => 'Description (Arabic)';

  @override
  String get descEn => 'Description (English)';

  @override
  String get price => 'Price (e.g. 10.99)';

  @override
  String get addMenuItem => 'Add Menu Item';

  @override
  String get itemAddedSuccessfully => 'Item added successfully!';

  @override
  String get categoryAddedSuccessfully => 'Category added successfully!';

  @override
  String get deleteCategory => 'Delete Category';

  @override
  String get deleteCategoryConfirm =>
      'Are you sure you want to delete this category? This will delete all its items too.';

  @override
  String get deleteItem => 'Delete Item';

  @override
  String get deleteItemConfirm => 'Are you sure you want to delete this item?';

  @override
  String get close => 'Close';

  @override
  String get customerAppTitle => 'Find Your Favorite Food';

  @override
  String get categories => 'Categories';

  @override
  String get popularRestaurants => 'Popular Restaurants';

  @override
  String get settings => 'Settings';

  @override
  String get restaurants => 'Restaurants';

  @override
  String get noRestaurants => 'No restaurants found.';

  @override
  String get restaurantProfile => 'Restaurant Profile';

  @override
  String get restaurantName => 'Restaurant Name';

  @override
  String get restaurantAddress => 'Restaurant Address';

  @override
  String get restNameAr => 'Restaurant Name (Arabic)';

  @override
  String get restNameEn => 'Restaurant Name (English)';

  @override
  String get restDescAr => 'Description (Arabic)';

  @override
  String get restDescEn => 'Description (English)';

  @override
  String get phone => 'Phone Number';

  @override
  String get addressAr => 'Address (Arabic)';

  @override
  String get addressEn => 'Address (English)';

  @override
  String get primaryColor => 'Primary';

  @override
  String get secondaryColor => 'Secondary';

  @override
  String get saving => 'Saving...';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String selectColor(String label) {
    return 'Select $label Color';
  }

  @override
  String get profileUpdatedSuccessfully => 'Profile updated successfully!';

  @override
  String errorUpdatingProfile(String error) {
    return 'Error updating profile: $error';
  }

  @override
  String couldNotGetLocation(String error) {
    return 'Could not get location: $error';
  }

  @override
  String get notLoggedIn => 'Not Logged In';

  @override
  String get signInToManageProfile =>
      'Sign in to manage your profile and orders.';

  @override
  String get signIn => 'Sign In';

  @override
  String get changeLanguageDesc =>
      'Change the application language between Arabic and English';

  @override
  String get or => 'OR';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get dontHaveAccountSignUp => 'Don\'t have an account? Sign Up';

  @override
  String get alreadyHaveAccountSignIn => 'Already have an account? Sign In';

  @override
  String errorOccurred(String error) {
    return 'Error: $error';
  }

  @override
  String googleSignInFailed(String error) {
    return 'Google Sign-In failed: $error';
  }

  @override
  String get search => 'Search';

  @override
  String get noMenuAvailable => 'No menu available.';

  @override
  String get chooseRestaurant => 'Choose your restaurant';

  @override
  String get restaurantOwnerLogin => 'Restaurant Owner? Login Here';
}
