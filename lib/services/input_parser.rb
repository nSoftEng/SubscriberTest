# frozen_string_literal: true

require_relative '../models/product'
require_relative '../models/line_item'
require_relative '../models/receipt'
require_relative '../models/validation_error'
require_relative 'product_classifier'

# Format expected: "quantity product_name at price"
# Example: "2 book at 12.49"
class InputParser
  def initialize(classifier: ProductClassifier.new)
    @classifier = classifier
  end

  def parse(input)
    receipt = Receipt.new

    input.each_line do |line|
      line_item = parse_line(line.strip)
      receipt.add_item(line_item) if line_item
    end

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

    product = build_product(description, price)
    LineItem.new(quantity: quantity, product: product)
  end

  def build_product(description, price)
    Product.new(
      name: description,
      base_price: price,
      category: determine_category(description),
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
