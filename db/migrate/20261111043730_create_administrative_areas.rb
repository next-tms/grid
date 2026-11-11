class CreateAdministrativeAreas < ActiveRecord::Migration[8.1]
  def change
    create_table(:administrative_areas, id: :uuid, default: -> { 'uuidv7()' }) do |t|
      t.references(:country, type: :uuid, foreign_key: true, null: false)

      t.string(:abbreviation)
      t.string(:iso3166_2, index: { unique: true, where: 'iso3166_2 IS NOT NULL' })
      t.string(:name, null: false)

      t.timestamps
    end

    add_index(:administrative_areas, %i[country_id abbreviation], unique: true, where: 'abbreviation IS NOT NULL')
    add_index(:administrative_areas, %i[country_id name], unique: true)
  end
end
