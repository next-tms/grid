namespace :overture do
  desc 'Builds the Overture places file, for example bin/rails "overture:build[2026-10-22.0]"'
  task :build, %i[release region_code] => :environment do |_task, args|
    release = args.fetch(:release)
    source = ENV.fetch('SOURCE') { Overture::Build.source(release) }
    path = Overture::Place.connection_db_config.database
    count = Overture::Build.new(path:, region_code: args.fetch(:region_code, 'US'), release:, source:).call

    puts("Wrote #{count} places to #{path}")
  end
end
