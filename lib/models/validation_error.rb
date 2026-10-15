# frozen_string_literal: true

class ValidationError < StandardError
  attr_reader :field, :value

  def initialize(field:, value:, message:)
    @field = field
    @value = value
    super(message)
  end
end
