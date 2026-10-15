# frozen_string_literal: true

require_relative 'validation_error'

class ProductValidationError < ValidationError
end

class Product
  attr_reader :description, :base_price, :category, :imported

  VALID_CATEGORIES = %i[book food medical other].freeze

  # @param description [String] the product description
  # @param base_price [Float] the shelf price without taxes
  # @param category [Symbol] the product category (:book, :food, :medical, :other)
  # @param imported [Boolean] whether the product is imported
  def initialize(description:, base_price:, category: :other, imported: false)
    validate_description!(description)
    validate_base_price!(base_price)
    validate_category!(category)
    validate_imported!(imported)

    @description = description.strip
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

  def validate_description!(description)
    if description.nil?
      raise ProductValidationError.new(
        field: :description,
        value: description,
        klass: self.class,
        message: "Description cannot be nil"
      )
    end

    if description.strip.empty?
      raise ProductValidationError.new(
        field: :description,
        value: description,
        klass: self.class,
        message: "Description cannot be empty"
      )
    end
  end

  def validate_base_price!(price)
    if price.nil?
      raise ProductValidationError.new(
        field: :base_price,
        value: price,
        klass: self.class,
        message: "Base price cannot be nil"
      )
    end

    begin
      price_value = Float(price)
    rescue ArgumentError, TypeError
      raise ProductValidationError.new(
        field: :base_price,
        value: price,
        klass: self.class,
        message: "Base price must be a valid number"
      )
    end

    if price_value.negative?
      raise ProductValidationError.new(
        field: :base_price,
        value: price,
        klass: self.class,
        message: "Base price cannot be negative"
      )
    end
  end

  def validate_category!(category)
    unless VALID_CATEGORIES.include?(category)
      raise ProductValidationError.new(
        field: :category,
        value: category,
        klass: self.class,
        message: "Invalid category. Must be one of: #{VALID_CATEGORIES.join(', ')}"
      )
    end
  end

  def validate_imported!(imported)
    unless [true, false].include?(imported)
      raise ProductValidationError.new(
        field: :imported,
        value: imported,
        klass: self.class,
        message: "Imported must be true or false"
      )
    end
  end
end
