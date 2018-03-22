import 'dart:convert';

import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;


void main() => runApp(new MyApp());

class FetchMoviesAction {}

class FetchMoviesSucceededAction {
  final List fetchedMovies;

  FetchMoviesSucceededAction(this.fetchedMovies);
}

class FetchMoviesFailedAction {
  final Exception error;

  FetchMoviesFailedAction(this.error);
}

class AppState {
  List movies;
  bool isFetching;
  Exception error;
  int page;

  AppState({
    this.movies = const [],
    this.isFetching = false,
    this.error,
    this.page = 1
  });
}

AppState moviesReducer(AppState state, action) {
  if (action is FetchMoviesAction) {
    return new AppState(
        movies: state.movies,
        isFetching: true,
        page: state.page + 1,
        error: null
    );
  } else if (action is FetchMoviesSucceededAction) {
    return new AppState(
        movies: action.fetchedMovies,
        isFetching: false,
        page: state.page,
        error: null
    );
  } else if (action is FetchMoviesFailedAction) {
    return new AppState(
        movies: const [],
        isFetching: false,
        error: action.error
    );
  }

  return state;
}

void fetchMoviesMiddleware(Store<AppState> store, action, NextDispatcher next) {
  if (action is FetchMoviesAction) {
    http.get(
      Uri.encodeFull(
          "https://api.themoviedb.org/3/movie/top_rated?api_key=2b02663ae5e6cb1370215e710a45e008&language=en-US&page=" +
              (store.state.page).toString()),
    ).then((response) {
      var jsonResponse;
      jsonResponse = JSON.decode(response.body);
      int page = jsonResponse['page'];
      print("Page : " + page.toString());
      print("PageCurrent : " + (store.state.page).toString());
      var movies = store.state.movies;
      var data = jsonResponse['results'];
      if (movies.length != 0)
        movies.addAll(data);
      else
        movies = data;
      store.dispatch(new FetchMoviesSucceededAction(movies));
    });
  }
  next(action);
}


class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Redux',
      theme: new ThemeData.dark(),
      home: new MyHomePage(),
    );
  }

}


class MyHomePage extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    final store = new Store(
      moviesReducer,
      initialState: new AppState(),
      middleware: [fetchMoviesMiddleware],
    );


//    print(store.state.isFetching);
//    print(store.state.movies);

//    print(store.state.isFetching);
//    print(store.state.movies);

    return new StoreProvider(
      store: store,
      child: new Scaffold(
        appBar: new AppBar(
            title: new Text("Flutter Redux")),
        body: new StoreConnector(
            builder: (context, todos) =>
            new ListView.builder(
              itemCount: todos == null ? 0 : todos.length,
              itemBuilder: (BuildContext context, int index) {
                return new Card(
                  child: new Container(
                    padding: new EdgeInsets.all(8.0),
                    decoration: new BoxDecoration(
                      color: new Color.fromRGBO(0, 0, 0, 0.2),
                      image: new DecorationImage(
                        image: new NetworkImage(
                            ("https://image.tmdb.org/t/p/w500/" +
                                todos[index]["backdrop_path"])),
                        fit: BoxFit.cover,
                        colorFilter: new ColorFilter.mode(
                            Colors.black.withOpacity(0.2), BlendMode.dstATop),
                      ),
                    ),
                    child: new Row(
                      children: <Widget>[
                        new Expanded(
                          child: new Column(
                            children: <Widget>[
                              new Image.network(
                                  ("https://image.tmdb.org/t/p/w500/" +
                                      todos[index]["poster_path"]),
                                  width: 100.0,
                                  alignment: Alignment.topLeft
                              ),
                              new Container(
                                padding: new EdgeInsets.only(top: 12.0),
                                child: new Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    new Icon(Icons.star, color: Colors.yellow,),
                                    new Text(
                                        todos[index]["vote_average"].toString())
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                        new Expanded(
                            child: new Container(
                              padding:
                              new EdgeInsets.all(5.0),
                              child: new Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  new Text(todos[index]["original_title"],
                                      style: new TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blueGrey,
                                          fontSize: 15.0)),
                                  new Text(
                                    todos[index]["overview"],
                                    softWrap: true,)
                                ],
                              ),
                            )
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            converter: (store) => store.state.movies),
        floatingActionButton: new StoreConnector(
            builder: (context, isFetching) =>
            new FloatingActionButton(
              onPressed: () {
                if (!store.state.isFetching) {
                  Scaffold.of(context).showSnackBar(
                    new SnackBar(
                      content: new Text("Fetching data for page " +
                          (store.state.page).toString()),
                      duration: new Duration(seconds: 1),
                    ),
                  );
                  store.dispatch(new FetchMoviesAction());
                }
              },
              tooltip: 'Get new movie data',
              child: isFetching ? new Icon(Icons.sync) : new Icon(
                  Icons.file_download),
            ),
            converter: (store) => store.state.isFetching),
      ),
    );
  }

}
