##
# copyright: 2020 Anatoliy Yastreb <anatoliy.yastreb@gmail.com>,
#            2023 Robert Riemann <robert@riemann.cc>
# license:   MIT
#
# original code from jekyll-maps, https://github.com/ayastreb/jekyll-maps/

require 'json'
require 'erb'

# taken from Active Support Gem (MIT license)
class Hash
  # File activesupport/lib/active_support/core_ext/hash/keys.rb, line 82
  def deep_transform_keys(&block)
    result = {}
    each do |key, value|
      result[yield(key)] = value.is_a?(Hash) ? value.deep_transform_keys(&block) : value
    end
    result
  end

  # File activesupport/lib/active_support/core_ext/hash/keys.rb, line 128
  def deep_symbolize_keys
    deep_transform_keys{ |key| key.to_sym rescue key }
  end
end

module Jekyll
  module MapLibre
    
    # @author Robert Riemann <robert@riemann.cc>
    class MapLibreTag < Liquid::Tag
      DEFAULT_MAP_WIDTH  = 600
      DEFAULT_MAP_HEIGHT = 400
      DEFAULT_ZOOM       = 10

      def initialize(tag_name, args, tokens)
        @options = OptionsParser.parse(args)
        super
      end

      # @return [String] HTML code with JS to render map with MapLibre GL
      def render(context)
        zoom = @options[:attributes][:zoom] || context.registers[:site].config.dig('maplibre', 'zoom') || DEFAULT_ZOOM
        
        @options[:attributes][:id] ||= "maplibre-#{SecureRandom.uuid}"
        
        # binding.irb
        template.result(binding)
      end
      
      private
      # @return [Object] ERB instance
      def template
        @@template ||= ERB.new File.read(File.expand_path("maplibre.html.erb", __dir__))
      end
      
      private
      # @return [String] absolute URL for sprite property pursuant to Mapbox Style Spec
      def sprite_url(context)
        # note: unlike glyphs, sprites must be an absolute path with protocol
        # see: https://github.com/mapbox/mapbox-gl-js/pull/9225
        sprite_config = context.registers[:site].config["maplibre"]["sprite"]
        if sprite_config.start_with?('/') then
          "#{context.registers[:site].config["url"]}#{sprite_config}"
        else
          sprite_config
        end
      end
      
      private
      # Generates from page metadata and site config
      # the style object pursuant to the Mapbox Style Spec
      #
      # @note The output can include some JS code to load layers asynchronously
      #       and is as such not always valid JSON.
      # @return [String] style persuant to Mapbox Style Spec
      def style(context)
        page_config = context.registers[:page].to_hash
        site_config = context.registers[:site].config
        
        if page_config.dig('maplibre', 'style') then
          page_config.dig('maplibre', 'style').to_json
        elsif site_config.dig('maplibre', 'style') then
          site_config.dig('maplibre', 'style').to_json
        else
          {
            version: 8,
            name: "OSM Liberty",
            metadata: {
              "maputnik:license": "https://github.com/maputnik/osm-liberty/blob/gh-pages/LICENSE.md",
              "maputnik:renderer": "mbgljs",
              "openmaptiles:version": "3.x"
            },
            sources: sources(context),
            sprite: sprite_url(context),
            glyphs: context.registers[:site].config["maplibre"]["glyphs"],
            layers: "__LAYERS__",
            id: "osm-liberty"
          }.to_json.sub(%r{"__LAYERS__"}, layers(context)) # assumes that #to_json uses double quotes
        end
      end
      
      private
      # Generates from page metadata and site config the sources
      # for the style object pursuant to the Mapbox Style Spec
      #
      # @return [Hash] Mapbox Style sources
      def sources(context)
        page_config = context.registers[:page].to_hash
        site_config = context.registers[:site].config
        
        if page_config.dig('maplibre', 'sources') then
          page_config.dig('maplibre', 'sources')
        elsif site_config.dig('maplibre', 'sources') then
          site_config.dig('maplibre', 'sources')
        else
          raise "No MapLibre source found in site config and page meta data."
        end
      end
      
      private
      # Generates from page metadata and site config the layers
      # for the style object pursuant to the Mapbox Style Spec
      # 
      # @note The string is either some JS code to load a JSON file asynchronously or directly a JSON Hash.
      # @return [String] Mapbox Style layers
      def layers(context)
        page_config = context.registers[:page].to_hash
        site_config = context.registers[:site].config
        
        unless page_config.dig('maplibre', 'layers') or site_config.dig('maplibre', 'layers') then
          raise "No MapLibre layers found in site config and page meta data."
        end
        
        obj = page_config.dig('maplibre', 'layers') || site_config.dig('maplibre', 'layers')
        if obj&.end_with? '.json' then
          "await (await fetch('#{obj}')).json()"
        else
          obj.to_json
        end
      end
      
      private
      # LngLat array from tag options or geojson to center the map
      #
      # @return [Array,nil] LngLat array or nil
      def center(context)
        @options[:attributes][:center]&.map{|v| v.to_f} || geojson(context)&.dig(:features, 0, :geometry, :coordinates)
      end

      private
      # Generates map div attributes
      #
      # @return [String]
      def attributes(context)
        attr = []
        attr << "id='#{@options[:attributes][:id]}'"
        attr << %(class='#{Array(@options[:attributes][:class]).join(" ")}') if @options[:attributes][:class]
        attr << %(style='#{(Array(@options[:attributes][:style]) + dimensions(context)).join(";")}')
        attr.join(" ")
      end

      private
      # Generates map div css with dimensions
      #
      # @return [String]
      def dimensions(context)
        width       = @options[:attributes][:width] || context.registers[:site].config.dig('maplibre', 'width') || DEFAULT_MAP_WIDTH
        height      = @options[:attributes][:height] || context.registers[:site].config.dig('maplibre', 'height') || DEFAULT_MAP_HEIGHT
        width_unit  = width.to_s.include?("%") ? "" : "px"
        height_unit = height.to_s.include?("%") ? "" : "px"
        ["width:#{width}#{width_unit}", "height:#{height}#{height_unit}"]
      end

      private
      # Generates GeoJSON Hash from tag attributes or page metadata
      #
      # @return [Hash] GeoJSON Hash
      def geojson(context)
        @geojson ||= if @options[:attributes][:latitude] and @options[:attributes][:longitude] then
          {
            type: "FeatureCollection",
            features: [{
              type: "Feature",
              # properties: {}.select {|key, value| !value.nil? },
              geometry: {
                type: "Point",
                coordinates: [ # first long, that lat
                  @options[:attributes]["longitude"].to_f,
                  @options[:attributes]["latitude"].to_f,
                ]
              }
            }],
          }
        elsif context.registers[:page]["geojson"].is_a? String and context.registers[:page]["geojson"].end_with?(".json") then
          context.registers[:page]["geojson"]
        elsif context.registers[:page].to_hash.dig("geojson", "type") == "FeatureCollection" then
          context.registers[:page]["geojson"].deep_symbolize_keys
        elsif context.registers[:page].to_hash.dig("geojson", "type") == "Feature" then
          {
            type: "FeatureCollection",
            features: [context.registers[:page]["geojson"].deep_symbolize_keys]
          }
        elsif ((lat = context.registers[:page].to_hash.dig("location", "latitude")) and (lon = context.registers[:page].to_hash.dig("location", "longitude"))) then
          {
            type: "FeatureCollection",
            features: [{
              type: "Feature",
              # properties: {}.select {|key, value| !value.nil? },
              geometry: {
                type: "Point",
                coordinates: [
                  # first lon, that lat
                  lon.to_f, lat.to_f
                ]
              }
            }]
          }
        else
          nil
        end
      end
    end
  end
end

Liquid::Template.register_tag("maplibre", Jekyll::MapLibre::MapLibreTag)
