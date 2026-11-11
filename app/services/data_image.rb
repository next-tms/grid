class DataImage
  class << self
    def version = Digest::SHA256.hexdigest(DATASETS.map { |key, dataset| "#{key}:#{dataset.fetch(:schema).version}" }.join(','))[0, 12]
  end

  DATASETS = {
    'geo_names' => { file: 'geo_names.sqlite3', license: 'CC-BY-4.0', schema: GeoNames::Schema },
    'overture' => { file: 'overture.sqlite3', license: 'CDLA-Permissive-2.0 AND Apache-2.0', schema: Overture::Schema }
  }.freeze
  LABEL_PREFIX = 'com.next-tms.grid-data'.freeze
  SOURCE = 'https://github.com/next-tms/grid'.freeze

  attr_reader :previous_image, :previous_labels, :releases

  def initialize(previous_image:, previous_labels:, releases:)
    @previous_image = previous_image
    @previous_labels = previous_labels
    @releases = releases
  end

  def builds = DATASETS.keys.reject { reusable?(it) }

  def dockerfile
    [
      '# syntax=docker/dockerfile:1.19',
      *("FROM #{previous_image} AS previous" if builds.size < DATASETS.size),
      'FROM scratch',
      *DATASETS.map { |key, dataset| copy(key, dataset.fetch(:file)) },
      *labels.map { |name, value| "LABEL #{name}=#{value.to_json}" }
    ].join("\n").concat("\n")
  end

  def labels
    {
      **DATASETS.keys.to_h { ["#{LABEL_PREFIX}.#{it}.release", releases.fetch(it)] },
      **DATASETS.to_h { |key, dataset| ["#{LABEL_PREFIX}.#{key}.schema-version", dataset.fetch(:schema).version] },
      'org.opencontainers.image.licenses' => DATASETS.values.map { it.fetch(:license) }.join(' AND '),
      'org.opencontainers.image.source' => SOURCE
    }
  end

  private

  def copy(key, file) = reusable?(key) ? "COPY --link --from=previous /data/#{file} /data/#{file}" : "COPY --link #{file} /data/#{file}"

  def reusable?(key)
    previous_labels["#{LABEL_PREFIX}.#{key}.release"] == releases.fetch(key) &&
      previous_labels["#{LABEL_PREFIX}.#{key}.schema-version"] == DATASETS.dig(key, :schema).version
  end
end
