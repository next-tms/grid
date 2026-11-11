class ChangePlacesNameNull < ActiveRecord::Migration[8.1]
  def change
    change_column_null(:places, :name, true)
  end
end
