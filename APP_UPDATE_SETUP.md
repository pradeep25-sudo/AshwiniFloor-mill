# अश्विनी खाता — GitHub Setup आणि APK Guide

**हे मार्गदर्शन त्यांच्यासाठी आहे ज्यांना coding येत नाही.**

---

## भाग 1: GitHub खाते तयार करणे

### पायरी 1 — GitHub वर नोंदणी करा
1. [github.com](https://github.com) उघडा
2. **Sign up** वर क्लिक करा
3. Email, Password, Username टाका
4. Email verify करा

### पायरी 2 — नवीन Repository तयार करा
1. लॉगिन केल्यावर उजव्या कोपऱ्यात **+** वर क्लिक करा
2. **New repository** निवडा
3. Repository name: `ashwini-khata`
4. **Public** निवडा (Free साठी)
5. **Create repository** दाबा

---

## भाग 2: प्रोजेक्ट फाइल्स Upload करणे

### GitHub Desktop वापरणे (सर्वात सोपे)

1. [desktop.github.com](https://desktop.github.com) वरून **GitHub Desktop** डाउनलोड करा
2. इन्स्टॉल करा आणि GitHub खात्याने लॉगिन करा
3. **Clone a repository** → `ashwini-khata` निवडा
4. Local folder: `C:\ashwini-khata` किंवा कुठेही
5. `ashwini_khata` folder मधील **सर्व फाइल्स** त्या local folder मध्ये copy करा
6. GitHub Desktop मध्ये:
   - **Summary**: `Initial commit - Ashwini Khata v1.0.0`
   - **Commit to main** दाबा
   - **Push origin** दाबा

### ✅ फाइल्स Upload झाल्या!

---

## भाग 3: APK आपोआप Build होणे

### Upload केल्यावर काय होते?
1. GitHub Actions **आपोआप सुरू होतो**
2. Flutter install होतो
3. APK तयार होतो
4. **Artifacts** मध्ये APK मिळतो

### APK कुठे मिळेल?

1. GitHub वर आपल्या `ashwini-khata` repository उघडा
2. वरती **Actions** tab वर क्लिक करा
3. **Build Ashwini Khata APK** वर क्लिक करा
4. सर्वात वरचा (Latest) build उघडा
5. खाली scroll करा → **Artifacts** section
6. **AshwiniKhata-APK-build...** वर क्लिक करा
7. ZIP फाइल डाउनलोड होईल

```
📁 AshwiniKhata-APK-build1.zip
   └── AshwiniKhata-v1.0.0-build1.apk  ← हीच APK इन्स्टॉल करा
```

---

## भाग 4: APK फोनवर इन्स्टॉल करणे

### पायरी 1 — Unknown Sources परवानगी द्या

**Android 8+ साठी:**
1. Settings → Apps → Special app access
2. Install unknown apps
3. Chrome किंवा File Manager निवडा → Allow

**Android 7 आणि जुन्यासाठी:**
1. Settings → Security
2. Unknown Sources → ON करा

### पायरी 2 — APK इन्स्टॉल करा
1. ZIP extract करा → APK फाइल मिळेल
2. APK फाइलवर tap करा
3. **Install** दाबा
4. **Open** दाबा → अॅप सुरू!

### पायरी 3 — पहिल्यांदा सुरू करताना
1. Microphone permission → **Allow** द्या
2. Camera permission → **Allow** द्या
3. Storage permission → **Allow** द्या

---

## भाग 5: अॅप Update करणे

### नवीन version आल्यावर:
1. नवीन APK डाउनलोड करा (वरील पद्धतीने)
2. **आधी बॅकअप घ्या:**
   - अॅप उघडा → Settings → बॅकअप एक्सपोर्ट करा
   - WhatsApp वर स्वतःला पाठवा किंवा Google Drive वर सेव्ह करा
3. नवीन APK Install करा
4. डेटा आपोआप safe राहतो

---

## सामान्य प्रश्न (FAQ)

### ❓ GitHub Actions मध्ये ❌ लाल दिसतो?
- Actions → Build वर क्लिक करा
- Error message वाचा
- Developer ला screenshot पाठवा

### ❓ APK Install होत नाही?
- Unknown Sources परत एकदा check करा
- Storage मध्ये जागा आहे का? (50 MB हवी)
- APK corrupt झाली असेल तर पुन्हा डाउनलोड करा

### ❓ आवाज ओळखत नाही?
- Internet connection तपासा
- हळू आणि स्पष्ट बोला
- मराठी असले तरी हाताने नोंद करता येते

### ❓ डेटा गेला?
- Settings → बॅकअप इम्पोर्ट करा
- आधी घेतलेला बॅकअप select करा

### ❓ Build किती वेळ लागतो?
- पहिल्यांदा: 8-12 मिनिटे
- नंतर (cache): 4-6 मिनिटे

---

## Developer शी संपर्क

अॅपमध्ये काही बदल हवे असल्यास किंवा अडचण आल्यास:
- GitHub Issues वर report करा
- Developer ला WhatsApp करा

---

## फाइल Structure संदर्भासाठी

GitHub वर upload करताना **या सर्व फाइल्स असाव्यात:**

```
ashwini-khata/
├── .github/
│   └── workflows/
│       └── build.yml          ← हे सर्वात महत्त्वाचे!
├── android/
├── assets/
├── lib/
├── pubspec.yaml
├── README.md
├── RELEASE.md
└── APP_UPDATE_SETUP.md
```

> ⚠️ `.github/workflows/build.yml` नसल्यास APK build होणार नाही!

---

*हे मार्गदर्शन Version 1.0.0 साठी आहे*
*अश्विनी खाता — तुमच्या गिरणीचे स्मार्ट हिशेब*
