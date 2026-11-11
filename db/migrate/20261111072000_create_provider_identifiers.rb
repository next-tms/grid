class CreateProviderIdentifiers < ActiveRecord::Migration[8.1]
  def change
    create_table(:provider_identifiers, id: :uuid, default: -> { 'uuidv7()' }) do |t|
      t.references(:identifiable, type: :uuid, index: false, null: false, polymorphic: true)

      t.string(:provider, null: false)
      t.string(:value, null: false)

      t.timestamps

      t.index(%i[identifiable_type identifiable_id provider], unique: true)
      t.index(%i[identifiable_type provider value], unique: true)
    end
  end
end
