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

    # Alias for query (more discoverable name)
    #
    # @param data [Hash, Array] the data structure to query
    # @param path [String] JSONPath expression
    # @return [Array] all matching values
    def self.values(data, path)
      query(data, path)
    end

    # Query data and return the first match
    #
    # @param data [Hash, Array] the data structure to query
    # @param path [String] JSONPath expression
    # @return [Object, nil] the first matching value or nil
    def self.first(data, path)
      query(data, path).first
    end

    # Return the number of matches for a JSONPath expression
    #
    # @param data [Hash, Array] the data structure to query
    # @param path [String] JSONPath expression
    # @return [Integer] number of matches
    def self.count(data, path)
      query(data, path).size
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

      TOKEN_PATTERNS = [
        [/\A\.\.(\w+)/, :recursive_pat],
        [/\A\.(\w+)/, :key_pat],
        [/\A\[(\d+)\]/, :index_pat],
        [/\A\[\*\]/, :wildcard_pat],
        [/\A\[(-?\d+):(-?\d+)\]/, :slice_both_pat],
        [/\A\[:(-?\d+)\]/, :slice_end_pat],
        [/\A\[(-?\d+):\]/, :slice_start_pat],
        [/\A\[\?\(!@\.(\w+)\)\]/, :filter_not_exists_pat],
        [/\A\[\?\(@\.([\w.]+)\.length\s*(==|!=|>|>=|<|<=)\s*([^\]]+)\)\]/, :filter_length_pat],
        [/\A\[\?\(@\.(\w+)\s*(==|!=|>|>=|<|<=)\s*([^\]]+)\)\]/, :filter_pat],
        [/\A\[\?\(@\.(\w+)\)\]/, :filter_exists_pat],
        [/\A\['([^']+)'\]/, :bracket_single_pat],
        [/\A\["([^"]+)"\]/, :bracket_double_pat]
      ].freeze

      def tokenize(path)
        raise Error, 'Path must start with $' unless path.to_s.start_with?('$')

        remaining = path[1..]
        tokens = []

        until remaining.empty?
          token, consumed = match_token(remaining)
          raise Error, "Unexpected token at: #{remaining}" unless token

          tokens << token
          remaining = remaining[consumed..]
        end

        tokens
      end

      def match_token(remaining)
        TOKEN_PATTERNS.each do |pattern, kind|
          m = pattern.match(remaining)
          next unless m

          return build_token(kind, m), m[0].length
        end
        nil
      end

      def build_token(kind, m)
        case kind
        when :recursive_pat then { type: :recursive, value: m[1] }
        when :key_pat then { type: :key, value: m[1] }
        when :index_pat then { type: :index, value: m[1].to_i }
        when :wildcard_pat then { type: :wildcard }
        when :slice_both_pat then { type: :slice, start: m[1].to_i, end: m[2].to_i }
        when :slice_end_pat then { type: :slice, start: 0, end: m[1].to_i }
        when :slice_start_pat then { type: :slice, start: m[1].to_i, end: nil }
        when :filter_not_exists_pat then { type: :filter_not_exists, key: m[1] }
        when :filter_length_pat then { type: :filter_length, key_path: m[1], op: m[2], value: parse_filter_value(m[3].strip) }
        when :filter_pat then { type: :filter, key: m[1], op: m[2], value: parse_filter_value(m[3].strip) }
        when :filter_exists_pat then { type: :filter_exists, key: m[1] }
        when :bracket_single_pat then { type: :key, value: m[1] }
        when :bracket_double_pat then { type: :key, value: m[1] }
        end
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
        when :filter_not_exists
          apply_filter_not_exists(node, token[:key])
        when :filter_length
          apply_filter_length(node, token[:key_path], token[:op], token[:value])
        when :recursive
          apply_recursive(node, token[:value])
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

      def apply_filter_not_exists(node, key)
        return [] unless node.is_a?(Array)

        node.reject do |item|
          next false unless item.is_a?(Hash)

          item.key?(key) || item.key?(key.to_sym)
        end
      end

      def apply_filter_length(node, key_path, op, value)
        return [] unless node.is_a?(Array)

        node.select do |item|
          next false unless item.is_a?(Hash)

          resolved = resolve_key_path(item, key_path)
          next false if resolved.nil?

          length = resolved.respond_to?(:length) ? resolved.length : nil
          next false if length.nil?

          compare(length, op, value)
        end
      end

      def resolve_key_path(node, key_path)
        keys = key_path.split('.')
        current = node
        keys.each do |key|
          return nil unless current.is_a?(Hash)

          current = current[key] || current[key.to_sym]
          return nil if current.nil?
        end
        current
      end

      def apply_recursive(node, key)
        results = []
        collect_recursive(node, key, results)
        results
      end

      def collect_recursive(node, key, results)
        case node
        when Hash
          node.each do |k, v|
            results << v if k.to_s == key
            collect_recursive(v, key, results)
          end
        when Array
          node.each { |item| collect_recursive(item, key, results) }
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
