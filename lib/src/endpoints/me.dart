// Copyright (c) 2019, chances, rinukkusu. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

part of spotify;

class Me extends EndpointPaging {
  @override
  String get _path => 'v1/me';

  Me(SpotifyApiBase api) : super(api);

  Future<User> get() async {
    final jsonString = await _api._get(_path);
    final map = json.decode(jsonString);

    return User.fromJson(map);
  }

  /// Endpoint /v1/me/following only supports "artist" type at the moment.
  /// needs 'user-follow-read' scope
  CursorPages<Artist> following(FollowingType type, [String after = '']) {
    // since 'artists' is the container, there is no
    // containerParse necessary. Adding json to make the
    // CursorPages-Object happy.
    return _getCursorPages('$_path/following?type=${type.key}',
        (json) => Artist.fromJson(json), 'artists', (json) => json);
  }

  /// Check if current user follow the provided artists. The output [bool]
  /// list is in the same order as the provided artist-id list
  Future<List<bool>> isFollowing(FollowingType type, List<String> ids) async {
    assert(ids.isNotEmpty, 'No user/artist id was provided');
    final jsonString = await _api._get(
        '$_path/following/contains?type=${type.key}&ids=${ids.join(",")}');
    final list = List.castFrom<dynamic, bool>(json.decode(jsonString));
    return list;
  }

  /// Follow provided users/artists\
  /// [type] - Type of Follow\
  /// [ids] - user/artist
  Future<void> follow(FollowingType type, List<String> ids) async {
    assert(ids.isNotEmpty, 'No user/artist id was provided');
    await _api._put("$_path/following?type=${type.key}&ids=${ids.join(",")}");
  }

  /// Unfollow already following users/artists\
  /// [type] - Type of Follow\
  /// [ids] - user/artist
  Future<void> unfollow(FollowingType type, List<String> ids) async {
    assert(ids.isNotEmpty, 'No user/artist id was provided');
    await _api
        ._delete("$_path/following?type=${type.key}&ids=${ids.join(",")}");
  }

  /// Get the object currently being played on the user’s Spotify account.
  Future<Player> currentlyPlaying(
      {List<CurrentlyPlayingType> types = CurrentlyPlayingType.all}) async {
    var type = types.map((type) => type.key).join(',');
    var queryMap = {'additional_types': type};
    var query = _buildQuery(queryMap);
    final jsonString =
        await _api._get('$_path/player/currently-playing?$query');

    if (jsonString.isEmpty) {
      return Player();
    }

    final map = json.decode(jsonString);
    return Player.fromJson(map);
  }

  /// Get tracks from the current user’s recently played tracks.
  /// Note: Currently doesn’t support podcast episodes.
  CursorPages<PlayHistory> recentlyPlayed(
      {int? limit, DateTime? after, DateTime? before}) {
    assert(after == null || before == null,
        'Cannot specify both after and before.');

    return _getCursorPages(
        '$_path/player/recently-played?' +
            _buildQuery({
              'limit': limit,
              'after': after?.millisecondsSinceEpoch,
              'before': before?.millisecondsSinceEpoch
            }),
        (json) => PlayHistory.fromJson(json));
  }

  /// Get the current user's top tracks.
  Future<Iterable<Track>> topTracks() async {
    final jsonString = await _api._get('$_path/top/tracks');
    final map = json.decode(jsonString);

    final items = map['items'] as Iterable<dynamic>;
    return items.map((item) => Track.fromJson(item));
  }

  /// Get the current user's top artists.
  Future<Iterable<Artist>> topArtists() async {
    final jsonString = await _api._get('$_path/top/artists');
    final map = json.decode(jsonString);

    final items = map['items'] as Iterable<dynamic>;
    return items.map((item) => Artist.fromJson(item));
  }

  /// Get information about a user’s available devices.
  Future<Iterable<Device>> devices() async {
    return _api._get('$_path/player/devices').then(_parseDeviceJson);
  }

  /// Start a new context or resume current playback on the user's
  /// active device.
  ///
  /// [deviceId] The id of the device this command is targeting.
  /// [contextUri] Spotify URI of the context to play. Valid contexts are
  /// albums, artists & playlists.
  /// [uris] A JSON array of the Spotify track URIs to play.
  Future<void> play({
    String? deviceId,
    String? contextUri,
    List<String>? uris,
  }) async {
    final json = <String, dynamic>{};

    if (contextUri != null) json['context_uri'] = contextUri;
    if (uris != null) json['uris'] = uris;

    await _api._put('$_path/player/play?device_id$deviceId', jsonEncode(json));
  }

  /// Get a list of shows saved in the current Spotify user’s library.
  Pages<Show> savedShows() {
    return _getPages('$_path/shows', (json) => Show.fromJson(json['show']));
  }

  /// gets current user's saved albums in pages
  Pages<AlbumSimple> savedAlbums() {
    return _getPages('v1/me/albums', (json) => Album.fromJson(json['album']));
  }

  /// Save albums for the current-user. It requires the
  /// `user-library-modify` scope of Spotify WebSDK\
  /// [ids] - the ids of the albums
  Future<void> saveAlbums(List<String> ids) async {
    assert(ids.isNotEmpty, 'No album ids were provided for saving');
    await _api._put('$_path/albums?ids=${ids.join(",")}');
  }

  /// Remove albums for the current-user. It requires the
  /// `user-library-modify` scope of Spotify WebSDK\
  /// [ids] - the ids of the albums
  Future<void> removeAlbums(List<String> ids) async {
    assert(ids.isNotEmpty, 'No album ids were provided for removing');
    await _api._delete('$_path/albums?ids=${ids.join(",")}');
  }

  /// Check if passed albums (ids) are saved by current user. The output
  /// [bool] list is in the same order as the provided album ids list
  Future<List<bool>> isSavedAlbums(List<String> ids) async {
    assert(ids.isNotEmpty, 'No album ids were provided for checking');
    final jsonString =
        await _api._get('$_path/albums/contains?ids=${ids.join(",")}');
    final list = List.castFrom<dynamic, bool>(json.decode(jsonString));
    return list;
  }

  Iterable<Device> _parseDeviceJson(String jsonString) {
    final map = json.decode(jsonString);

    final items = map['devices'] as Iterable<dynamic>;
    return items.map((item) => Device.fromJson(item));
  }
}

class FollowingType {
  final String _key;

  const FollowingType(this._key);

  String get key => _key;

  static const artist = FollowingType('artist');
  static const user = FollowingType('user');
}

class CurrentlyPlayingType {
  final String _key;

  const CurrentlyPlayingType(this._key);
  String get key => _key;

  static const track = CurrentlyPlayingType('track');
  static const episode = CurrentlyPlayingType('episode');
  static const all = [
    CurrentlyPlayingType.track,
    CurrentlyPlayingType.episode,
  ];
}
