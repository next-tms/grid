class CreateTextTranslations < ActiveRecord::Migration[8.1]
  def change
    create_table(:mobility_text_translations, id: :uuid, default: -> { 'uuidv7()' }) do |t|
      t.references(:translatable, type: :uuid, index: false, polymorphic: true)

      t.string(:key, null: false)
      t.string(:locale, null: false)

      t.text(:value)

      t.timestamps
    end

    add_index(:mobility_text_translations, %i[translatable_id translatable_type key])
    add_index(:mobility_text_translations, %i[translatable_id translatable_type locale key], unique: true)
  end
end
