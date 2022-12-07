// Copyright (c) 2020, deandreamatias, rinukkusu. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

part of spotify;

class Episodes extends EndpointPaging {
  @override
  String get _path => 'v1/episodes';

  Episodes(SpotifyApiBase api) : super(api);

  /// Get a single episode
  ///
  /// [market]: An ISO 3166-1 alpha-2 country code or the string 'from_token'.
  /// If a country code is specified, only artists, albums, and tracks with
  /// content that is playable in that market is returned.
  Future<Episode> get(String episodeId, {String market = ''}) async {
    var jsonString;
    if (market.isNotEmpty) {
      var queryMap = {'market': market};
      var query = _buildQuery(queryMap);
      jsonString = await _get('$_path/$episodeId?$query');
    } else {
      jsonString = await _get('$_path/$episodeId');
    }

    var map = json.decode(jsonString);

    return Episode.fromJson(map);
  }

  /// Get one or several episodes
  Future<Iterable<Episode>> list(List<String> episodesId) async {
    final jsonString = await _get('$_path?ids=${episodesId.join(',')}');
    final map = json.decode(jsonString);

    final episodesMap = map['episodes'] as Iterable<dynamic>;
    return episodesMap.map((m) => Episode.fromJson(m));
  }
}
