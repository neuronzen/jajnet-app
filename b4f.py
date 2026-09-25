with open('lib/login.dart') as f:
    c = f.read()

# After successful login, check user status before navigating to MainShell
old = """      await AuthService.signIn(_email.text.trim(), _pass.text);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
      );"""

new = """      await AuthService.signIn(_email.text.trim(), _pass.text);
      if (!mounted) return;

      // Check if customer account is active
      final data = await AuthService.getUserData();
      final status = (data?['status'] ?? 'active').toString().toLowerCase();

      if (status == 'suspended' || status == 'deleted') {
        await AuthService.signOut();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'আপনার সংযোগ বন্ধ রয়েছে। সাপোর্টে যোগাযোগ করুন: ${AppInfo.helpline}',
              style: GoogleFonts.hindSiliguri(height: 1.5),
            ),
            backgroundColor: JC.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 6),
          ),
        );
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
      );"""

if old in c and 'সংযোগ বন্ধ' not in c:
    c = c.replace(old, new, 1)
    print("✓ Suspended user handling added")
else:
    print("✗ Pattern not matched or already exists")

with open('lib/login.dart', 'w') as f:
    f.write(c)
print("DONE")
