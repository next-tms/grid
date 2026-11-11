class CreateCountries < ActiveRecord::Migration[8.1]
  def change
    create_table(:countries, id: :uuid, default: -> { 'gen_random_uuid()' }) do |t|
      t.integer(:un_m49, index: { unique: true }, null: false)

      t.string(:iso3166_1_alpha2, index: { unique: true }, null: false)
      t.string(:iso3166_1_alpha3, index: { unique: true }, null: false)
      t.string(:name, index: { unique: true }, null: false)

      t.timestamps
    end
  end
end
