# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Philiprehberger::JsonPath do
  it 'has a version number' do
    expect(described_class::VERSION).not_to be_nil
  end

  let(:store_data) do
    {
      'store' => {
        'books' => [
          { 'title' => 'A', 'price' => 10, 'category' => 'fiction' },
          { 'title' => 'B', 'price' => 20, 'category' => 'science' },
          { 'title' => 'C', 'price' => 30, 'category' => 'fiction' },
          { 'title' => 'D', 'price' => 5, 'category' => 'science' }
        ],
        'name' => 'My Store'
      }
    }
  end

  describe '.query' do
    it 'returns root with $' do
      expect(described_class.query(store_data, '$')).to eq([store_data])
    end

    it 'accesses a nested key' do
      expect(described_class.query(store_data, '$.store.name')).to eq(['My Store'])
    end

    it 'accesses array by index' do
      result = described_class.query(store_data, '$.store.books[0].title')
      expect(result).to eq(['A'])
    end

    it 'accesses last array element by index' do
      result = described_class.query(store_data, '$.store.books[3].title')
      expect(result).to eq(['D'])
    end

    it 'uses wildcard on array' do
      result = described_class.query(store_data, '$.store.books[*].title')
      expect(result).to eq(%w[A B C D])
    end

    it 'uses array slice' do
      result = described_class.query(store_data, '$.store.books[0:2].title')
      expect(result).to eq(%w[A B])
    end

    it 'uses filter with ==' do
      result = described_class.query(store_data, "$.store.books[?(@.category=='fiction')].title")
      expect(result).to eq(%w[A C])
    end

    it 'uses filter with >' do
      result = described_class.query(store_data, '$.store.books[?(@.price>15)].title')
      expect(result).to eq(%w[B C])
    end

    it 'uses filter with > on different threshold' do
      result = described_class.query(store_data, '$.store.books[?(@.price>25)].title')
      expect(result).to eq(['C'])
    end

    it 'uses bracket notation with single quotes' do
      result = described_class.query(store_data, "$.store['name']")
      expect(result).to eq(['My Store'])
    end

    it 'uses bracket notation with double quotes' do
      result = described_class.query(store_data, '$.store["name"]')
      expect(result).to eq(['My Store'])
    end

    it 'returns empty array for nonexistent path' do
      expect(described_class.query(store_data, '$.store.nonexistent')).to eq([])
    end

    it 'returns empty array for index out of bounds' do
      expect(described_class.query(store_data, '$.store.books[99]')).to eq([])
    end

    it 'raises Error for path not starting with $' do
      expect { described_class.query(store_data, 'store.name') }.to raise_error(described_class::Error)
    end

    it 'raises Error for invalid token' do
      expect { described_class.query(store_data, '$!!invalid') }.to raise_error(described_class::Error)
    end

    it 'handles symbol keys' do
      data = { store: { name: 'Test' } }
      expect(described_class.query(data, '$.store.name')).to eq(['Test'])
    end

    it 'handles wildcard on hash values' do
      data = { 'a' => 1, 'b' => 2, 'c' => 3 }
      result = described_class.query(data, '$[*]')
      expect(result).to contain_exactly(1, 2, 3)
    end

    it 'handles existence filter' do
      data = {
        'items' => [
          { 'name' => 'a', 'color' => 'red' },
          { 'name' => 'b' },
          { 'name' => 'c', 'color' => 'blue' }
        ]
      }
      result = described_class.query(data, '$.items[?(@.color)].name')
      expect(result).to eq(%w[a c])
    end
  end

  describe '.first' do
    it 'returns the first match' do
      expect(described_class.first(store_data, '$.store.books[*].title')).to eq('A')
    end

    it 'returns nil when no match' do
      expect(described_class.first(store_data, '$.store.nonexistent')).to be_nil
    end
  end

  describe '.exists?' do
    it 'returns true when path exists' do
      expect(described_class.exists?(store_data, '$.store.name')).to be true
    end

    it 'returns false when path does not exist' do
      expect(described_class.exists?(store_data, '$.store.nonexistent')).to be false
    end

    it 'returns true for array elements' do
      expect(described_class.exists?(store_data, '$.store.books[0]')).to be true
    end
  end

  describe 'complex queries' do
    let(:nested) do
      {
        'users' => [
          { 'name' => 'Alice', 'age' => 30, 'scores' => [90, 85, 92] },
          { 'name' => 'Bob', 'age' => 25, 'scores' => [78, 88, 95] },
          { 'name' => 'Carol', 'age' => 35, 'scores' => [100, 98, 97] }
        ]
      }
    end

    it 'filters and accesses nested arrays' do
      result = described_class.query(nested, '$.users[?(@.age>28)].name')
      expect(result).to eq(%w[Alice Carol])
    end

    it 'accesses nested array elements' do
      result = described_class.query(nested, '$.users[0].scores[2]')
      expect(result).to eq([92])
    end

    it 'slices nested arrays' do
      result = described_class.query(nested, '$.users[0:2].name')
      expect(result).to eq(%w[Alice Bob])
    end
  end

  describe 'index access' do
    it 'accesses first element' do
      data = { 'items' => [10, 20, 30] }
      result = described_class.query(data, '$.items[0]')
      expect(result).to eq([10])
    end

    it 'accesses middle element' do
      data = { 'items' => [10, 20, 30] }
      result = described_class.query(data, '$.items[1]')
      expect(result).to eq([20])
    end

    it 'accesses last element by index' do
      data = { 'items' => [10, 20, 30] }
      result = described_class.query(data, '$.items[2]')
      expect(result).to eq([30])
    end
  end

  describe 'filter expressions (extended)' do
    let(:data) do
      {
        'products' => [
          { 'name' => 'A', 'price' => 10, 'in_stock' => true },
          { 'name' => 'B', 'price' => 25, 'in_stock' => false },
          { 'name' => 'C', 'price' => 50, 'in_stock' => true },
          { 'name' => 'D', 'price' => 5, 'in_stock' => true }
        ]
      }
    end

    it 'filters with != operator' do
      result = described_class.query(data, "$.products[?(@.name!='A')].name")
      expect(result).to eq(%w[B C D])
    end

    it 'filters with > operator' do
      result = described_class.query(data, '$.products[?(@.price>25)].name')
      expect(result).to eq(['C'])
    end

    it 'filters with < operator' do
      result = described_class.query(data, '$.products[?(@.price<10)].name')
      expect(result).to eq(['D'])
    end

    it 'filters with boolean value' do
      result = described_class.query(data, '$.products[?(@.in_stock==true)].name')
      expect(result).to eq(%w[A C D])
    end

    it 'returns empty when no items match filter' do
      result = described_class.query(data, '$.products[?(@.price>1000)].name')
      expect(result).to eq([])
    end
  end

  describe 'slice expressions (extended)' do
    let(:data) { { 'nums' => [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] } }

    it 'slices from start index to end' do
      result = described_class.query(data, '$.nums[7:]')
      expect(result).to eq([7, 8, 9])
    end

    it 'slices from beginning to index' do
      result = described_class.query(data, '$.nums[:3]')
      expect(result).to eq([0, 1, 2])
    end

    it 'returns empty for slice on non-array' do
      hash_data = { 'obj' => { 'a' => 1 } }
      result = described_class.query(hash_data, '$.obj[0:2]')
      expect(result).to eq([])
    end
  end

  describe '.count' do
    it 'returns the number of matches' do
      expect(described_class.count(store_data, '$.store.books[*].title')).to eq(4)
    end

    it 'returns 0 when no matches' do
      expect(described_class.count(store_data, '$.store.nonexistent')).to eq(0)
    end

    it 'returns 1 for a single match' do
      expect(described_class.count(store_data, '$.store.name')).to eq(1)
    end
  end

  describe '.values' do
    it 'returns the same result as query' do
      result = described_class.values(store_data, '$.store.books[*].title')
      expect(result).to eq(%w[A B C D])
    end

    it 'is an alias for query' do
      path = '$.store.books[?(@.price>15)].title'
      expect(described_class.values(store_data, path)).to eq(described_class.query(store_data, path))
    end
  end

  describe 'recursive descent (..)' do
    it 'finds a key at any depth in nested hashes' do
      data = { 'a' => { 'b' => { 'target' => 1 }, 'target' => 2 } }
      result = described_class.query(data, '$..target')
      expect(result).to contain_exactly(2, 1)
    end

    it 'finds price keys in nested store structure' do
      result = described_class.query(store_data, '$..price')
      expect(result).to contain_exactly(10, 20, 30, 5)
    end

    it 'finds keys inside arrays' do
      data = {
        'items' => [
          { 'name' => 'x', 'sub' => { 'val' => 1 } },
          { 'name' => 'y', 'sub' => { 'val' => 2 } }
        ]
      }
      result = described_class.query(data, '$..val')
      expect(result).to eq([1, 2])
    end

    it 'finds keys in deeply nested mixed structures' do
      data = {
        'level1' => {
          'level2' => [
            { 'level3' => { 'id' => 1 } },
            { 'id' => 2 }
          ],
          'id' => 3
        }
      }
      result = described_class.query(data, '$..id')
      expect(result).to contain_exactly(3, 1, 2)
    end

    it 'returns empty array when key does not exist anywhere' do
      result = described_class.query(store_data, '$..nonexistent')
      expect(result).to eq([])
    end

    it 'works with nested arrays of arrays' do
      data = { 'matrix' => [[{ 'v' => 1 }], [{ 'v' => 2 }, { 'v' => 3 }]] }
      result = described_class.query(data, '$..v')
      expect(result).to eq([1, 2, 3])
    end
  end

  describe 'negation filter (!@)' do
    it 'matches items without a given key' do
      data = {
        'items' => [
          { 'name' => 'a', 'disabled' => true },
          { 'name' => 'b' },
          { 'name' => 'c', 'disabled' => false }
        ]
      }
      result = described_class.query(data, '$.items[?(!@.disabled)].name')
      expect(result).to eq(['b'])
    end

    it 'returns all items when none have the key' do
      data = { 'items' => [{ 'name' => 'a' }, { 'name' => 'b' }] }
      result = described_class.query(data, '$.items[?(!@.color)]')
      expect(result).to eq([{ 'name' => 'a' }, { 'name' => 'b' }])
    end

    it 'returns empty when all items have the key' do
      data = { 'items' => [{ 'x' => 1 }, { 'x' => 2 }] }
      result = described_class.query(data, '$.items[?(!@.x)]')
      expect(result).to eq([])
    end
  end

  describe 'length in filter comparisons' do
    it 'filters by array length > 0' do
      data = {
        'groups' => [
          { 'name' => 'a', 'items' => [1, 2, 3] },
          { 'name' => 'b', 'items' => [] },
          { 'name' => 'c', 'items' => [4] }
        ]
      }
      result = described_class.query(data, '$.groups[?(@.items.length > 0)].name')
      expect(result).to eq(%w[a c])
    end

    it 'filters by string length' do
      data = {
        'words' => [
          { 'text' => 'hi' },
          { 'text' => 'hello' },
          { 'text' => 'hey' }
        ]
      }
      result = described_class.query(data, '$.words[?(@.text.length > 2)].text')
      expect(result).to eq(%w[hello hey])
    end

    it 'filters by exact length with ==' do
      data = {
        'items' => [
          { 'tags' => %w[a b] },
          { 'tags' => %w[c d e] },
          { 'tags' => ['f'] }
        ]
      }
      result = described_class.query(data, '$.items[?(@.tags.length == 2)]')
      expect(result).to eq([{ 'tags' => %w[a b] }])
    end

    it 'returns empty when key path does not resolve' do
      data = { 'items' => [{ 'name' => 'a' }] }
      result = described_class.query(data, '$.items[?(@.missing.length > 0)]')
      expect(result).to eq([])
    end
  end

  describe '.paths' do
    it 'returns the root path for $' do
      expect(described_class.paths({ 'a' => 1 }, '$')).to eq(['$'])
    end

    it 'returns the canonical path for a simple dotted expression' do
      expect(described_class.paths({ 'a' => { 'b' => 1 } }, '$.a.b')).to eq(['$.a.b'])
    end

    it 'returns one path per match for wildcard expansion' do
      data = { 'items' => [10, 20, 30] }
      expect(described_class.paths(data, '$.items[*]')).to eq(['$.items[0]', '$.items[1]', '$.items[2]'])
    end

    it 'returns the canonical path for an array index' do
      data = { 'items' => [10, 20, 30] }
      expect(described_class.paths(data, '$.items[0]')).to eq(['$.items[0]'])
    end

    it 'returns an array slice as separate index paths' do
      data = { 'items' => [10, 20, 30, 40] }
      expect(described_class.paths(data, '$.items[*]'))
        .to eq(['$.items[0]', '$.items[1]', '$.items[2]', '$.items[3]'])
    end

    it 'returns an empty array for non-matching expressions' do
      expect(described_class.paths({ 'a' => 1 }, '$.missing')).to eq([])
    end

    it 'returns paths in document order' do
      data = {
        'store' => {
          'books' => [
            { 'title' => 'A' },
            { 'title' => 'B' },
            { 'title' => 'C' }
          ]
        }
      }
      expect(described_class.paths(data, '$.store.books[*].title')).to eq([
                                                                            '$.store.books[0].title',
                                                                            '$.store.books[1].title',
                                                                            '$.store.books[2].title'
                                                                          ])
    end

    it 'does not mutate the input' do
      data = { 'items' => [{ 'name' => 'a' }, { 'name' => 'b' }] }
      before = Marshal.load(Marshal.dump(data))
      described_class.paths(data, '$.items[*].name')
      expect(data).to eq(before)
    end

    it 'returns the same canonical path that resolves back to the value' do
      data = { 'items' => [{ 'name' => 'a' }, { 'name' => 'b' }] }
      paths = described_class.paths(data, '$.items[*].name')
      paths.each_with_index do |p, i|
        expect(described_class.query(data, p)).to eq([data['items'][i]['name']])
      end
    end

    it 'emits index paths for filter matches' do
      data = {
        'items' => [
          { 'name' => 'a', 'on' => true },
          { 'name' => 'b', 'on' => false },
          { 'name' => 'c', 'on' => true }
        ]
      }
      expect(described_class.paths(data, '$.items[?(@.on==true)].name'))
        .to eq(['$.items[0].name', '$.items[2].name'])
    end

    it 'emits paths for recursive descent matches' do
      data = { 'a' => { 'b' => { 'target' => 1 }, 'target' => 2 } }
      expect(described_class.paths(data, '$..target')).to contain_exactly('$.a.target', '$.a.b.target')
    end
  end

  describe 'edge cases' do
    it 'returns empty for key access on non-hash node' do
      data = { 'val' => 42 }
      result = described_class.query(data, '$.val.sub')
      expect(result).to eq([])
    end

    it 'returns empty for index access on non-array' do
      data = { 'val' => 'string' }
      result = described_class.query(data, '$.val[0]')
      expect(result).to eq([])
    end

    it 'returns empty for wildcard on scalar' do
      data = { 'val' => 42 }
      result = described_class.query(data, '$.val[*]')
      expect(result).to eq([])
    end

    it 'handles deeply nested structures' do
      data = { 'a' => { 'b' => { 'c' => { 'd' => { 'e' => 'deep' } } } } }
      result = described_class.query(data, '$.a.b.c.d.e')
      expect(result).to eq(['deep'])
    end

    it 'handles empty array' do
      data = { 'items' => [] }
      result = described_class.query(data, '$.items[*]')
      expect(result).to eq([])
    end

    it 'handles empty hash' do
      data = { 'obj' => {} }
      result = described_class.query(data, '$.obj[*]')
      expect(result).to eq([])
    end

    it 'handles filter on non-array returns empty' do
      data = { 'val' => 'string' }
      result = described_class.query(data, "$.val[?(@.x=='y')]")
      expect(result).to eq([])
    end

    it 'handles existence filter on non-hash items in array' do
      data = { 'items' => [1, 'string', { 'x' => 1 }] }
      result = described_class.query(data, '$.items[?(@.x)]')
      expect(result).to eq([{ 'x' => 1 }])
    end
  end
end
