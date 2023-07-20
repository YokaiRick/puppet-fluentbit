# frozen_string_literal: true

require 'spec_helper'

describe 'fluentbit' do
  _, os_facts = on_supported_os.first
  let(:facts) { os_facts }

  context 'with default parameters' do
    it { is_expected.to compile.with_all_deps }

    it { is_expected.to contain_class('fluentbit') }
    it { is_expected.to contain_class('fluentbit::repo') }
    it { is_expected.to contain_class('fluentbit::install') }
    it { is_expected.to contain_class('fluentbit::config') }
    it { is_expected.to contain_class('fluentbit::service') }
    it { is_expected.to contain_package('fluent-bit').with_ensure(%r{present|installed}) }
    it { is_expected.to contain_service('fluent-bit').with_ensure('running') }

    it { is_expected.to contain_concat('/etc/fluent-bit/pipelines/inputs.conf') }
    it { is_expected.to contain_concat('/etc/fluent-bit/pipelines/outputs.conf') }
    it { is_expected.to contain_concat('/etc/fluent-bit/pipelines/filters.conf') }

    it {
      is_expected.to contain_file('/etc/fluent-bit').with(
        ensure: 'directory',
      )
    }

    it {
      is_expected.to contain_file('/etc/fluent-bit/fluent-bit.conf').with(
        ensure: 'file',
      )
    }
  end

  context 'with custom directories' do
    let(:params) do
      {
        config_dir: '/etc/fluentbit',
        config_file: '/etc/fluentbit/fluent-bit.conf',
      }
    end

    it { is_expected.to compile.with_all_deps }

    it {
      is_expected.to contain_file('/etc/fluentbit').with(
        ensure: 'directory',
        purge: true,
        recurse: true,
      )
    }

    it {
      is_expected.to contain_file('/etc/fluentbit/pipelines').with(
        ensure: 'directory',
        purge: true,
        recurse: true,
      )
    }

    it {
      is_expected.to contain_file('/etc/fluentbit/lua-scripts').with(
        ensure: 'directory',
        purge: true,
        recurse: true,
      )
    }
  end

  context 'override service file' do
    let(:params) do
      {
        service_override_unit_file: true,
      }
    end

    it {
      is_expected.to contain_file('/etc/systemd/system/fluent-bit.service').with(
        ensure: 'file',
      ).with_content(%r{ExecStart=/opt/fluent-bit/bin/fluent-bit -c /etc/fluent-bit/fluent-bit.conf --enable-hot-reload})
    }
  end

  context 'configure json parser' do
    let(:params) do
      {
        parsers: {
          'json': {
            'format': 'json',
            'time_key': 'time',
            'time_format': '%d/%b/%Y:%H:%M:%S %z',
          }
        },
      }
    end

    it {
      is_expected.to contain_file('/etc/fluent-bit/parsers.conf')
        .with_content(%r{Name\s+json\n\s+Format\s+json\n\s+Time_key\s+time})
    }
  end

  context 'configure inputs' do
    let(:params) do
      {
        inputs: {
          'tail-syslog': {
            'pipeline': 'input',
            'plugin': 'tail',
            'properties': {
              'Path': '/var/log/syslog',
            }
          }
        },
      }
    end

    it {
      is_expected.to contain_file('/etc/fluent-bit/parsers.conf')
        .with_content(%r{Name\s+json\n\s+Format\s+json\n\s+Time_key\s+time})
    }
  end
end
