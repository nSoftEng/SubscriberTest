# frozen_string_literal: true

class TaxRule
  def applies_to?(product)
    raise NotImplementedError, 'Subclasses must implement applies_to?'
  end

  # @return [Float] the tax rate as a decimal (e.g., 0.10 for 10%)
  def rate
    raise NotImplementedError, 'Subclasses must implement rate'
  end
end
