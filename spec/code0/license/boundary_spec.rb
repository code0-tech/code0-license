# frozen_string_literal: true

RSpec.describe Code0::License::Boundary do
  describe "#add_boundary" do
    it "adds expected boundary" do
      result = described_class.add_boundary("Some\nmultiline\ndata", "CODE0")

      expect(result).to eq(<<~BOUNDARY.chomp)
        ---------------------BEGIN CODE0 LICENSE--------------------
        Some
        multiline
        data
        ----------------------END CODE0 LICENSE---------------------
      BOUNDARY
    end
  end

  describe "#remove_boundary" do
    it "removes the boundary" do
      result = described_class.remove_boundary(<<~BOUNDARY)
        ---------------------BEGIN CODE0 LICENSE--------------------
        Some
        multiline
        data
        ----------------------END CODE0 LICENSE---------------------
      BOUNDARY

      expect(result).to eq("Some\nmultiline\ndata")
    end

    it "removes partial boundaries" do
      result = described_class.remove_boundary(<<~BOUNDARY.chomp)
        ---------------------BEGIN CODE0 LICENSE--------------------
        Some
        multiline
        data
      BOUNDARY

      expect(result).to eq("Some\nmultiline\ndata")
    end
  end
end
