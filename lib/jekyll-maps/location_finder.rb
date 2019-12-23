# frozen_string_literal: true

class Object
  # File activesupport/lib/active_support/core_ext/object/blank.rb, line 19
  def blank?
    respond_to?(:empty?) ? !!empty? : !self
  end

  def present?
    not blank?
  end
end

module Jekyll
  module Maps
    class LocationFinder
      def initialize(options) # options are fed by tag arguments
        @options = options
      end

      def find(site, page)
        features = []

        # use tag data if latitude and longitude is set
        if @options[:attributes][:latitude] and @options[:attributes][:longitude]
          features.push geojson_feature(@options[:attributes], page)
        # use page data if location is set
        elsif page["location"].present?
          features.push geojson_feature(page["location"], page)
        # extract geojson from page tags
        elsif page["geojson"].present?
          features.push(*page["geojson"].features)
        # use data files indicated with src tag attribute
        elsif @options.dig(:filter, "src")&.start_with?("_data")
          src = @options[:filter]["src"]
          # src = "_data/a/aa _data/b/bb" => ["a/aa", "b/bb"]
          src.scan(/(?<=_data\/)\S+/).each do |path|
            dataset = site.data.dig(*path.split("/"))
            if match_filters? dataset
              # TODO check also for nested elements in objects or arrays
              if dataset["location"].present?
                features.push geojson_feature(dataset)
              elsif dataset[:type] == "FeatureCollection" # is geojson object
                features.push(*dataset.features)
              end
            end
          end
        else
          features = []
          site.collections.each_value do |collection|
            collection.docs.each do |dataset|
              if match_filters?(dataset, false)
                if dataset["location"].present?
                  features << geojson_from(dataset).features
                elsif dataset[:type] == "FeatureCollection" # is geojson object
                  features << dataset.features
                end
              end
            end
          end
        end

        {
          type: "FeatureCollection",
          features: features
        }
      end

      private
      def geojson_feature(source, page = {})
        # create geojson from source for compatibility with old jekyll-maps
        {
          type: "Feature",
          properties: {
            title: source[:marker_title] || page["title"],
            url: source[:marker_url],
            img: source[:marker_img],
            "marker-icon": source[:marker_icon], # compatibility for old jekyll-maps API
            "marker-symbol": source[:marker_symbol],
          },
          geometry: {
            type: "Point",
            coordinates: [ # first long, that lat
              source[:longitude].to_f,
              source[:latitude].to_f,
            ]
          }
        }
      end

      private
      def match_filters?(source, skip_src = true)
        @options[:filters].each do |filter, value|
          if filter == "src"
            if source.respond_to?(:relative_path)
              # "_data/a/aa _data/b/bb" => ["_data/a/aa", "_data/b/bb"]
              return false unless skip_src or value.scan(/\S+/).map{ |path|
                source.relative_path.start_with?(path)
              }.any?
            end
          elsif source[filter].nil? || source[filter] != value
            return false
          end
        end
        return true
      end
    end
  end
end
