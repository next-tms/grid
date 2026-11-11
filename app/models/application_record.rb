class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  before_create { self.id ||= SecureRandom.uuid_v7 if self.class.columns_hash[self.class.primary_key]&.type == :uuid }
end
