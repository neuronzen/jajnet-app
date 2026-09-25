with open('pubspec.yaml') as f:
    c = f.read()

# Check if assets section exists
if 'assets/fonts' not in c:
    # Find the flutter: section
    marker = "flutter:\n  uses-material-design: true"
    new_flutter = """flutter:
  uses-material-design: true
  assets:
    - assets/fonts/HindSiliguri-Regular.ttf
    - assets/fonts/HindSiliguri-Bold.ttf
    - assets/fonts/HindSiliguri-SemiBold.ttf"""
    
    if marker in c:
        c = c.replace(marker, new_flutter, 1)
        print("✓ Fonts added to pubspec")
    else:
        print("✗ flutter: marker not found")
        print("Looking for:")
        idx = c.find('flutter:')
        if idx > 0:
            print(repr(c[idx:idx+150]))
else:
    print("Already has assets/fonts")

with open('pubspec.yaml', 'w') as f:
    f.write(c)

# Verify
with open('pubspec.yaml') as f:
    check = f.read()
print(f"\nHindSiliguri mentions: {check.count('HindSiliguri')}")
print("DONE")
