require 'rails_helper'

RSpec.describe(GridSchema) do
  let(:country) { create(:country) }

  describe '.id_from_object' do
    it { expect(described_class.id_from_object(country, nil, nil)).to(eq(country.to_gid_param)) }
  end

  describe '.object_from_id' do
    it { expect(described_class.object_from_id(country.to_gid_param, nil)).to(eq(country)) }
  end

  describe '.resolve_type' do
    it { expect { described_class.resolve_type(nil, country, nil) }.to(raise_error(GraphQL::RequiredImplementationMissingError)) }
  end
end
