# frozen_string_literal: true

require_relative '../models/product'
require_relative '../models/line_item'
require_relative '../models/receipt'
require_relative '../models/validation_error'
require_relative 'product_classifier'

# Format expected: "quantity product_description at price"
# Example: "2 book at 12.49"
class InputParser
  def initialize(classifier: ProductClassifier.new)
    @classifier = classifier
  end

  def parse(input)
    receipt = Receipt.new

    line_items = input.each_line.filter_map { |line| parse_line(line.strip) }
    classify_concurrently!(line_items)
    line_items.each { |line_item| receipt.add_item(line_item) }

    receipt
  end

  private

  def parse_line(line)
    return nil if line.empty?

    match = line.match(/^(-?\d+)\s+(.+?)\s+at\s+(-?\d+(?:\.\d+)?)$/)
    return nil unless match

    build_line_item(match)
  rescue ValidationError => e
    warn "Skipping invalid line #{line.inspect}: #{e.message}"
    nil
  end

  def build_line_item(match)
    quantity = match[1].to_i
    description = match[2]
    price = match[3].to_f

    validate_quantity!(quantity)

    # Product validates, before paying for a classify call (network round trip),
    # so an invalid line never waits on the classifier.
    product = build_product(description, price)

    LineItem.new(quantity: quantity, product: product)
  end

  def classify_concurrently!(line_items)
    line_items.map do |line_item|
      Thread.new { line_item.product.category = determine_category(line_item.product.description) }
    end.each(&:join)
  end

  def validate_quantity!(quantity)
    return if quantity.positive?

    raise LineItemValidationError.new(
      field: :quantity,
      value: quantity,
      klass: self.class,
      message: "Quantity must be greater than zero"
    )
  end

  def build_product(description, price)
    Product.new(
      description: description,
      base_price: price,
      category: :other,
      imported: imported?(description)
    )
  end

  def determine_category(description)
    @classifier.classify(description)
  rescue ProductClassificationError => e
    warn "Could not classify #{description.inspect}, defaulting to :other (#{e.message})"
    :other
  end

  def imported?(description)
    description.downcase.include?('imported')
  end
end
