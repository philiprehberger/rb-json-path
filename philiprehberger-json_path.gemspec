# frozen_string_literal: true

require_relative 'lib/philiprehberger/json_path/version'

Gem::Specification.new do |spec|
  spec.name = 'philiprehberger-json_path'
  spec.version = Philiprehberger::JsonPath::VERSION
  spec.authors = ['philiprehberger']
  spec.email = ['philiprehberger@users.noreply.github.com']

  spec.summary = 'JSONPath expression evaluator for querying nested data structures'
  spec.description = 'Evaluate JSONPath expressions against Ruby hashes and arrays. Supports dot notation, ' \
                     'array indexing, wildcards, slices, and filter expressions for querying nested data.'
  spec.homepage = 'https://github.com/philiprehberger/rb-json-path'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.1'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir['lib/**/*.rb', 'LICENSE', 'README.md', 'CHANGELOG.md']
  spec.require_paths = ['lib']
end
