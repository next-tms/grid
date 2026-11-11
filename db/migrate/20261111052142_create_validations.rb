class CreateValidations < ActiveRecord::Migration[8.1]
  def change
    create_table(:validations, id: :uuid, default: -> { 'uuidv7()' }) do |t|
      t.references(:validatable, type: :uuid, null: false, polymorphic: true)

      t.string(:address_lines, array: true, default: [], null: false)
      t.string(:administrative_area)
      t.boolean(:business)
      t.string(:dpv_confirmation)
      t.datetime(:expires_at, index: true, null: false)
      t.datetime(:fetched_at, null: false)
      t.string(:geocode_granularity)
      t.decimal(:latitude, precision: 10, scale: 7)
      t.string(:locality)
      t.decimal(:longitude, precision: 10, scale: 7)
      t.boolean(:permanently_closed)
      t.boolean(:po_box)
      t.string(:postal_code)
      t.string(:provider, null: false)
      t.jsonb(:raw, default: {}, null: false)
      t.string(:region_code)
      t.boolean(:residential)
      t.string(:types, array: true, default: [], null: false)
      t.string(:validation_granularity)

      t.timestamps

      t.index(%i[validatable_type validatable_id provider])
    end
  end
end
