##
# copyright: 2020 Anatoliy Yastreb <anatoliy.yastreb@gmail.com>
# license: MIT
#
# original code from jekyll-maps, https://github.com/ayastreb/jekyll-maps/

module Jekyll
  module MapLibre
    class OptionsParser
      OPTIONS_SYNTAX     = %r!([^\s]+)\s*=\s*['"]+([^'"]+)['"]+!
      ALLOWED_FLAGS      = %w(
        no_cluster
      ).freeze
      ALLOWED_ATTRIBUTES = %w(
        id
        width
        height
        class
        style
        zoom
        center
        description
        latitude
        longitude
      ).freeze

      class << self
        def parse(raw_options)
          options = {
            :attributes => {},
            :flags      => {}
          }
          raw_options.scan(OPTIONS_SYNTAX).each do |key, value|
            value = value.split(",") if value.include?(",")
            if ALLOWED_ATTRIBUTES.include?(key)
              options[:attributes][key.to_sym] = value
            else
              raise "found not allowed MapLibre tag attribute #{key}"
            end
          end
          ALLOWED_FLAGS.each do |key|
            options[:flags][key.to_sym] = true if raw_options.include?(key)
          end
          options
        end
      end
    end
  end
end
