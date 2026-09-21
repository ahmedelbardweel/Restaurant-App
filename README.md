# 🍽️ Restaurant App

تطبيق Flutter لإدارة المطاعم - يدعم نظام المطعم والزبون والأدمن.

---

## 🍎 بناء iOS IPA عبر GitHub Actions

### الخطوات:

**1. ارفع الكود على GitHub:**
```bash
git add .
git commit -m "Add GitHub Actions iOS build"
git push origin main
```

**2. ابدأ البناء يدوياً (اختياري):**
- اذهب إلى `Actions` في مستودعك على GitHub
- اختر `🍎 Build iOS IPA`
- اضغط `Run workflow`

**3. حمّل الـ IPA:**
- بعد اكتمال البناء، اذهب إلى الـ `Run` المكتمل
- اسحب إلى أسفل إلى قسم `Artifacts`
- حمّل ملف `RestaurantApp-IPA`

---

## ⚠️ تثبيت الـ IPA على iPhone

| الطريقة | الوصف | المتطلبات |
|---|---|---|
| **AltStore** | مجاني، بدون جيلبريك | Apple ID مجاني |
| **Sideloadly** | سهل وبسيط | Apple ID مجاني |
| **Apple TestFlight** | رسمي من Apple | اشتراك Developer $99/سنة |

> 💡 **للتثبيت بدون Developer Account:**
> حمّل [Sideloadly](https://sideloadly.io) على جهاز Mac أو Windows، ثم اسحب ملف IPA إليه مع تثبيت جهازك بالكمبيوتر.

---

## 🔧 متطلبات التطوير

- Flutter `^3.32.0`
- Dart `^3.11.0`
- Xcode 15+ (لبناء iOS)
- Supabase Account

## 📱 الميزات

- 🏪 لوحة تحكم المطعم (إضافة أطباق، إدارة الطلبات)
- 👤 واجهة الزبون (تصفح المنيو، إضافة للسلة)
- 🛡️ لوحة الأدمن (إدارة المطاعم)
- 📸 رفع صور الأطباق عبر Supabase Storage
- 🎨 تصميم احترافي مع ألوان الشعار الخاص بكل مطعم
