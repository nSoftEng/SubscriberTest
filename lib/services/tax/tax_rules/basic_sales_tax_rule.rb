# frozen_string_literal: true

require_relative 'tax_rule'

# Basic sales tax rule: 10% on all goods except books, food, and medical products
class BasicSalesTaxRule < TaxRule
  RATE = 0.10
  TAX_EXEMPT_CATEGORIES = %i[book food medical].freeze

  def applies_to?(product)
    !TAX_EXEMPT_CATEGORIES.include?(product.category)
  end

  def rate
    RATE
  end
end
