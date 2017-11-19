require 'spec_helper'

describe 'nginx::config' do
  let(:facts) { default_test_facts }

  it do
    should contain_class('boxen::config')
  end
end
