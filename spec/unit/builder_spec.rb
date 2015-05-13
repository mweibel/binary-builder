require 'spec_helper'
require 'builder'
require 'architect/architects'

module BinaryBuilder
  describe Builder do
    subject(:builder) { Builder.new(options) }
    let(:node_architect) { double(:node_architect) }
    let(:options) do
      {
        binary_name: 'node',
        binary_version: 'v0.12.2'
      }
    end
    let (:foundation_path) { 'tmp_dir' }

    before do
      allow(NodeArchitect).to receive(:new)
      allow(Dir).to receive(:mktmpdir).and_return('tmp_dir')
    end

    describe '#new' do
      context 'for a node binary' do
        it 'sets binary_name, binary_version, and docker_image values' do
          expect(builder.binary_name).to eq('node')
          expect(builder.binary_version).to eq('v0.12.2')
        end

        it 'creates a node architect' do
          expect(NodeArchitect).to receive(:new).with({binary_version: 'v0.12.2'}).and_return(node_architect)
          builder
        end
      end
    end

    describe '#set_foundation' do
      let(:blueprint) { double(:blueprint) }

      before do
        allow(NodeArchitect).to receive(:new).and_return(node_architect)
        allow(FileUtils).to receive(:chmod)
      end

      it "writes the architect's blueprint to a temporary executable within $HOME" do
        expect(node_architect).to receive(:blueprint).and_return(blueprint)
        expect(FileUtils).to receive(:mkdir_p).with(foundation_path)

        blueprint_path = File.join(foundation_path, 'blueprint.sh')
        expect(File).to receive(:write).with(blueprint_path, blueprint)
        expect(FileUtils).to receive(:chmod).with('+x', blueprint_path)
        builder.set_foundation
      end
    end

    describe '#install' do
      it 'exercises the blueprint script' do
        blueprint_path = File.join(foundation_path, 'blueprint.sh')
        expect(builder).to receive(:run!).with(blueprint_path)
        builder.install
      end
    end

    describe '#tar_installed_binary' do

      before do
        allow(FileUtils).to receive(:rm)
        allow(builder).to receive(:run!)
      end

      it 'removes the blueprint' do
        expect(FileUtils).to receive(:rm).with(File.join(foundation_path, 'blueprint.sh'))
        builder.tar_installed_binary
      end

      it 'tars the remaining files from their directory' do
        expect(builder).to receive(:run!).with("tar czf node-v0.12.2-linux-x64.tgz -C #{foundation_path} .")
        builder.tar_installed_binary
      end
    end

    describe '#build' do
      let(:builder) { double(:builder) }

      it 'sets a foundation, installs via docker, and tars the installed binary' do
        allow(Builder).to receive(:new).with(options).and_return(builder)

        expect(builder).to receive(:set_foundation)
        expect(builder).to receive(:install)
        expect(builder).to receive(:tar_installed_binary)
        Builder.build(options)
      end
    end
  end
end
