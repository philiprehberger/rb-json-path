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
end
