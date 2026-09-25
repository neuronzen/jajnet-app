with open('lib/payment_screen.dart') as f:
    c = f.read()

# Find where amounts are displayed (in _infoRow or similar)
# Look for _amountCard or total display
import re

# Find the amount display section
if '_monthlyDiscount > 0' not in c:
    # Add a discount line to _infoRow section
    old_info = "_infoRow('মাসিক বিল', '৳$_packagePrice'),"
    new_info = """_infoRow('মাসিক বিল', '৳$_packagePrice'),
                      if (_monthlyDiscount > 0)
                        _infoRow('ডিসকাউন্ট', '- ৳$_monthlyDiscount',
                            highlight: true, green: true),"""
    
    if old_info in c:
        c = c.replace(old_info, new_info, 1)
        print("1. Discount row added to info section")
    else:
        print("1. Info row pattern not matched")

# Update _infoRow to support green color
old_row = """Widget _infoRow(String label, String value, {bool highlight = false}) {"""
new_row = """Widget _infoRow(String label, String value,
      {bool highlight = false, bool green = false}) {"""
if old_row in c:
    c = c.replace(old_row, new_row, 1)
    print("2. _infoRow green param added")

# Update color logic
old_color = "color: highlight ? JC.error : JC.ink,"
new_color = "color: green ? JC.success : (highlight ? JC.error : JC.ink),"
if old_color in c:
    c = c.replace(old_color, new_color, 1)
    print("3. Color logic updated")

with open('lib/payment_screen.dart', 'w') as f:
    f.write(c)
print("DONE")
