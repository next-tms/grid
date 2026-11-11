# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_11_11_150000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "addresses", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "administrative_area_id"
    t.uuid "country_id", null: false
    t.uuid "locality_id"
    t.uuid "postal_code_id"
    t.string "address_lines", default: [], null: false, array: true
    t.string "key", null: false
    t.string "organization"
    t.string "sorting_code"
    t.string "sublocality"
    t.string "time_zone_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["administrative_area_id"], name: "index_addresses_on_administrative_area_id"
    t.index ["country_id"], name: "index_addresses_on_country_id"
    t.index ["key"], name: "index_addresses_on_key", unique: true
    t.index ["locality_id"], name: "index_addresses_on_locality_id"
    t.index ["postal_code_id"], name: "index_addresses_on_postal_code_id"
  end

  create_table "administrative_areas", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "country_id", null: false
    t.string "abbreviation"
    t.string "iso3166_2"
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["country_id", "abbreviation"], name: "index_administrative_areas_on_country_id_and_abbreviation", unique: true, where: "(abbreviation IS NOT NULL)"
    t.index ["country_id", "name"], name: "index_administrative_areas_on_country_id_and_name", unique: true
    t.index ["country_id"], name: "index_administrative_areas_on_country_id"
    t.index ["iso3166_2"], name: "index_administrative_areas_on_iso3166_2", unique: true, where: "(iso3166_2 IS NOT NULL)"
  end

  create_table "countries", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.integer "un_m49", null: false
    t.string "iso3166_1_alpha2", null: false
    t.string "iso3166_1_alpha3", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["iso3166_1_alpha2"], name: "index_countries_on_iso3166_1_alpha2", unique: true
    t.index ["iso3166_1_alpha3"], name: "index_countries_on_iso3166_1_alpha3", unique: true
    t.index ["name"], name: "index_countries_on_name", unique: true
    t.index ["un_m49"], name: "index_countries_on_un_m49", unique: true
  end

  create_table "localities", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "administrative_area_id", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["administrative_area_id", "name"], name: "index_localities_on_administrative_area_id_and_name", unique: true
    t.index ["administrative_area_id"], name: "index_localities_on_administrative_area_id"
  end

  create_table "mobility_string_translations", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.string "translatable_type"
    t.uuid "translatable_id"
    t.string "key", null: false
    t.string "locale", null: false
    t.string "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["translatable_id", "translatable_type", "key"], name: "idx_on_translatable_id_translatable_type_key_1082b4c8f8"
    t.index ["translatable_id", "translatable_type", "locale", "key"], name: "idx_on_translatable_id_translatable_type_locale_key_39cd1c41ee", unique: true
    t.index ["translatable_type", "key", "value", "locale"], name: "idx_on_translatable_type_key_value_locale_6eb30204aa"
  end

  create_table "mobility_text_translations", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.string "translatable_type"
    t.uuid "translatable_id"
    t.string "key", null: false
    t.string "locale", null: false
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["translatable_id", "translatable_type", "key"], name: "idx_on_translatable_id_translatable_type_key_8d46c5d5e5"
    t.index ["translatable_id", "translatable_type", "locale", "key"], name: "idx_on_translatable_id_translatable_type_locale_key_cb04246cff", unique: true
  end

  create_table "places", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "address_id", null: false
    t.uuid "validation_id", null: false
    t.string "name"
    t.boolean "permanently_closed"
    t.string "types", default: [], null: false, array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["address_id"], name: "index_places_on_address_id"
    t.index ["validation_id"], name: "index_places_on_validation_id"
  end

  create_table "postal_codes", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "country_id", null: false
    t.uuid "locality_id"
    t.string "value", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["country_id", "value"], name: "index_postal_codes_on_country_id_and_value", unique: true
    t.index ["country_id"], name: "index_postal_codes_on_country_id"
    t.index ["locality_id"], name: "index_postal_codes_on_locality_id"
    t.index ["value"], name: "index_postal_codes_on_value"
  end

  create_table "provider_identifiers", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.string "identifiable_type", null: false
    t.uuid "identifiable_id", null: false
    t.string "provider", null: false
    t.string "value", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["identifiable_type", "identifiable_id", "provider"], name: "idx_on_identifiable_type_identifiable_id_provider_6216b6779a", unique: true
    t.index ["identifiable_type", "provider", "value"], name: "idx_on_identifiable_type_provider_value_eb8d8c18cf", unique: true
  end

  create_table "solid_cache_entries", force: :cascade do |t|
    t.binary "key", null: false
    t.binary "value", null: false
    t.datetime "created_at", null: false
    t.bigint "key_hash", null: false
    t.integer "byte_size", null: false
    t.index ["byte_size"], name: "index_solid_cache_entries_on_byte_size"
    t.index ["key_hash", "byte_size"], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
    t.index ["key_hash"], name: "index_solid_cache_entries_on_key_hash", unique: true
  end

  create_table "validations", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.string "validatable_type", null: false
    t.uuid "validatable_id", null: false
    t.string "address_lines", default: [], null: false, array: true
    t.string "administrative_area"
    t.boolean "business"
    t.string "dpv_confirmation"
    t.datetime "expires_at", null: false
    t.datetime "fetched_at", null: false
    t.string "geocode_granularity"
    t.decimal "latitude", precision: 10, scale: 7
    t.string "locality"
    t.decimal "longitude", precision: 10, scale: 7
    t.boolean "permanently_closed"
    t.boolean "po_box"
    t.string "postal_code"
    t.string "provider", null: false
    t.string "provider_identifier"
    t.jsonb "raw", default: {}, null: false
    t.string "region_code"
    t.boolean "residential"
    t.string "types", default: [], null: false, array: true
    t.string "validation_granularity"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "time_zone"
    t.boolean "dock"
    t.index ["expires_at"], name: "index_validations_on_expires_at"
    t.index ["validatable_type", "validatable_id", "provider"], name: "idx_on_validatable_type_validatable_id_provider_c3d711ed36"
    t.index ["validatable_type", "validatable_id"], name: "index_validations_on_validatable"
  end

  add_foreign_key "addresses", "administrative_areas"
  add_foreign_key "addresses", "countries"
  add_foreign_key "addresses", "localities"
  add_foreign_key "addresses", "postal_codes"
  add_foreign_key "administrative_areas", "countries"
  add_foreign_key "localities", "administrative_areas"
  add_foreign_key "places", "addresses"
  add_foreign_key "places", "validations"
  add_foreign_key "postal_codes", "countries"
  add_foreign_key "postal_codes", "localities"
end
