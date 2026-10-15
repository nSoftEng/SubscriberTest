# frozen_string_literal: true

require_relative 'line_item'

class Receipt
  attr_reader :line_items

  def initialize
    @line_items = []
  end

  def add_item(line_item)
    @line_items << line_item
    self
  end

  def total_tax
    line_items.sum(&:tax_amount)
  end

  def total_amount
    line_items.sum(&:total_price)
  end

  def to_s
    output = []

    # Add each line item
    line_items.each do |item|
      output << item.to_s
    end

    # Add tax and total summary
    output << format('Sales Taxes: %.2f', total_tax)
    output << format('Total: %.2f', total_amount)

    output.join("\n")
  end
end
