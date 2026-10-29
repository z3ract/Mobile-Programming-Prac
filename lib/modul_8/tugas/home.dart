// ignore_for_file: non_constant_identifier_names
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'screen_arguments.dart';
import 'tujuan.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String? title, thumbnail, short_description, description;
  String? genre, platform, release, cover, gameid, publisher;

  Future getGame(String gameid) async {
    try {
      final response = await http.get(
        Uri.parse('https://www.freetogame.com/api/game?id=$gameid'),
      );
      if (response.statusCode == 200) {
        var results = jsonDecode(response.body);
        setState(() {
          this.gameid = gameid;
          title = results['title'] ?? 'Forza Motorsport 6: Apex';
          thumbnail = results['thumbnail'] ??
              'https://www.freetogame.com/g/475/thumbnail.jpg';
          short_description = results['short_description'] ?? '';
          description = results['description'] ?? '';
          genre = results['genre'] ?? 'Racing';
          platform = results['platform'] ?? 'Windows';
          publisher = results['publisher'] ?? 'Microsoft';
          release = results['release_date'] ?? '2016-09-15';
          cover = (results['screenshots'] != null &&
                  results['screenshots'].isNotEmpty)
              ? results['screenshots'][0]['image']
              : thumbnail;
        });
      }
    } catch (e) {
      debugPrint('Error fetching game: $e');
      // Fallback data agar UI tetap tampil rapi
      setState(() {
        this.gameid = gameid;
        title = 'Forza Motorsport 6: Apex';
        thumbnail = 'https://www.freetogame.com/g/475/thumbnail.jpg';
        short_description =
            'Forza Motorsport 6: Apex is a free-to-play multiplayer online racing game.';
        description =
            'Forza Motorsport 6: Apex delivers a curated single-player tour of Forza Motorsport’s best content on Windows 10.';
        genre = 'Racing';
        platform = 'Windows';
        publisher = 'Microsoft';
        release = '2016-09-15';
        cover = 'https://www.freetogame.com/g/475/forza-motorsport-6-apex-1.jpg';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    getGame('475');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0081C9),
      body: SafeArea(
        child: Center(
          child: gameid == null
              ? const CircularProgressIndicator(color: Colors.white)
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        margin: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          children: [
                            Image.network(
                              thumbnail ?? '',
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.image, size: 80),
                            ),
                            const SizedBox(height: 15),
                            Text(
                              title ?? '',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Genre: $genre"),
                                    Text("Platform: $platform"),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Publisher: $publisher"),
                                    Text("Release: $release"),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          Tujuan.routeName,
                          arguments: ScreenArguments(
                            cover ?? '',
                            title ?? '',
                            description ?? '',
                            short_description ?? '',
                          ),
                        );
                      },
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
