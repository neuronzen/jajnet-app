with open('pubspec.yaml') as f:
    pub = f.read()

# Check for the actual config block, not the package name
if 'image_path:' not in pub:
    pub = pub.rstrip() + """

flutter_launcher_icons:
  android: true
  ios: false
  image_path: "assets/icon/app_icon.png"
  adaptive_icon_background: "#FF7A1A"
  adaptive_icon_foreground: "assets/icon/app_icon.png"
  min_sdk_android: 21
"""
    with open('pubspec.yaml', 'w') as f:
        f.write(pub)
    print("✓ launcher_icons config added")
else:
    print("Already has config")

# Verify
check = open('pubspec.yaml').read()
print(f"image_path present: {'image_path:' in check}")
print(f"adaptive_icon_background present: {'adaptive_icon_background' in check}")
print("DONE")
