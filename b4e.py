with open('lib/invoice.dart') as f:
    c = f.read()

# Add monthlyDiscount fetch from user
old = "final previousDue = (widget.payment['dueBefore'] ?? 0) as int;"
new = """final previousDue = (widget.payment['dueBefore'] ?? 0) as int;
    final monthlyDiscount = ((widget.user['monthlyDiscount'] ?? 0) as num).toInt();"""

if old in c and 'monthlyDiscount' not in c.split('final previousDue')[1].split('\n')[0]:
    c = c.replace(old, new, 1)
    print("1. monthlyDiscount variable added")

# Update the amount calculation to subtract discount
old_total = "final subtotal = previousDue + widget.monthlyPrice * widget.months;"
new_total = "final grossAmount = widget.monthlyPrice * widget.months;\n    final subtotal = previousDue + grossAmount - monthlyDiscount;"

if old_total in c:
    c = c.replace(old_total, new_total, 1)
    print("2. Subtotal calculation: discount subtracted")

# Add discount line in Items section
old_items = """_itemLine('Internet Package — ${widget.user['package'] ?? ''}',
                                '৳${widget.monthlyPrice * widget.months}'),
                            _itemLine('Previous Due', '৳$previousDue'),
                            _itemLine('Discount', '৳0'),"""

new_items = """_itemLine('Internet Package — ${widget.user['package'] ?? ''}',
                                '৳$grossAmount'),
                            _itemLine('Previous Due', '৳$previousDue'),
                            if (monthlyDiscount > 0)
                              _itemLine('Discount', '- ৳$monthlyDiscount'),"""

if old_items in c:
    c = c.replace(old_items, new_items, 1)
    print("3. Discount line in items section")

# Update summary Total - remove the "Discount ৳0" line, add real discount
old_summary = """_totalLine('Subtotal', '৳$subtotal'),
                            _totalLine('Discount', '৳0'),
                            _totalLine('Paid', '৳$paid'),"""

new_summary = """_totalLine('Subtotal', '৳$grossAmount'),
                            if (monthlyDiscount > 0)
                              _totalLine('Discount', '- ৳$monthlyDiscount'),
                            if (previousDue > 0)
                              _totalLine('Previous Due', '৳$previousDue'),
                            _totalLine('Total', '৳$subtotal'),
                            _totalLine('Paid', '৳$paid'),"""

if old_summary in c:
    c = c.replace(old_summary, new_summary, 1)
    print("4. Summary section: full breakdown")

with open('lib/invoice.dart', 'w') as f:
    f.write(c)

check = open('lib/invoice.dart').read()
print(f"\nmonthlyDiscount present: {'monthlyDiscount' in check}")
print(f"grossAmount present: {'grossAmount' in check}")
print("DONE")
