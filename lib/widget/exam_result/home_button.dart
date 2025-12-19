import 'package:flutter/material.dart';
import '../../component/HomeNavigation.dart';

/// Widget nút về trang chủ
class HomeButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const HomeButton({Key? key, this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed:
            onPressed ??
            () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => HomeNavigation(),
                ),
                (Route<dynamic> route) => false,
              );
            },
        icon: Icon(Icons.home),
        label: Text(
          'Về trang chủ',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 14),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
