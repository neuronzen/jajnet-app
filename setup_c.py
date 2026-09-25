# ============ 1. Update pubspec.yaml ============
with open('pubspec.yaml') as f:
    pub = f.read()

if 'firebase_messaging' not in pub:
    pub = pub.replace(
        '  firebase_auth: ^4.20.0',
        '  firebase_auth: ^4.20.0\n  firebase_messaging: ^14.7.10',
    )
    print("1. firebase_messaging added")

if 'flutter_launcher_icons' not in pub:
    pub = pub.replace(
        '  flutter_lints: ^3.0.0',
        '  flutter_lints: ^3.0.0\n  flutter_launcher_icons: ^0.13.1',
    )
    print("2. flutter_launcher_icons added")

if 'flutter_launcher_icons:' not in pub:
    pub = pub.rstrip() + """

flutter_launcher_icons:
  android: true
  ios: false
  image_path: "assets/icon/app_icon.png"
  adaptive_icon_background: "#FF7A1A"
  adaptive_icon_foreground: "assets/icon/app_icon.png"
  min_sdk_android: 21
"""
    print("3. launcher_icons config added")

with open('pubspec.yaml', 'w') as f:
    f.write(pub)

# ============ 2. Update build.yml ============
with open('.github/workflows/build.yml') as f:
    yml = f.read()

old_perm = '<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>'
new_perm = '''<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
              <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>'''

if 'POST_NOTIFICATIONS' not in yml:
    yml = yml.replace(old_perm, new_perm, 1)
    print("4. POST_NOTIFICATIONS permission added")

old_step = """      - name: Flutter pub get
        run: flutter pub get"""

new_step = """      - name: Setup Image Tools
        run: sudo apt-get update -qq && sudo apt-get install -y -qq imagemagick librsvg2-bin

      - name: Generate App Icon
        run: |
          mkdir -p assets/icon
          cat > /tmp/icon.svg << 'ENDSVG'
          <svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">
            <defs>
              <linearGradient id="g" x1="0%" y1="0%" x2="100%" y2="100%">
                <stop offset="0%" stop-color="#FF9F5A"/>
                <stop offset="55%" stop-color="#FF6B00"/>
                <stop offset="100%" stop-color="#E55A00"/>
              </linearGradient>
            </defs>
            <rect width="1024" height="1024" rx="230" ry="230" fill="url(#g)"/>
            <g transform="translate(512,490)" fill="none" stroke="#FFFFFF" stroke-width="72" stroke-linecap="round">
              <path d="M -250 -55 Q 0 -290 250 -55"/>
              <path d="M -160 40 Q 0 -150 160 40"/>
              <path d="M -80 130 Q 0 -30 80 130"/>
            </g>
            <circle cx="512" cy="720" r="48" fill="#FFFFFF"/>
          </svg>
          ENDSVG
          sed -i 's/^          //' /tmp/icon.svg
          rsvg-convert -w 1024 -h 1024 /tmp/icon.svg -o assets/icon/app_icon.png
          ls -lh assets/icon/

      - name: Flutter pub get
        run: flutter pub get

      - name: Generate Launcher Icons
        run: dart run flutter_launcher_icons"""

if 'Generate App Icon' not in yml:
    yml = yml.replace(old_step, new_step, 1)
    print("5. Icon generation step added")

with open('.github/workflows/build.yml', 'w') as f:
    f.write(yml)

print("DONE")
