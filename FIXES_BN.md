# কাস্টমার অ্যাপ — কী কী ঠিক করা হয়েছে

> সতর্কতা: এই কোড Flutter দিয়ে compile করে দেখা হয়নি (এখানে Flutter নেই)। GitHub Actions এ build হলে যদি error আসে, error টা পাঠিয়ে দিলে ঠিক করে দেব।

## কোডে বদল
- **লগইন/সাইনআপের পর FCM token সেভ** হয় (`NotificationService.saveTokenForCurrentUser`)।
- **অ্যাপ খোলা অবস্থায় নোটিফিকেশন** এলে নিচে banner দেখায়, "দেখুন" চাপলে বিস্তারিত খোলে।
- **`as int` crash বন্ধ:** `lib/num_utils.dart` এর `asInt()` ব্যবহার করা হয়েছে (মান 525.0 হলেও চলবে)।
- **পাসওয়ার্ড ভুলে গেছেন?** লিংক যোগ হয়েছে (লগইন পেজে)।
- **সাইনআপে validation:** ইমেইল, মোবাইল নম্বর (01XXXXXXXXX), পাসওয়ার্ড ≥ ৬ অক্ষর। Firebase এর ইংরেজি error এর বদলে বাংলা বার্তা (`lib/auth_errors.dart`)।
- **সাইনআপে ডকুমেন্ট তৈরি ব্যর্থ হলে** Auth অ্যাকাউন্টটা মুছে যায় (ঝুলে থাকে না)।
- **TrxID:** কমপক্ষে ৬ অক্ষর, জমার সময় বড় হাতের অক্ষরে সেভ (ডুপ্লিকেট ধরা সহজ)।
- **অগ্রিম জমা:** বকেয়া নেগেটিভ হলে কার্ডে "অগ্রিম জমা আছে: ৳X" দেখায়।
- **ফন্ট:** HindSiliguri (Regular/SemiBold/Bold) এখন অ্যাপের ভেতরেই bundle (offline এ ঠিক থাকবে)। Medium ওজন ও Poppins এখনো ইন্টারনেট থেকে আসে।
- রুটের ১১টা পুরনো `.py` patch script মুছে ফেলা হয়েছে।

## Release signing (নতুন)
এতদিন প্রতিটা APK আলাদা debug key এ sign হতো, তাই গ্রাহক আপডেট দিতে পারত না। এখন নিজের key দিতে হবে — **একবারই**:

```bash
# Termux এ
pkg install openjdk-17
keytool -genkeypair -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
base64 -w0 upload-keystore.jks > keystore.b64.txt
```

GitHub → repo → Settings → Secrets and variables → Actions → **New repository secret**:

| নাম | মান |
|---|---|
| `KEYSTORE_BASE64` | `keystore.b64.txt` এর পুরো লেখা |
| `KEYSTORE_PASSWORD` | keytool এ দেওয়া keystore password |
| `KEY_ALIAS` | `upload` |
| `KEY_PASSWORD` | key password |

- `upload-keystore.jks` **কখনো repo তে push করবে না**, আর ফাইলটার একটা ব্যাকআপ নিরাপদ জায়গায় রাখো। হারালে আর আপডেট দেওয়া যাবে না।
- Secrets না দিলে আগের মতো debug key এ build হবে (কিছু ভাঙবে না)।
- নতুন key এ প্রথমবার যাওয়ার সময় গ্রাহকদের পুরনো অ্যাপ uninstall করে নতুনটা বসাতে হবে। এরপর থেকে সরাসরি আপডেট হবে।

## Firestore Rules
`firestore.rules` ফাইলটা Firebase Console → Firestore → Rules এ পেস্ট করে Publish করো।
এরপর টেস্ট: নতুন সাইনআপ, পেমেন্ট জমা, অ্যাডমিন থেকে Add Customer, পেমেন্ট verify।

## এখনো বাকি (এই zip এ করা হয়নি)
- প্যাকেজ ও bKash নম্বর অ্যাপে হার্ডকোড (Firestore থেকে নেওয়া ভালো)।
- `screens.dart` এ পুরনো ডুপ্লিকেট Login/Signup/Splash কোড।
- লগইন পেজের ভারী water অ্যানিমেশন (UI কাজের সময় দেখব)।
- সাইনআপে প্যাকেজ বাছাইয়ের UI নেই — সবাই ২০ Mbps/৫২৫ দিয়ে শুরু করে, অ্যাডমিন পরে বদলায়।
- `google-services.json` এর API key Google Cloud Console এ package name + SHA-1 দিয়ে restrict করো।
