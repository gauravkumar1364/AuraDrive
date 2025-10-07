// Map Style Configuration
class MapStyle {
  // Mapbox configuration
  static const String mapboxAccessToken =
      'YOUR_MAPBOX_ACCESS_TOKEN'; // Replace with your token

  // Google Maps-like style for Mapbox
  static const String mapboxStyle =
      'mapbox://styles/mapbox/navigation-night-v1';

  // Alternative tile servers
  static const List<String> mapTileServers = [
    // OpenStreetMap default
    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',

    // Thunderforest Maps (requires API key)
    // 'https://tile.thunderforest.com/transport/{z}/{x}/{y}.png', // Transport style
    // 'https://tile.thunderforest.com/atlas/{z}/{x}/{y}.png',     // Atlas style

    // Stamen Maps
    'https://stamen-tiles.a.ssl.fastly.net/toner/{z}/{x}/{y}.png', // High contrast B&W
    'https://stamen-tiles.a.ssl.fastly.net/terrain/{z}/{x}/{y}.png', // Terrain style
    // CartoDB
    'https://cartodb-basemaps-a.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png', // Light style
    'https://cartodb-basemaps-a.global.ssl.fastly.net/dark_all/{z}/{x}/{y}.png', // Dark style
  ];

  // Map styling options
  static const mapOptions = {
    'version': 8,
    'sources': {
      'osm': {
        'type': 'raster',
        'tiles': [
          'https://cartodb-basemaps-a.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png',
        ],
        'tileSize': 256,
        'attribution': '© OpenStreetMap contributors, © CartoDB',
      },
    },
    'layers': [
      {
        'id': 'osm',
        'type': 'raster',
        'source': 'osm',
        'minzoom': 0,
        'maxzoom': 22,
      },
    ],
  };

  // Custom map appearance settings
  static const mapCustomization = {
    'water': '#a4dded', // Water bodies color
    'parks': '#c8df9f', // Parks and green areas
    'buildings': '#d9d0c9', // Building colors
    'roads': '#ffffff', // Road color
    'mainRoads': '#f7c59f', // Main roads
    'highways': '#f7c59f', // Highways
    'labels': '#666666', // Text labels
    'landuse': '#f2f2f2', // General land use
    'transit': '#dd8829', // Transit lines
  };
}
