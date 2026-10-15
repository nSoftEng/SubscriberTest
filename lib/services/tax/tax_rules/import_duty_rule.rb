# frozen_string_literal: true

require_relative 'tax_rule'

# Import duty rule: 5% on all imported goods with no exemptions
class ImportDutyRule < TaxRule
  RATE = 0.05

  def applies_to?(product)
    product.imported?
  end

  def rate
    RATE
  end
end
