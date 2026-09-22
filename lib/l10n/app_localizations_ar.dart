// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'تطبيق المطعم';

  @override
  String get loginTitle => 'مرحباً بعودتك !';

  @override
  String get loginSubtitle => 'قم بتسجيل الدخول لحسابك';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get loginButton => 'تسجيل الدخول';

  @override
  String get dontHaveAccount => 'لا تملك حساباً؟';

  @override
  String get registerHere => 'سجل هنا';

  @override
  String get registerTitle => 'إنشاء حساب';

  @override
  String get registerSubtitle => 'سجل لتبدأ';

  @override
  String get name => 'الاسم الكامل';

  @override
  String get registerButton => 'تسجيل';

  @override
  String get alreadyHaveAccount => 'لديك حساب بالفعل؟';

  @override
  String get loginHere => 'سجل الدخول هنا';

  @override
  String get menu => 'القائمة';

  @override
  String get add => 'إضافة';

  @override
  String get orders => 'الطلبات';

  @override
  String get profile => 'الحساب';

  @override
  String get home => 'الرئيسية';

  @override
  String get cart => 'السلة';

  @override
  String get addCategory => 'إضافة قسم';

  @override
  String get emptyMenu => 'القائمة فارغة.';

  @override
  String get noItemsInCategory => 'لا توجد عناصر في هذا القسم.';

  @override
  String get addImages => 'إضافة صور';

  @override
  String get images => 'الصور';

  @override
  String get language => 'اللغة';

  @override
  String get arabic => 'العربية';

  @override
  String get english => 'الإنجليزية';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get save => 'حفظ';

  @override
  String get cancel => 'إلغاء';

  @override
  String get delete => 'حذف';

  @override
  String get edit => 'تعديل';

  @override
  String get createCategory => 'إنشاء قسم';

  @override
  String get itemNameAr => 'اسم الوجبة (عربي)';

  @override
  String get itemNameEn => 'اسم الوجبة (إنجليزي)';

  @override
  String get categoryNameAr => 'اسم القسم (عربي)';

  @override
  String get categoryNameEn => 'اسم القسم (إنجليزي)';

  @override
  String get descAr => 'الوصف (عربي)';

  @override
  String get descEn => 'الوصف (إنجليزي)';

  @override
  String get price => 'السعر (مثال: 10.99)';

  @override
  String get addMenuItem => 'إضافة وجبة';

  @override
  String get itemAddedSuccessfully => 'تم إضافة الوجبة بنجاح!';

  @override
  String get categoryAddedSuccessfully => 'تم إضافة القسم بنجاح!';

  @override
  String get deleteCategory => 'حذف القسم';

  @override
  String get deleteCategoryConfirm =>
      'هل أنت متأكد من حذف هذا القسم؟ سيتم حذف جميع الوجبات التابعة له.';

  @override
  String get deleteItem => 'حذف الوجبة';

  @override
  String get deleteItemConfirm => 'هل أنت متأكد من حذف هذه الوجبة؟';

  @override
  String get close => 'إغلاق';

  @override
  String get customerAppTitle => 'اكتشف طعامك المفضل';

  @override
  String get categories => 'التصنيفات';

  @override
  String get popularRestaurants => 'مطاعم شهيرة';

  @override
  String get settings => 'الإعدادات';

  @override
  String get restaurants => 'المطاعم';

  @override
  String get noRestaurants => 'لم يتم العثور على مطاعم.';

  @override
  String get restaurantProfile => 'ملف المطعم';

  @override
  String get restaurantName => 'اسم المطعم';

  @override
  String get restaurantAddress => 'عنوان المطعم';

  @override
  String get restNameAr => 'اسم المطعم (عربي)';

  @override
  String get restNameEn => 'اسم المطعم (إنجليزي)';

  @override
  String get restDescAr => 'الوصف (عربي)';

  @override
  String get restDescEn => 'الوصف (إنجليزي)';

  @override
  String get phone => 'رقم الهاتف';

  @override
  String get addressAr => 'العنوان (عربي)';

  @override
  String get addressEn => 'العنوان (إنجليزي)';

  @override
  String get primaryColor => 'اللون الأساسي';

  @override
  String get secondaryColor => 'اللون الثانوي';

  @override
  String get saving => 'جاري الحفظ...';

  @override
  String get saveChanges => 'حفظ التغييرات';

  @override
  String selectColor(String label) {
    return 'اختر لون $label';
  }

  @override
  String get profileUpdatedSuccessfully => 'تم تحديث الملف بنجاح!';

  @override
  String errorUpdatingProfile(String error) {
    return 'خطأ في التحديث: $error';
  }

  @override
  String couldNotGetLocation(String error) {
    return 'لم نتمكن من تحديد الموقع: $error';
  }

  @override
  String get notLoggedIn => 'لم تقم بتسجيل الدخول';

  @override
  String get signInToManageProfile => 'سجل الدخول لإدارة حسابك وطلباتك.';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get changeLanguageDesc => 'تغيير لغة التطبيق بين العربية والإنجليزية';

  @override
  String get or => 'أو';

  @override
  String get continueWithGoogle => 'المتابعة باستخدام جوجل';

  @override
  String get dontHaveAccountSignUp => 'لا تملك حساباً؟ سجل الآن';

  @override
  String get alreadyHaveAccountSignIn => 'لديك حساب بالفعل؟ سجل الدخول';

  @override
  String errorOccurred(String error) {
    return 'خطأ: $error';
  }

  @override
  String googleSignInFailed(String error) {
    return 'فشل تسجيل الدخول بجوجل: $error';
  }

  @override
  String get search => 'البحث';

  @override
  String get noMenuAvailable => 'لا توجد قائمة متاحة.';

  @override
  String get chooseRestaurant => 'اختر مطعمك';

  @override
  String get restaurantOwnerLogin => 'صاحب مطعم؟ سجل دخولك هنا';
}
