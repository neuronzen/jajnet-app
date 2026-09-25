with open('lib/dashboard_v2.dart') as f:
    c = f.read()

# Match the actual indentation (2 spaces, not 16)
old_block = """                Text(
                  '৳ ${NumberFormat('#,##0').format(due)}',
                  style: GoogleFonts.poppins(
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.3),
                ),"""

new_block = """                Text(
                  '৳ ${NumberFormat('#,##0').format(due)}',
                  style: GoogleFonts.poppins(
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.3),
                ),
                if ((_user?['monthlyDiscount'] ?? 0) is num &&
                    (_user?['monthlyDiscount'] ?? 0) > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    '🎁 ডিসকাউন্ট: ৳${_user?['monthlyDiscount']}/মাস',
                    style: GoogleFonts.hindSiliguri(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.5),
                  ),
                ],"""

if old_block in c:
    c = c.replace(old_block, new_block, 1)
    print("✓ Discount display added (matched)")
elif 'Text(\n  \'৳ ${NumberFormat(\'#,##0\').format(due)}\',' in c:
    print("Found 2-space indented version — using that")
    old_block2 = """Text(
  '৳ ${NumberFormat('#,##0').format(due)}',
  style: GoogleFonts.poppins(
      fontSize: 40,
      fontWeight: FontWeight.w700,
      color: Colors.white,
      height: 1.3),
),"""
    new_block2 = """Text(
  '৳ ${NumberFormat('#,##0').format(due)}',
  style: GoogleFonts.poppins(
      fontSize: 40,
      fontWeight: FontWeight.w700,
      color: Colors.white,
      height: 1.3),
),
if ((_user?['monthlyDiscount'] ?? 0) is num && (_user?['monthlyDiscount'] ?? 0) > 0)
  Padding(
    padding: const EdgeInsets.only(top: 2),
    child: Text(
      '🎁 ডিসকাউন্ট: ৳${_user?['monthlyDiscount']}/মাস',
      style: GoogleFonts.hindSiliguri(
          fontSize: 12,
          color: Colors.white.withOpacity(0.9),
          height: 1.5),
    ),
  ),"""
    if old_block2 in c:
        c = c.replace(old_block2, new_block2, 1)
        print("✓ Discount added via 2-space pattern")
    else:
        print("✗ 2-space pattern not matched")
else:
    print("✗ Still not matched")

with open('lib/dashboard_v2.dart', 'w') as f:
    f.write(c)

# Verify
check = open('lib/dashboard_v2.dart').read()
print(f"Discount present: {'ডিসকাউন্ট' in check}")
print("DONE")
