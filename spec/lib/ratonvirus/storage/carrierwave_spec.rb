# frozen_string_literal: true

require "spec_helper_carrierwave"

describe Ratonvirus::Storage::Carrierwave do
  describe "#changed?" do
    let(:record) { double }
    let(:attribute) { :file }

    it "returns true when attribute is marked as dirty" do
      expect(record).to receive(:file_changed?).and_return(true)
      expect(subject.changed?(record, attribute)).to be(true)
    end

    it "returns false when attribute is not marked as dirty" do
      expect(record).to receive(:file_changed?).and_return(false)
      expect(subject.changed?(record, attribute)).to be(false)
    end
  end

  describe "#accept?" do
    let(:uploader) do
      Class.new CarrierWave::Uploader::Base
    end

    context "with CarrierWave::Uploader::Base" do
      it "is true" do
        expect(subject.accept?(uploader.new)).to be(true)
      end
    end

    context "with Array" do
      context "when empty" do
        it "is true" do
          expect(subject.accept?([])).to be(true)
        end
      end

      context "when containing only CarrierWave::Uploader::Base" do
        it "is true" do
          expect(
            subject.accept?([uploader.new, uploader.new, uploader.new])
          ).to be(true)
        end
      end

      context "when containing CarrierWave::Uploader::Base and something else" do
        it "is false" do
          expect(
            subject.accept?([uploader.new, double, uploader.new])
          ).to be(false)
        end
      end
    end
  end

  describe "#asset_path" do
    let(:asset) { double }

    context "when a block is not given" do
      it "does nothing" do
        expect(asset).not_to receive(:nil?)
        subject.asset_path(asset)
      end
    end

    context "when a block is given" do
      it "does not yield with nil asset" do
        expect { |b| subject.asset_path(nil, &b) }.not_to yield_control
      end

      it "does not yield with asset.file returning nil" do
        expect(asset).to receive(:file).and_return(nil)
        expect { |b| subject.asset_path(asset, &b) }.not_to yield_control
      end

      it "yields with asset.file.path when a correct resource is given" do
        file = double
        path = double
        expect(asset).to receive(:file).twice.and_return(file)
        expect(file).to receive(:path).and_return(path)
        expect { |b| subject.asset_path(asset, &b) }.to yield_with_args(
          path
        )
      end
    end
  end

  describe "#asset_remove" do
    let(:asset) { double }
    let(:file) { double }
    let(:path) { double }
    let(:dir) { double }

    before do
      expect(asset).to receive(:file).and_return(file)
      expect(file).to receive(:path).and_return(path)
      expect(asset).to receive(:remove!)
      expect(File).to receive(:dirname).with(path).and_return(dir)
    end

    context "with correct folder" do
      it "calls asset.remove! and removes its folder" do
        expect(File).to receive(:directory?).with(dir).and_return(true)
        expect(FileUtils).to receive(:remove_dir).with(dir)

        subject.asset_remove(asset)
      end
    end

    context "with incorrect folder" do
      it "calls asset.remove! and does not remove its folder" do
        expect(File).to receive(:directory?).with(dir).and_return(false)
        expect(FileUtils).not_to receive(:remove_dir)

        subject.asset_remove(asset)
      end
    end
  end
end
