# philiprehberger-json_path

[![Tests](https://github.com/philiprehberger/rb-json-path/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-json-path/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-json_path.svg)](https://rubygems.org/gems/philiprehberger-json_path)
[![License](https://img.shields.io/github/license/philiprehberger/rb-json-path)](LICENSE)

JSONPath expression evaluator with dot notation, wildcards, slices, and filters

## Requirements

- Ruby >= 3.1

## Installation

Add to your Gemfile:

```ruby
gem 'philiprehberger-json_path'
```

Or install directly:

```bash
gem install philiprehberger-json_path
```

## Usage

```ruby
require 'philiprehberger/json_path'

data = {
  'store' => {
    'books' => [
      { 'title' => 'Ruby', 'price' => 30 },
      { 'title' => 'Python', 'price' => 25 },
      { 'title' => 'Go', 'price' => 20 }
    ]
  }
}

Philiprehberger::JsonPath.query(data, '$.store.books[*].title')
# => ["Ruby", "Python", "Go"]

Philiprehberger::JsonPath.first(data, '$.store.books[0].title')
# => "Ruby"

Philiprehberger::JsonPath.exists?(data, '$.store.books')
# => true
```

### Array Indexing and Slicing

```ruby
Philiprehberger::JsonPath.query(data, '$.store.books[0]')
# => [{"title"=>"Ruby", "price"=>30}]

Philiprehberger::JsonPath.query(data, '$.store.books[-1].title')
# => ["Go"]

Philiprehberger::JsonPath.query(data, '$.store.books[0:2].title')
# => ["Ruby", "Python"]
```

### Filter Expressions

```ruby
Philiprehberger::JsonPath.query(data, '$.store.books[?(@.price>22)].title')
# => ["Ruby", "Python"]

Philiprehberger::JsonPath.query(data, "$.store.books[?(@.title=='Go')].price")
# => [20]
```

### Supported Syntax

| Syntax | Description |
|--------|-------------|
| `$` | Root element |
| `.key` | Dot notation for object keys |
| `['key']` | Bracket notation for object keys |
| `[n]` | Array index (supports negative) |
| `[*]` | Wildcard (all elements) |
| `[start:end]` | Array slice |
| `[?(@.key>val)]` | Filter expression |
| `[?(@.key)]` | Existence filter |

## API

| Method | Description |
|--------|-------------|
| `JsonPath.query(data, path)` | Return all matches as an array |
| `JsonPath.first(data, path)` | Return the first match or nil |
| `JsonPath.exists?(data, path)` | Check if any match exists |

## Development

```bash
bundle install
bundle exec rspec      # Run tests
bundle exec rubocop    # Check code style
```

## License

MIT
