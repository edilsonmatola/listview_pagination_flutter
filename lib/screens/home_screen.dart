import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // *Fetching data from this Rest api
  final _baseUrl = 'https://jsonplaceholder.typicode.com/posts';

  // Fetching the first 20 posts
  int _page = 0;
  int _limit = 20;

  // The controller for the ListView
  late ScrollController _controller;

  // There is next page or not
  bool _hasNextPage = true;

  // Used to display loading indicators whn _firstLoad function is running
  bool _isFirstLoadRunning = true;

  // Used to display loading indicators when _loadMore function is rnning
  bool _isLoadMoreRunning = false;

  // *The list to hold the posts fetched from the server
  List _posts = [];

  // *This function will be called when the app launches (see the initState function)
  void _firstLoad() async {
    setState(() {
      _isFirstLoadRunning = true;
    });
    try {
      final res =
          await http.get(Uri.parse("$_baseUrl?_page=$_page&_limit=$_limit"));
      setState(() {
        _posts = json.decode(res.body);
      });
    } catch (err) {
      throw Exception('Something went wrong');
    }

    setState(() {
      _isFirstLoadRunning = false;
    });
  }

  // *This function will be triggered whenver the user scroll
  // to near the bottom of the list view
  void _loadMore() async {
    if (_hasNextPage == true &&
        _isFirstLoadRunning == false &&
        _isLoadMoreRunning == false &&
        _controller.position.extentAfter < 300) {
      setState(() {
        _isLoadMoreRunning = true; // Display a progress indicator at the bottom
      });
      _page += 1; // Increase _page by 1
      try {
        final res =
            await http.get(Uri.parse("$_baseUrl?_page=$_page&_limit=$_limit"));

        final List fetchedPosts = json.decode(res.body);
        if (fetchedPosts.isNotEmpty) {
          setState(() {
            _posts.addAll(fetchedPosts);
          });
        } else {
          // This means there is no more data
          // and therefore, we will not send another GET request
          setState(() {
            _hasNextPage = false;
          });
        }
      } catch (err) {
        throw Exception('Something went wrong!');
      }

      setState(() {
        _isLoadMoreRunning = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _firstLoad();
    _controller = ScrollController()..addListener(_loadMore);
  }

  @override
  void dispose() {
    _controller.removeListener(_loadMore);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Posts',
        ),
      ),
      body: _isFirstLoadRunning
          ? Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    physics: BouncingScrollPhysics(),
                    controller: _controller,
                    itemCount: _posts.length,
                    itemBuilder: (_, index) => Card(
                      color: Colors.grey.shade100,
                      margin: EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 10,
                      ),
                      child: ListTile(
                        title: Text(
                          _posts[index]['title'],
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(_posts[index]['body']),
                      ),
                    ),
                  ),
                ),
                // * When the  _loadMore function is running
                if (_isLoadMoreRunning)
                  Padding(
                    padding: EdgeInsets.only(
                      top: 10,
                      bottom: 40,
                    ),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                // TODO: Adicionar funcao para desaparecer a notificacao quando fazer um scroll up
                // *When nothing else to load
                if (_hasNextPage == false)
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height * .05,
                    child: Container(
                      color: Colors.black87,
                      child: Center(
                        child: Text(
                          'You have fetched all the content.',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  )
              ],
            ),
    );
  }
}
