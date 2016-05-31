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
      expect(result).to eq(['A', 'B', 'C', 'D'])
    end

    it 'uses array slice' do
      result = described_class.query(store_data, '$.store.books[0:2].title')
      expect(result).to eq(['A', 'B'])
    end

    it 'uses filter with ==' do
      result = described_class.query(store_data, "$.store.books[?(@.category=='fiction')].title")
      expect(result).to eq(['A', 'C'])
    end

    it 'uses filter with >' do
      result = described_class.query(store_data, '$.store.books[?(@.price>15)].title')
      expect(result).to eq(['B', 'C'])
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
      expect(result).to eq(['a', 'c'])
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
      expect(result).to eq(['Alice', 'Carol'])
    end

    it 'accesses nested array elements' do
      result = described_class.query(nested, '$.users[0].scores[2]')
      expect(result).to eq([92])
    end

    it 'slices nested arrays' do
      result = described_class.query(nested, '$.users[0:2].name')
      expect(result).to eq(['Alice', 'Bob'])
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
      expect(result).to eq(['B', 'C', 'D'])
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
      expect(result).to eq(['A', 'C', 'D'])
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
