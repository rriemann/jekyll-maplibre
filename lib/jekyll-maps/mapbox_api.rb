module Jekyll
  module Maps
    class MapboxApi
      HEAD_END_TAG = %r!</[\s\t]*head>!

      class << self
        def prepend_api_code(doc)
          @config = doc.site.config
          if doc.output =~ HEAD_END_TAG
            # Insert API code before header's end if this document has one.
            doc.output.gsub!(HEAD_END_TAG, %(#{api_code}#{Regexp.last_match}))
          else
            doc.output.prepend(api_code)
          end
        end

        private
        def api_code
          <<HTML
<script type='text/javascript'>
  #{js_lib_contents}
</script>
#{load_mapbox_api}
HTML
        end

        private
        def load_mapbox_api
          access_token = @config.fetch("maps", {})
            .fetch("mapbox", {})
            .fetch("access_token", "")
          <<HTML

<script async defer src='https://api.tiles.mapbox.com/mapbox-gl-js/v0.54.0/mapbox-gl.js' onload='#{Jekyll::Maps::MapboxTag::JS_LIB_NAME}.initializeMap("#{access_token}")'></script>
<link async defer href='https://api.tiles.mapbox.com/mapbox-gl-js/v0.54.0/mapbox-gl.css' rel='stylesheet' />
<style>
  .mapboxgl-popup {
    max-width: 400px;
  }
  .mapboxgl-popup-content {
    padding: 20px 10px 15px 10px;
  }
</style>
HTML
        end

        private
        def js_lib_contents
          @js_lib_contents ||= begin
            File.read(js_lib_path)
          end
        end

        private
        def js_lib_path
          @js_lib_path ||= begin
            File.expand_path("./mapbox_api.js", File.dirname(__FILE__))
          end
        end
      end
    end
  end
end

Jekyll::Hooks.register [:pages, :documents], :post_render do |doc|
  if !doc.relative_path.end_with?('.xml') and doc.output =~ %r!#{Jekyll::Maps::MapboxTag::JS_LIB_NAME}!
    Jekyll::Maps::MapboxApi.prepend_api_code(doc)
  end
end
