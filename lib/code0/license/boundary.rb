# frozen_string_literal: true

module Code0
  class License
    # Responsible for adding and removing boundaries of strings
    module Boundary
      BOUNDARY_START  = /(\A|\r?\n)-*BEGIN .+? LICENSE-*\r?\n/
      BOUNDARY_END    = /\r?\n-*END .+? LICENSE-*(\r?\n|\z)/

      class << self
        def add_boundary(data, license_name)
          data = remove_boundary(data)

          [
            pad("BEGIN #{license_name} LICENSE", 60),
            data.strip,
            pad("END #{license_name} LICENSE", 60)
          ].join("\n")
        end

        def remove_boundary(data)
          after_boundary = data.split(BOUNDARY_START).last
          after_boundary.split(BOUNDARY_END).first
        end

        private

        def pad(str, length)
          total_padding = [length - str.length, 0].max

          padding = total_padding / 2.0
          [
            "-" * padding.ceil,
            str,
            "-" * padding.floor
          ].join
        end
      end
    end
  end
end
