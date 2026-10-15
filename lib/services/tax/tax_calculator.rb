# frozen_string_literal: true

require_relative 'tax_rules/basic_sales_tax_rule'
require_relative 'tax_rules/import_duty_rule'

class TaxCalculator
  def initialize(tax_rules = default_rules)
    @tax_rules = tax_rules
  end

  # Calculates the total tax amount for a product using compound taxes
  # Taxes are applied in cascade: (price * (1 + tax1)) * (1 + tax2) - price
  # @param product [Product] the product to calculate tax for
  # @return [Float] the tax amount rounded to nearest 0.05
  def calculate(product)
    applicable_rules = @tax_rules.select { |rule| rule.applies_to?(product) }

    # Apply taxes in cascade (compound)
    final_price = applicable_rules.reduce(product.base_price) do |price, rule|
      price * (1 + rule.rate)
    end

    # Calculate total tax (final price - base price)
    raw_tax = final_price - product.base_price
    round_up_to_nearest_nickel(raw_tax)
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
