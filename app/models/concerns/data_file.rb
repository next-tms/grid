module DataFile
  extend ActiveSupport::Concern

  class_methods do
    def available?
      return false unless File.size?(connection_db_config.database) && releases.table_exists?
      return true if releases.exists?(schema_version: schema.version)

      Rails.logger.warn("#{connection_db_config.database} is not built for schema version #{schema.version}") unless @warned
      @warned = true
      false
    end
  end
end
