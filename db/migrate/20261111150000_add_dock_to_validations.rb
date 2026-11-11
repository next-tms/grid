class AddDockToValidations < ActiveRecord::Migration[8.1]
  def change
    add_column(:validations, :dock, :boolean)
  end
end
