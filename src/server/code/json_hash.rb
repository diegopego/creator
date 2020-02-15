# frozen_string_literal: true
require 'json'

module JsonHash

  def self.fast(obj)
    JSON.fast_generate(obj)
  end

  def self.pretty(obj)
    JSON.pretty_generate(obj)
  end

  def self.parse(s)
    if s === ''
      {}
    else
      JSON.parse!(s)
    end
  end

  ParseError = JSON::ParserError

end