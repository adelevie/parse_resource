module Associations
  def self.belongs_to(parent)
    field(parent)
  end
end