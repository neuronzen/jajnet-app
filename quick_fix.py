import re

# ============ 1. pubspec — use padded icon ============
with open('pubspec.yaml') as f:
    pub = f.read()

new_icon_config = """flutter_launcher_icons:
  android: true
  ios: false
  image_path: "assets/icon/app_icon_padded.png"
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: "assets/icon/app_icon_padded.png"
  min_sdk_android: 21"""

# Replace existing config
pub = re.sub(
    r"flutter_launcher_icons:.*?(?=\n\S|\Z)",
    new_icon_config,
    pub,
    flags=re.DOTALL,
)

# Ensure padded icon in assets
if 'assets/icon/app_icon_padded.png' not in pub:
    if 'assets/logo/jajnet-logo.png' in pub:
        pub = pub.replace(
            "    - assets/logo/jajnet-logo.png",
            "    - assets/logo/jajnet-logo.png\n    - assets/icon/app_icon_padded.png",
            1,
        )

with open('pubspec.yaml', 'w') as f:
    f.write(pub)
print("1. ✓ pubspec: padded icon config")

# ============ 2. build.yml — add padding step using ImageMagick ============
with open('.github/workflows/build.yml') as f:
    yml = f.read()

pad_step = """      - name: Generate Padded App Icon
        run: |
          sudo apt-get update -qq
          sudo apt-get install -y -qq imagemagick
          mkdir -p assets/icon
          # Get max dimension and add 25% padding on white background
          W=$(identify -format "%w" assets/logo/jajnet-logo.png)
          H=$(identify -format "%h" assets/logo/jajnet-logo.png)
          MAX=$W
          if [ $H -gt $MAX ]; then MAX=$H; fi
          CANVAS=$((MAX * 125 / 100))
          convert assets/logo/jajnet-logo.png \\
            -resize ${MAX}x${MAX} \\
            -background white \\
            -gravity center \\
            -extent ${CANVAS}x${CANVAS} \\
            assets/icon/app_icon_padded.png
          echo "Original: ${W}x${H}"
          echo "Padded canvas: ${CANVAS}x${CANVAS}"
          ls -lh assets/icon/

"""

# Insert before "Flutter pub get" step
old = "      - name: Flutter pub get\n        run: flutter pub get"
new = pad_step + old

if old in yml and 'Generate Padded App Icon' not in yml:
    yml = yml.replace(old, new, 1)
    print("2. ✓ build.yml: padding step added")

with open('.github/workflows/build.yml', 'w') as f:
    f.write(yml)

# ============ 3. invoice.dart — WiFi → logo ============
with open('lib/invoice.dart') as f:
    inv = f.read()

old_wifi = """child: const Icon(Icons.wifi_rounded,
                                      color: Color(0xFFFF6B00),
                                      size: 20),"""

new_wifi = """child: Padding(
                                      padding: const EdgeInsets.all(5),
                                      child: Image.asset(
                                        'assets/logo/jajnet-logo.png',
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(
                                          Icons.wifi_rounded,
                                          color: Color(0xFFFF6B00),
                                          size: 20,
                                        ),
                                      ),
                                    ),"""

if old_wifi in inv:
    inv = inv.replace(old_wifi, new_wifi, 1)
    print("3. ✓ invoice.dart: logo applied")
else:
    # try single-line
    old_wifi2 = "child: const Icon(Icons.wifi_rounded, color: Color(0xFFFF6B00), size: 20),"
    if old_wifi2 in inv:
        inv = inv.replace(old_wifi2, new_wifi.replace('\n                                      ', ' '), 1)
        print("3. ✓ invoice.dart: logo applied (alt)")
    else:
        print("3. ✗ invoice.dart: wifi icon not found")

with open('lib/invoice.dart', 'w') as f:
    f.write(inv)

# ============ 4. dashboard_v2.dart — WiFi → logo in top right ============
with open('lib/dashboard_v2.dart') as f:
    dash = f.read()

# The dashboard has a small wifi icon in a container. Find it.
# Looking for: Icon(Icons.wifi_rounded, color: Colors.white, size: 24)
dashboard_wifi = "Icon(Icons.wifi_rounded, color: Colors.white, size: 24)"

if dashboard_wifi in dash:
    new_dash_icon = """Image.asset(
                          'assets/logo/jajnet-logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.wifi_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        )"""
    dash = dash.replace(dashboard_wifi, new_dash_icon, 1)
    print("4. ✓ dashboard_v2.dart: logo in header")
else:
    print("4. ✗ dashboard_v2.dart: wifi icon not found")

with open('lib/dashboard_v2.dart', 'w') as f:
    f.write(dash)

print("\nDONE")
