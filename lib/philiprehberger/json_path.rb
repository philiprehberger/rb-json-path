# frozen_string_literal: true

require_relative 'json_path/version'

module Philiprehberger
  module JsonPath
    class Error < StandardError; end

    # Query data with a JSONPath expression and return all matches
    #
    # @param data [Hash, Array] the data structure to query
    # @param path [String] JSONPath expression
    # @return [Array] all matching values
    def self.query(data, path)
      tokens = tokenize(path)
      evaluate(data, tokens)
    end

    # Query data and return the first match
    #
    # @param data [Hash, Array] the data structure to query
    # @param path [String] JSONPath expression
    # @return [Object, nil] the first matching value or nil
    def self.first(data, path)
      query(data, path).first
    end

    # Check if a JSONPath expression matches anything
    #
    # @param data [Hash, Array] the data structure to query
    # @param path [String] JSONPath expression
    # @return [Boolean] true if at least one match exists
    def self.exists?(data, path)
      !query(data, path).empty?
    end

    class << self
      private

      def tokenize(path)
        raise Error, 'Path must start with $' unless path.to_s.start_with?('$')

        remaining = path[1..]
        tokens = []

        until remaining.empty?
          case remaining
          when /\A\.(\w+)/
            tokens << { type: :key, value: Regexp.last_match(1) }
            remaining = remaining[Regexp.last_match(0).length..]
          when /\A\[(\d+)\]/
            tokens << { type: :index, value: Regexp.last_match(1).to_i }
            remaining = remaining[Regexp.last_match(0).length..]
          when /\A\[\*\]/
            tokens << { type: :wildcard }
            remaining = remaining[3..]
          when /\A\[(\-?\d+):(\-?\d+)\]/
            tokens << { type: :slice, start: Regexp.last_match(1).to_i, end: Regexp.last_match(2).to_i }
            remaining = remaining[Regexp.last_match(0).length..]
          when /\A\[:(\-?\d+)\]/
            tokens << { type: :slice, start: 0, end: Regexp.last_match(1).to_i }
            remaining = remaining[Regexp.last_match(0).length..]
          when /\A\[(\-?\d+):\]/
            tokens << { type: :slice, start: Regexp.last_match(1).to_i, end: nil }
            remaining = remaining[Regexp.last_match(0).length..]
          when /\A\[\?\(@\.(\w+)\s*(==|!=|>|>=|<|<=)\s*([^\]]+)\)\]/
            tokens << {
              type: :filter,
              key: Regexp.last_match(1),
              op: Regexp.last_match(2),
              value: parse_filter_value(Regexp.last_match(3).strip)
            }
            remaining = remaining[Regexp.last_match(0).length..]
          when /\A\[\?\(@\.(\w+)\)\]/
            tokens << { type: :filter_exists, key: Regexp.last_match(1) }
            remaining = remaining[Regexp.last_match(0).length..]
          when /\A\['([^']+)'\]/
            tokens << { type: :key, value: Regexp.last_match(1) }
            remaining = remaining[Regexp.last_match(0).length..]
          when /\A\["([^"]+)"\]/
            tokens << { type: :key, value: Regexp.last_match(1) }
            remaining = remaining[Regexp.last_match(0).length..]
          else
            raise Error, "Unexpected token at: #{remaining}"
          end
        end

        tokens
      end

      def parse_filter_value(str)
        case str
        when /\A'(.*)'\z/ then Regexp.last_match(1)
        when /\A"(.*)"\z/ then Regexp.last_match(1)
        when /\Atrue\z/i then true
        when /\Afalse\z/i then false
        when /\Anil\z/i, /\Anull\z/i then nil
        when /\A-?\d+\z/ then str.to_i
        when /\A-?\d+\.\d+\z/ then str.to_f
        else str
        end
      end

      def evaluate(data, tokens)
        results = [data]

        tokens.each do |token|
          results = results.flat_map { |node| apply_token(node, token) }
        end

        results
      end

      def apply_token(node, token)
        case token[:type]
        when :key
          apply_key(node, token[:value])
        when :index
          apply_index(node, token[:value])
        when :wildcard
          apply_wildcard(node)
        when :slice
          apply_slice(node, token[:start], token[:end])
        when :filter
          apply_filter(node, token[:key], token[:op], token[:value])
        when :filter_exists
          apply_filter_exists(node, token[:key])
        else
          []
        end
      end

      def apply_key(node, key)
        case node
        when Hash
          sym_key = key.to_sym
          if node.key?(key)
            [node[key]]
          elsif node.key?(sym_key)
            [node[sym_key]]
          else
            []
          end
        else
          []
        end
      end

      def apply_index(node, index)
        return [] unless node.is_a?(Array)
        return [] if index >= node.length || index < -node.length

        [node[index]]
      end

      def apply_wildcard(node)
        case node
        when Array then node
        when Hash then node.values
        else []
        end
      end

      def apply_slice(node, start_idx, end_idx)
        return [] unless node.is_a?(Array)

        end_idx = node.length if end_idx.nil?
        node[start_idx...end_idx] || []
      end

      def apply_filter(node, key, op, value)
        return [] unless node.is_a?(Array)

        node.select do |item|
          next false unless item.is_a?(Hash)

          actual = item[key] || item[key.to_sym]
          next false if actual.nil? && !item.key?(key) && !item.key?(key.to_sym)

          compare(actual, op, value)
        end
      end

      def apply_filter_exists(node, key)
        return [] unless node.is_a?(Array)

        node.select do |item|
          next false unless item.is_a?(Hash)

          item.key?(key) || item.key?(key.to_sym)
        end
      end

      def compare(actual, op, value)
        case op
        when '==' then actual == value
        when '!=' then actual != value
        when '>' then actual.is_a?(Numeric) && value.is_a?(Numeric) && actual > value
        when '>=' then actual.is_a?(Numeric) && value.is_a?(Numeric) && actual >= value
        when '<' then actual.is_a?(Numeric) && value.is_a?(Numeric) && actual < value
        when '<=' then actual.is_a?(Numeric) && value.is_a?(Numeric) && actual <= value
        else false
        end
      end
    end
  end
end
