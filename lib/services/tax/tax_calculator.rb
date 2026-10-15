# frozen_string_literal: true

require_relative 'tax_rules/basic_sales_tax_rule'
require_relative 'tax_rules/import_duty_rule'

class TaxCalculator
  def initialize(tax_rules = default_rules)
    @tax_rules = tax_rules
  end

  # Calculates the total tax amount for a product
  # Each applicable rule's tax is rounded to the nearest 0.05 independently,
  # then the rounded amounts are summed
  # @param product [Product] the product to calculate tax for
  # @return [Float] the tax amount
  def calculate(product)
    applicable_rules = @tax_rules.select { |rule| rule.applies_to?(product) }

    applicable_rules.sum do |rule|
      round_up_to_nearest_nickel(product.base_price * rule.rate)
    end
  end

  private

  def default_rules
    [BasicSalesTaxRule.new, ImportDutyRule.new]
  end

  # Rounds up to the nearest 0.05
  # Uses round with 10 decimal places to avoid floating-point precision errors
  def round_up_to_nearest_nickel(amount)
    rounded = (amount / 0.05).round(10).ceil * 0.05
    rounded.round(2)
  end
end
