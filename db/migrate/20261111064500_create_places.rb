class CreatePlaces < ActiveRecord::Migration[8.1]
  def change
    create_table(:places, id: :uuid, default: -> { 'uuidv7()' }) do |t|
      t.references(:address, type: :uuid, foreign_key: true, null: false)
      t.references(:validation, type: :uuid, foreign_key: true, null: false)

      t.string(:name, null: false)
      t.boolean(:permanently_closed)
      t.string(:types, array: true, default: [], null: false)

      t.timestamps
    end
  end
end
