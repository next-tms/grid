class CreateStringTranslations < ActiveRecord::Migration[8.1]
  def change
    create_table(:mobility_string_translations, id: :uuid, default: -> { 'uuidv7()' }) do |t|
      t.references(:translatable, type: :uuid, index: false, polymorphic: true)

      t.string(:key, null: false)
      t.string(:locale, null: false)
      t.string(:value)

      t.timestamps
    end

    add_index(:mobility_string_translations, %i[translatable_id translatable_type key])
    add_index(:mobility_string_translations, %i[translatable_id translatable_type locale key], unique: true)
    add_index(:mobility_string_translations, %i[translatable_type key value locale])
  end
end
