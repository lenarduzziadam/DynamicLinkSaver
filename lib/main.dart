import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Starbucks Hub Link',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 76, 170, 175),
        title: const Text('Link Storing'),
      ),
      body: Stack(
        children:  [ 
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Center(
            child: Column(
              children: [
                const SizedBox(height: 50),
                customButton('https://partnercentral.starbucks.com', 'Open Starbucks Hub', Colors.green, const Color.fromARGB(255, 229, 224, 224)),
                const SizedBox(height: 30),
                customButton('https://paws.uwm.edu/signin.html', 'Open Paws', const Color.fromARGB(255, 210, 178, 33), const Color.fromARGB(255, 0, 0, 0)),
                const SizedBox(height: 30),
                customButton('https://uwmil.instructure.com/login/saml/15', 'Open Canvas', const Color.fromARGB(255, 233, 232, 228), const Color.fromARGB(255, 195, 94, 94)),
                const SizedBox(height: 30),
                customButton('https://docs.google.com/', 'Open Google Docs', const Color.fromARGB(255, 10, 87, 194), const Color.fromARGB(255, 254, 254, 254)),
                const SizedBox(height: 30),
                customButton('https://github.com', 'Open GitHub', const Color.fromARGB(255, 0, 0, 0), const Color.fromARGB(255, 255, 255, 255)),
                const SizedBox(height: 30),
                customButton('https://www.reddit.com/r/programming/', 'Open Programming Reddit', const Color.fromARGB(255, 255, 69, 0), const Color.fromARGB(255, 255, 255, 255)),
                const SizedBox(height: 30),
                customButton('https://outlook.office.com/mail', 'Open Outlook Email', const Color.fromARGB(255, 10, 138, 189), const Color.fromARGB(255, 206, 233, 243)),
                const SizedBox(height: 30),
                customButton('https://www.linkedin.com/', 'Open LinkedIn', const Color.fromARGB(255, 8, 102, 180), const Color.fromARGB(255, 255, 255, 255)),
              ],
            ),
        ),
      ],
    ),
  );
}

  void _launchURL(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
    }
  }

  Widget customButton(String url, String text, Color backgroundColor, Color foregroundColor) {
    return ElevatedButton(
      onPressed: () => _launchURL(url),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        elevation: 5,
      ),
      child: Text(text),
    );
  }

}
