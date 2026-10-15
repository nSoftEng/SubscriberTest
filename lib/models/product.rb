# frozen_string_literal: true

require_relative 'validation_error'

class ProductValidationError < ValidationError
end

class Product
  attr_reader :name, :base_price, :category, :imported

  VALID_CATEGORIES = %i[book food medical other].freeze

  # @param name [String] the product name
  # @param base_price [Float] the shelf price without taxes
  # @param category [Symbol] the product category (:book, :food, :medical, :other)
  # @param imported [Boolean] whether the product is imported
  def initialize(name:, base_price:, category: :other, imported: false)
    validate_name!(name)
    validate_base_price!(base_price)
    validate_category!(category)
    validate_imported!(imported)

    @name = name.strip
    @base_price = base_price.to_f
    @category = category
    @imported = imported
  end

  # @return [Boolean] true if the product is imported
  def imported?
    imported
  end

  def category=(new_category)
    validate_category!(new_category)
    @category = new_category
  end

  private

  def validate_name!(name)
    if name.nil?
      raise ProductValidationError.new(
        field: :name,
        value: name,
        message: "Product name cannot be nil"
      )
    end

    if name.strip.empty?
      raise ProductValidationError.new(
        field: :name,
        value: name,
        message: "Product name cannot be empty"
      )
    end
  end

  def validate_base_price!(price)
    if price.nil?
      raise ProductValidationError.new(
        field: :base_price,
        value: price,
        message: "Product base_price cannot be nil"
      )
    end

    begin
      price_value = Float(price)
    rescue ArgumentError, TypeError
      raise ProductValidationError.new(
        field: :base_price,
        value: price,
        message: "Product base_price must be a valid number, got: #{price.inspect}"
      )
    end

    if price_value.negative?
      raise ProductValidationError.new(
        field: :base_price,
        value: price,
        message: "Product base_price cannot be negative, got: #{price_value}"
      )
    end
  end

  def validate_category!(category)
    unless VALID_CATEGORIES.include?(category)
      raise ProductValidationError.new(
        field: :category,
        value: category,
        message: "Invalid category: #{category.inspect}. Must be one of: #{VALID_CATEGORIES.join(', ')}"
      )
    end
  end

  def validate_imported!(imported)
    unless [true, false].include?(imported)
      raise ProductValidationError.new(
        field: :imported,
        value: imported,
        message: "Product imported must be true or false, got: #{imported.inspect}"
      )
    end
  end
end
