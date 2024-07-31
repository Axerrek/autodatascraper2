# frozen_string_literal: true

require 'rspec'
require_relative '../classes/csv'

RSpec.describe Csv do
  let(:params) { "link: https://example.com;param1: value1\nlink: https://another-example.com;param2: value2" }
  let(:max_semicolons_params) { "link: https://example.com;param1: value1;param2: value2" }
  let(:csv_instance) { Csv.new(params, max_semicolons_params) }
  let(:filename) { 'test_dane.csv' }

  describe '#extract_columns' do
    it 'extracts unique column headers from max_semicolons_parameters' do
      expect(csv_instance.extract_columns).to match_array(['link', 'param1', 'param2'])
    end
  end
end
