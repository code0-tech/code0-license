# frozen_string_literal: true

RSpec.describe Code0::License::Encryptor do
  let(:key_pair) { OpenSSL::PKey::RSA.generate(2048) }
  let(:key) { key_pair }
  let(:encryptor) { described_class.new(key) }

  describe "#encrypt" do
    context "when used with public key" do
      let(:key) { key_pair.public_key }

      it "raises error" do
        expect { encryptor.encrypt("some_data") }.to raise_error(described_class::KeyError)
      end
    end

    it "returns expected keys in base64" do
      result = encryptor.encrypt("some_data")
      decoded = JSON.parse(Base64.decode64(result))

      expect(decoded.keys).to match_array(%w[data key iv])
    end
  end

  describe "#decrypt" do
    let(:encrypted_data) { described_class.new(key_pair).encrypt("some_data") }

    it "decrypts encrypted data" do
      expect(encryptor.decrypt(encrypted_data)).to eq("some_data")
    end

    context "when used with public key" do
      let(:key) { key_pair.public_key }

      it "decrypts encrypted data" do
        expect(encryptor.decrypt(encrypted_data)).to eq("some_data")
      end
    end

    context "when required keys are missing" do
      let(:encrypted_data) do
        Base64.encode64(<<~DATA)
          {
            "data": "Something"
          }
        DATA
      end

      it "raises error" do
        expect { encryptor.decrypt(encrypted_data) }.to raise_error(described_class::DecryptionError)
      end
    end
  end
end
