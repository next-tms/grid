class CreatePostalCodes < ActiveRecord::Migration[8.1]
  def change
    create_table(:postal_codes, id: :uuid, default: -> { 'uuidv7()' }) do |t|
      t.references(:country, type: :uuid, foreign_key: true, null: false)
      t.references(:locality, type: :uuid, foreign_key: true)

      t.string(:value, index: true, null: false)

      t.timestamps
    end

    add_index(:postal_codes, %i[country_id value], unique: true)
  end
end
