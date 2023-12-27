# Jekyll MapLibre 

[![Gem Version](https://badge.fury.io/rb/jekyll-maplibre.svg)](https://badge.fury.io/rb/jekyll-maplibre)

Jekyll MapLibre is a Jekyll plugin that allows to easily display maps with [MapLibre GL JS](https://maplibre.org/). It is a fork of [Jekyll Maps](https://github.com/ayastreb/jekyll-maps) that uses Google Maps.

MapLibre GL JS is open source software and allows for self-hosted maps. Self-hosting become much easier with [PMTiles](https://docs.protomaps.com/pmtiles/), which is a single-file archive format for pyramids of tiled data that can be hosted on Github, Gitlab, Netlify, etc. and enables low-cost, zero-maintenance map applications.

Check out a Jekyll MapLibre [demo at blog.riemann.cc](https://blog.riemann.cc/projects/jekyll-maplibre)!

## Installation

1. Add the following to your site's `Gemfile`:


```ruby
gem 'jekyll-maplibre'
```

2. Add the following to your site's `_config.yml`:


```yml
plugins:
  - jekyll-maplibre
```

3. Also prepare configuration specific for `jekyll-maplibre` in your site's `_config.yml`:

```
maplibre:
  width:  600
  height: 400
  zoom:   10
  pmtiles: true
  style: false
  # if style is not set to an URL (Mapbox, MapTiler, OpenMapTiles), the following values are used
  sprite: /assets/maps/osm-liberty-sprites/osm-liberty
  glyphs: /assets/maps/fonts/{fontstack}/{range}.pbf
  layers: /assets/maps/OSM-Liberty-layers.json
  sources:
    openmaptiles: 
      type: vector
      url: pmtiles:///assets/maps/maptiler-osm-2020-02-10-v3.11-belgium_brussels.pmtiles
      attribution: © <a href='https://openstreetmap.org'>OpenStreetMap contributors</a>
    natural_earth_shaded_relief:
      attribution: Made with <a href='https://www.naturalearthdata.com/'>Natural Earth</a> data
      maxzoom: 6
      type: raster
      url: pmtiles:///assets/maps/natural_earth_2_shaded_relief.raster.pmtiles
      # uncomment tileSize and tiles for cloud CDN tiles
      # tileSize: 256
      # tiles:
      #   - "https://klokantech.github.io/naturalearthtiles/tiles/natural_earth_2_shaded_relief.raster/{z}/{x}/{y}.png"
```

4. Prepare assets to display maps with MapLibre GL JS:

The required assets depend on your specific map configuration. With cloud hosting (untested), it may be sufficient to only configure the `style` property above.

For self-hosted maps, you need to host and configure the following resources:

- **The source.** PMTiles covering the map area you need. Use `pmtiles convert input.mbtiles output.pmtiles` to convert your mbtiles from e.g. <https://data.maptiler.com/downloads/planet/>. More on `pmtiles` and extraction of custom areas at <https://docs.protomaps.com/guide/getting-started>.
- **The glyphs.** Font files in pbf format when using vector sources. Check out <https://github.com/openmaptiles/fonts/releases>.
- **The sprite.** Icons used when using vector sources.
- **The layers.** A map requires at least one layer. Layers describe how to render source data and rely on glyphs and sprite. The layer definition for vector data depends on the schema used to encode the data in the vector source.
- **The Mapbox Style file.** It links all assets together.

For an easy start `jekyll-maplibre` suggests to use PMTiles raster files and vector files following the *OpenMapTiles Vector Tile Schema*, so that the layers from [OSM-Liberty](https://maputnik.github.io/osm-liberty/) can be used. Find a demo of OSM Liberty [here](https://maputnik.github.io/editor/?style=https://maputnik.github.io/osm-liberty/style.json).

Example assets folder:

```
assets
└── maps
    ├── fonts
    │   ├── Roboto Condensed Italic
    │   │   ├── 0-255.pbf
    │   │   ├── […]
    │   │   └── 9984-10239.pbf
    │   ├── Roboto Medium
    │   │   ├── 0-255.pbf
    │   │   ├── […]
    │   │   └── 9984-10239.pbf
    │   └── Roboto Regular
    │       ├── 0-255.pbf
    │       ├── […]
    │       └── 9984-10239.pbf
    ├── maplibre-gl.css
    ├── maplibre-gl.js
    ├── maptiler-osm-2020-02-10-v3.11-belgium_brussels.pmtiles
    ├── natural_earth_2_shaded_relief.raster.pmtiles
    ├── natural_earth.vector.pmtiles
    ├── OSM-Liberty-layers.json
    ├── osm-liberty-sprites
    │   ├── osm-liberty@2x.json
    │   ├── osm-liberty@2x.png
    │   ├── osm-liberty.json
    │   └── osm-liberty.png
    └── pmtiles.js

```

Example assets sources:

- [pmtiles.js](https://unpkg.com/pmtiles@2.11.0/dist/index.js)
- [osm-liberty-sprites](https://github.com/maputnik/osm-liberty/tree/gh-pages/sprites)
- [fonts](https://github.com/maputnik/osm-liberty/tree/gh-pages/sprites) (the v2.0 zip)
- [maplibre-gl.js](https://unpkg.com/maplibre-gl@3.6.2/dist/maplibre-gl.js)
- [maplibre-gl.css](https://unpkg.com/maplibre-gl@3.6.2/dist/maplibre-gl.css)
- [OSM-Liberty-layers.json extracted from OSM Liberty style.json](https://github.com/maputnik/osm-liberty/blob/f2c798e80dc11d47613e3b093881b4d37a5fde8e/style.json)

5. Load MapLibre GL JS CSS in `<head>`

The file `maplibre-gl.css` should be linked in your `<head>` or included in another css file.

Many Jeyll templates provide for a file `_includes/my-head.html` or `_includes/custom-head.html` (check the docs). If so, add a line such as `<link href="/assets/maps/maplibre-gl.css" rel="stylesheet">`.

## Usage

### MapLibre Tag

```
{% maplibre %}
```

The following optional attributes are supported:

- id
- width
- height
- class
- style
- zoom
- center
- description
- latitude
- longitude

The flag `no_cluster` can be used to disable clustering of points.

Example with all attributes and flags:

```
{% maplibre id="custom-id" width="100%" height="200" class="custom-class" style="clear: both;" zoom="10" center="4.300,50.800" description="<a href='#'>Popup Link</a>" longitude="4.300" latitude="50.800" no_cluster %}
```

### Data Source

Jekyll MapLibre offers several ways to add markers to the map. While in principle MapLibre GL JS allows to add all kinds of data other than markers to the map, more configuration must be added to the style definition.

#### Location data in the tag attributes

Example:

```
{% maplibre longitude="4.300" latitude="50.800" %}
```

#### Location data in the YAML frontmatter

```yml
location:
  latitude: 50.800
  longitude: 4.300
```

#### GeoJSON data in the YAML frontmatter

The `geojson` attribute in the YAML frontmatter supports (a) individual GeoJSON features or (b) collections of features.

Individual feature:

```
geojson:
  type: Feature
  properties:
    description: |
      <strong>A Little Night Music</strong><p>The Arlington Players' production of Stephen Sondheim's <em>A Little Night Music</em> comes to the Kogod Cradle at The Mead Center for American Theater (1101 6th Street SW) this weekend and next. 8:00 p.m.</p>
  geometry:
    type: Point
    coordinates: [4.300, 50.800]
```

Collection of features:

```
geojson:
  type: FeatureCollection
  features:
    -
      type: Feature
      properties:
        description: "<strong>A Little Night Music</strong><p>The Arlington Players' production of Stephen Sondheim's <em>A Little Night Music</em> comes to the Kogod Cradle at The Mead Center for American Theater (1101 6th Street SW) this weekend and next. 8:00 p.m.</p>\n"
      geometry:
        type: Point
        coordinates: [4.376, - 50.83012]
    -
      type: Feature
      ...
```

#### GeoJSON data in a JSON file

The `geojson` attribute in the YAML frontmatter can also contain a URL with `.json` extension.

Example:

```
geojson: /post-locations.json`
```

The linked file can be a static file on the same host or another server. If the data source points to a generated file capturing the `location` attribute of posts, Jekyll MapLibre can display maps with post markers.

Example for `/post-locations.json`:

```
{% assign posts = site.posts | where_exp:"location", "location != nil" %}
{
  "type": "FeatureCollection",
  "features": [
  {% for post in posts limit:20 %}
    {
      "type": "Feature",
      "properties": {
        "description": "<b><a href='{{post.url}}'>{{post.title}}</a></b><br/>{{post.description}}<br/>"
      },
      "geometry": {
        "type": "Point",
        "coordinates": {{post.location | jsonify }}
      }
    }{% unless forloop.last %},{% endif %}
  {% endfor %}
  ]
}
```

With `where` and `where_exp` (see [documentation](https://jekyllrb.com/docs/liquid/filters/)), Jekyll permits to implement various filters.

### Marker Cluster

Clusters are enabled by default. Use the flag `no_cluster` in the tag to disable clusters.

## Examples

Want to see Jekyll MapLibre in action? Check out [Demo Page](https://ayastreb.me/jekyll-maps/#examples)!

## Contributing

1. Fork it (https://github.com/rriemann/jekyll-maplibre/fork)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## TODOs

The following issues and limitation require contribution:

- implement random SVG markers, see: <https://github.com/maplibre/maplibre-gl-js/discussions/3243>, <https://github.com/rbrundritt/maplibre-gl-svg/>
- implement more than one map tag per page
- add more examples on how to generate geojson data from Jekyll collections/data.
- Jekyll-Maps has spec tests (still in this repo) – make them work again with Jekyll MapLibre
- add flag to switch popups to open by default (without click to open)

## Similar Software

- <https://github.com/ayastreb/jekyll-maps/>
- <https://github.com/matthewowen/jekyll-mapping>
- <https://wiki.openstreetmap.org/wiki/UMap>

## Contributors

- Anatoliy Yastreb (as the author of the forked Jekyll Maps gem)
- Robert Riemann

## License

[MIT](https://github.com/rriemann/jekyll-maplibre/blob/master/LICENSE). Feel free to use, copy or
distribute it.
