Mobility.configure do
  plugins do
    backend :key_value

    active_record

    reader
    writer

    backend_reader

    query

    cache

    column_fallback true

    presence

    locale_accessors
  end
end
