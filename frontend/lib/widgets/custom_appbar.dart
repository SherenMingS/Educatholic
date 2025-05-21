import 'package:flutter/material.dart';

class CustomPageAppBar extends StatelessWidget implements PreferredSizeWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onBack;
  final bool showBack;

  const CustomPageAppBar({
    required this.icon,
    required this.title,
    this.onBack,
    this.showBack = true, // ✅ default tetap true, aman untuk halaman lain
    super.key,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.blue,
      elevation: 0,
      centerTitle: true,
      leading: showBack
          ? Padding(
              padding: const EdgeInsets.only(left: 12),
              child: InkWell(
                onTap: onBack ?? () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(6),
                  child: const Icon(Icons.arrow_back, color: Colors.blue),
                ),
              ),
            )
          : null, // ✅ Jika false, tidak menampilkan leading
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
