class CreateAddresses < ActiveRecord::Migration[8.1]
  def change
    create_table(:addresses, id: :uuid, default: -> { 'uuidv7()' }) do |t|
      t.references(:administrative_area, type: :uuid, foreign_key: true)
      t.references(:country, type: :uuid, foreign_key: true, null: false)
      t.references(:locality, type: :uuid, foreign_key: true)
      t.references(:postal_code, type: :uuid, foreign_key: true)

      t.string(:address_lines, array: true, default: [], null: false)
      t.string(:key, index: { unique: true }, null: false)
      t.string(:organization)
      t.string(:sorting_code)
      t.string(:sublocality)
      t.string(:time_zone_name)

      t.timestamps
    end
  end
end
