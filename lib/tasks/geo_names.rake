namespace :geo_names do
  desc 'Builds the GeoNames postal code and city file, for example bin/rails "geo_names:build[2026-11]"'
  task :build, %i[release] => :environment do |_task, args|
    release = args.fetch(:release) { Time.current.strftime('%Y-%m') }
    path = GeoNames::PostalCode.connection_db_config.database
    counts = GeoNames::Build.new(path:, release:, source: ENV.fetch('SOURCE', GeoNames::Build.source)).call

    puts("Wrote #{counts[:postal_codes]} postal codes and #{counts[:cities]} cities to #{path}")
  end
end
