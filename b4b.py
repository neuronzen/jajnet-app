with open('lib/payment_screen.dart') as f:
    c = f.read()

# Add monthlyDiscount state variable
old_state = "int _packagePrice = 500;"
new_state = "int _packagePrice = 500;\n            int _monthlyDiscount = 0;"

if old_state in c and '_monthlyDiscount' not in c:
    c = c.replace(old_state, new_state, 1)
    print("1. monthlyDiscount state added")
else:
    print("1. State pattern not matched or exists")

# Load discount from user
old_load = "                  _packagePrice = _toInt(d['packagePrice'], 500);"
new_load = "                  _packagePrice = _toInt(d['packagePrice'], 500);\n                  _monthlyDiscount = _toInt(d['monthlyDiscount'], 0);"

if old_load in c and '_monthlyDiscount = _toInt' not in c:
    c = c.replace(old_load, new_load, 1)
    print("2. Discount loading added")
else:
    print("2. Load pattern not matched or exists")

# Update total amount calculation
old_total = "int get _totalAmount => _months * _packagePrice;"
new_total = "int get _effectivePrice => (_packagePrice - _monthlyDiscount).clamp(0, 999999);\n            int get _totalAmount => _months * _effectivePrice;"

if old_total in c and '_effectivePrice' not in c:
    c = c.replace(old_total, new_total, 1)
    print("3. Effective price getter added")
else:
    print("3. Total pattern not matched or exists")

with open('lib/payment_screen.dart', 'w') as f:
    f.write(c)

# Check syntax roughly
check = open('lib/payment_screen.dart').read()
print(f"Effective price present: {'_effectivePrice' in check}")
print(f"Discount state present: {'_monthlyDiscount' in check}")
print("DONE")
