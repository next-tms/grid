class AddTimeZoneToValidations < ActiveRecord::Migration[8.1]
  def change
    add_column(:validations, :time_zone, :string)
  end
end
