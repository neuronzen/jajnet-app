with open('lib/payment_screen.dart') as f:
    c = f.read()

old = """      setState(() {
        _packagePrice = _toInt(d['packagePrice'], 500);
        _currentDue = _toInt(d['dueAmount'], 0);
        _packageName = (d['package'] ?? '20 Mbps').toString();
        _fetching = false;
      });"""

new = """      setState(() {
        _packagePrice = _toInt(d['packagePrice'], 500);
        _currentDue = _toInt(d['dueAmount'], 0);
        _monthlyDiscount = _toInt(d['monthlyDiscount'], 0);
        _packageName = (d['package'] ?? '20 Mbps').toString();
        _fetching = false;
      });"""

if old in c:
    c = c.replace(old, new, 1)
    print("✓ monthlyDiscount loaded in setState")
else:
    print("✗ Pattern not matched")

with open('lib/payment_screen.dart', 'w') as f:
    f.write(c)

check = open('lib/payment_screen.dart').read()
print(f"Discount load present: {'_monthlyDiscount = _toInt' in check}")
print("DONE")
