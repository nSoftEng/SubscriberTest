# frozen_string_literal: true

require_relative 'product'
require_relative 'validation_error'
require_relative '../services/tax/tax_calculator'

class LineItemValidationError < ValidationError
end

class LineItem
  attr_reader :quantity, :product

  def initialize(quantity:, product:, tax_calculator: TaxCalculator.new)
    @quantity = validate_quantity!(quantity)
    validate_product!(product)
    validate_tax_calculator!(tax_calculator)

    @product = product
    @tax_calculator = tax_calculator
  end

  # @return [Float] the total shelf price (without tax) for this line
  def shelf_price
    @shelf_price ||= quantity * product.base_price
  end

  # @return [Float] the total tax amount for this line
  def tax_amount
    @tax_amount ||= quantity * @tax_calculator.calculate(product)
  end

  def total_price
    @total_price ||= shelf_price + tax_amount
  end

  # @return [String] formatted line for receipt output
  def to_s
    format('%d %s: %.2f', quantity, product.description, total_price)
  end

  private

  def validate_quantity!(quantity)
    if quantity.nil?
      raise LineItemValidationError.new(
        field: :quantity,
        value: quantity,
        klass: self.class,
        message: "Quantity cannot be nil"
      )
    end

    begin
      quantity_value = Integer(quantity.to_s, 10)
    rescue ArgumentError
      raise LineItemValidationError.new(
        field: :quantity,
        value: quantity,
        klass: self.class,
        message: "Quantity must be a valid integer"
      )
    end

    unless quantity_value.positive?
      raise LineItemValidationError.new(
        field: :quantity,
        value: quantity,
        klass: self.class,
        message: "Quantity must be greater than zero"
      )
    end

    quantity_value
  end

  def validate_product!(product)
    if product.nil?
      raise LineItemValidationError.new(
        field: :product,
        value: product,
        klass: self.class,
        message: "Product cannot be nil"
      )
    end

    unless product.is_a?(Product)
      raise LineItemValidationError.new(
        field: :product,
        value: product,
        klass: self.class,
        message: "Product is invalid"
      )
    end
  end

  def validate_tax_calculator!(tax_calculator)
    unless tax_calculator.respond_to?(:calculate)
      raise LineItemValidationError.new(
        field: :tax_calculator,
        value: tax_calculator,
        klass: self.class,
        message: "Tax calculator is invalid"
      )
    end
  end
end
