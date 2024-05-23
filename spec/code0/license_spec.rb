# frozen_string_literal: true

RSpec.describe Code0::License do
  described_class.encryption_key = OpenSSL::PKey::RSA.generate(2048)

  let(:license_data) { default_license_data }
  let(:license) { described_class.new(license_data) }
  let(:default_license_data) do
    {
      licensee: { company: "Code0" },
      start_date: "2024-05-01",
      end_date: "2025-05-01",
      restrictions: { users: 1 },
      options: {}
    }
  end

  describe "VERSION" do
    it "has a version number" do
      expect(Code0::License::VERSION).not_to be_nil
    end
  end

  it "data returns hash of attributes" do
    expect(license.data).to match(
      {
        licensee: { company: "Code0" },
        start_date: Date.new(2024, 5, 1),
        end_date: Date.new(2025, 5, 1),
        restrictions: { users: 1 },
        options: {}
      }
    )
  end

  describe ".load" do
    subject(:load) { described_class.load(data) }

    shared_examples "raises decryption error" do |example_name|
      it(example_name) { expect { load }.to raise_error(Code0::License::Encryptor::DecryptionError) }
    end

    context "when data is nil" do
      let(:data) { nil }

      it { expect { load }.to raise_error(Code0::License::ValidationError) }
    end

    it_behaves_like "raises decryption error", "when data is an empty string" do
      let(:data) { "" }
    end

    it_behaves_like "raises decryption error", "when data is a start boundary" do
      let(:data) do
        <<~DATA
          --------BEGIN CODE0 LICENSE--------
        DATA
      end
    end

    it_behaves_like "raises decryption error", "when data is an end boundary" do
      let(:data) do
        <<~DATA
          ---------END CODE0 LICENSE---------
        DATA
      end
    end

    it_behaves_like "raises decryption error", "when data is a boundary" do
      let(:data) do
        <<~DATA
          --------BEGIN CODE0 LICENSE--------
          ---------END CODE0 LICENSE---------
        DATA
      end
    end
  end

  describe "#valid?" do
    subject { license.valid? }

    it { is_expected.to be true }

    context "when missing licensee" do
      let(:license_data) { default_license_data.except(:licensee) }

      it { is_expected.to be false }
    end

    context "when missing licensee is invalid" do
      let(:license_data) { default_license_data.merge(licensee: "") }

      it { is_expected.to be false }
    end

    context "when missing licensee is empty" do
      let(:license_data) { default_license_data.merge(licensee: {}) }

      it { is_expected.to be false }
    end

    context "when missing start date" do
      let(:license_data) { default_license_data.except(:start_date) }

      it { is_expected.to be false }
    end

    context "when missing end date" do
      let(:license_data) { default_license_data.except(:end_date) }

      it { is_expected.to be false }
    end

    context "when missing end date with missing end date allowed" do
      let(:license_data) do
        data = default_license_data.except(:end_date)
        data[:options].merge!(allow_missing_end_date: true)
        data
      end

      it { is_expected.to be true }
    end
  end

  describe "#in_active_time?" do
    subject { license.in_active_time? }

    context "when start is after today" do
      let(:license_data) { default_license_data.merge(start_date: Date.today + 1) }

      it { is_expected.to be false }
    end

    context "when start is today" do
      let(:license_data) { default_license_data.merge(start_date: Date.today) }

      it { is_expected.to be true }
    end

    context "when start is before today" do
      let(:license_data) { default_license_data.merge(start_date: Date.today - 1) }

      it { is_expected.to be true }
    end

    context "when end is after today" do
      let(:license_data) { default_license_data.merge(end_date: Date.today + 1) }

      it { is_expected.to be true }
    end

    context "when end is today" do
      let(:license_data) { default_license_data.merge(end_date: Date.today) }

      it { is_expected.to be true }
    end

    context "when end is before today" do
      let(:license_data) { default_license_data.merge(end_date: Date.today - 1) }

      it { is_expected.to be false }
    end

    context "when end is not set" do
      let(:license_data) { default_license_data.merge(end_date: nil) }

      it { is_expected.to be false }
    end

    context "when end is not set and missing end allowed" do
      let(:license_data) do
        default_license_data.merge(end_date: nil, options: { allow_missing_end_date: true })
      end

      it { is_expected.to be true }
    end
  end

  describe "#restricted?" do
    it "returns true if restriction is set" do
      expect(license.restricted?(:users)).to be true
    end

    it "returns fals if restriction is not set" do
      expect(license.restricted?(:user_count)).to be false
    end
  end
end
