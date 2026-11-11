RSpec.shared_examples('a cacheable response') do
  let(:conditional_headers) do
    { 'If-None-Match' => response.headers['ETag'], 'X-Goog-FieldMask' => request.headers['X-Goog-FieldMask'] }.compact
  end

  it { expect(response.headers['Cache-Control']).to(match(/\Amax-age=\d+, public\z/)) }
  it { expect(response.headers['Cache-Control'][/\d+/].to_i).to(be_between(1, 60)) }
  it { expect(response.headers['Last-Modified']).to(be_present) }

  context 'with a matching ETag' do
    before { get(request.fullpath, headers: conditional_headers) }

    it { expect(response).to(have_http_status(:not_modified)) }
  end
end
