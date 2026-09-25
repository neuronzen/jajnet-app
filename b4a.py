with open('lib/dashboard_v2.dart') as f:
    c = f.read()

# ============ Add monthlyDiscount to state + display ============
# In _balanceCard, add discount display if exists

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

if old_block in c and 'ডিসকাউন্ট:' not in c:
    c = c.replace(old_block, new_block, 1)
    print("✓ Dashboard: discount display added")
else:
    print("✗ Dashboard pattern not matched or already added")

with open('lib/dashboard_v2.dart', 'w') as f:
    f.write(c)
print("DONE")
