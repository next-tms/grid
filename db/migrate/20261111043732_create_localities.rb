class CreateLocalities < ActiveRecord::Migration[8.1]
  def change
    create_table(:localities, id: :uuid, default: -> { 'uuidv7()' }) do |t|
      t.references(:administrative_area, type: :uuid, foreign_key: true, null: false)

      t.string(:name, null: false)

      t.timestamps
    end

    add_index(:localities, %i[administrative_area_id name], unique: true)
  end
end
