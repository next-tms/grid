RSpec.configure do |config|
  config.before(:suite) do
    [[GeoNames::Record, GeoNames::Schema], [Overture::Record, Overture::Schema]].each do |record, schema|
      record.connection_pool.disconnect!
      FileUtils.rm_f(record.connection_db_config.database)
      schema.define(record.connection)
      record.releases.create!(name: 'test', schema_version: schema.version)
    end
    Overture::Schema.index(Overture::Record.connection)
  end
end
