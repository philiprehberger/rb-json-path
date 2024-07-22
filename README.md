# philiprehberger-json_path

[![Tests](https://github.com/philiprehberger/rb-json-path/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-json-path/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-json_path.svg)](https://rubygems.org/gems/philiprehberger-json_path)
[![Last updated](https://img.shields.io/github/last-commit/philiprehberger/rb-json-path)](https://github.com/philiprehberger/rb-json-path/commits/main)

JSONPath expression evaluator with dot notation, wildcards, slices, filters, and recursive descent

## Requirements

- Ruby >= 3.1

## Installation

Add to your Gemfile:

```ruby
gem "philiprehberger-json_path"
```

Or install directly:

```bash
gem install philiprehberger-json_path
```

## Usage

```ruby
require "philiprehberger/json_path"

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

Philiprehberger::JsonPath.values(data, '$.store.books[*].title')
# => ["Ruby", "Python", "Go"]  (alias for query)

Philiprehberger::JsonPath.first(data, '$.store.books[0].title')
# => "Ruby"

Philiprehberger::JsonPath.count(data, '$.store.books[*]')
# => 3

Philiprehberger::JsonPath.exists?(data, '$.store.books')
# => true
```

### Recursive Descent

```ruby
Philiprehberger::JsonPath.query(data, '$..price')
# => [30, 25, 20]

Philiprehberger::JsonPath.query(data, '$..title')
# => ["Ruby", "Python", "Go"]
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

### Negation Filters

```ruby
data = { 'items' => [{ 'name' => 'a', 'hidden' => true }, { 'name' => 'b' }] }

Philiprehberger::JsonPath.query(data, '$.items[?(!@.hidden)].name')
# => ["b"]
```

### Length Comparisons

```ruby
data = {
  'groups' => [
    { 'name' => 'team1', 'members' => ['Alice', 'Bob'] },
    { 'name' => 'team2', 'members' => [] }
  ]
}

Philiprehberger::JsonPath.query(data, '$.groups[?(@.members.length > 0)].name')
# => ["team1"]
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
| `..key` | Recursive descent (match key at any depth) |
| `[?(@.key>val)]` | Filter expression |
| `[?(@.key)]` | Existence filter |
| `[?(!@.key)]` | Negation filter |
| `[?(@.key.length>n)]` | Length comparison filter |

## API

| Method | Description |
|--------|-------------|
| `JsonPath.query(data, path)` | Return all matches as an array |
| `JsonPath.values(data, path)` | Alias for `query` |
| `JsonPath.first(data, path)` | Return the first match or nil |
| `JsonPath.count(data, path)` | Return the number of matches |
| `JsonPath.exists?(data, path)` | Check if any match exists |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## Support

If you find this project useful:

⭐ [Star the repo](https://github.com/philiprehberger/rb-json-path)

🐛 [Report issues](https://github.com/philiprehberger/rb-json-path/issues?q=is%3Aissue+is%3Aopen+label%3Abug)

💡 [Suggest features](https://github.com/philiprehberger/rb-json-path/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement)

❤️ [Sponsor development](https://github.com/sponsors/philiprehberger)

🌐 [All Open Source Projects](https://philiprehberger.com/open-source-packages)

💻 [GitHub Profile](https://github.com/philiprehberger)

🔗 [LinkedIn Profile](https://www.linkedin.com/in/philiprehberger)

## License

[MIT](LICENSE)
