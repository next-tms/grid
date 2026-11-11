namespace :data do
  desc 'Writes the grid-data Dockerfile to DATA_DIR and prints the datasets to build, in GitHub Actions output format'
  task plan: :environment do
    image = DataImage.new(
      previous_image: ENV.fetch('PREVIOUS_IMAGE'),
      previous_labels: JSON.parse(ENV.fetch('PREVIOUS_LABELS', '{}')),
      releases: { 'geo_names' => ENV.fetch('GEO_NAMES_RELEASE'), 'overture' => ENV.fetch('OVERTURE_RELEASE') }
    )
    File.write(File.join(ENV.fetch('DATA_DIR'), 'Dockerfile'), image.dockerfile)

    puts("builds=#{image.builds.join(' ')}")
    puts("version=#{DataImage.version}")
  end

  desc 'Prints the grid-data image version, which is the tag that a deploy uses'
  task version: :environment do
    puts(DataImage.version)
  end
end
