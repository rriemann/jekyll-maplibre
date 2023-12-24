lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "jekyll-maplibre/version"

Gem::Specification.new do |spec|
  spec.name          = "jekyll-maplibre"
  spec.summary       = "Maplibre GL JS for Jekyll"
  spec.description   = "MapLibre GL JS support for Jekyll websites to easily display vector maps with geojson data"
  spec.version       = Jekyll::MapLibre::VERSION
  spec.authors       = ["Anatoliy Yastreb, Robert Riemann"]
  spec.email         = ["robert@riemann.cc"]

  spec.homepage      = "https://blog.riemann.cc/projects/jekyll-maplibre"
  spec.licenses      = ["MIT"]
  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r!^(test|spec|features)/!) }
  spec.require_paths = ["lib"]
  
  spec.required_ruby_version = '>= 3.1.0'

  spec.add_dependency "jekyll", ">= 3.0", "< 5.0"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake", "~> 13.1"
  spec.add_development_dependency "rspec", "~> 3.5"
  spec.add_development_dependency "rubocop", "1.50.2"
end
