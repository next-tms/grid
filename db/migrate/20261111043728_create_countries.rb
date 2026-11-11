class CreateCountries < ActiveRecord::Migration[8.1]
  def change
    create_table(:countries, id: :uuid, default: -> { 'uuidv7()' }) do |t|
      t.integer(:un_m49, index: { unique: true }, null: false)

      t.string(:iso3166_1_alpha2, index: { unique: true }, null: false)
      t.string(:iso3166_1_alpha3, index: { unique: true }, null: false)
      t.string(:name, index: { unique: true }, null: false)

      t.timestamps
    end
  end
end
