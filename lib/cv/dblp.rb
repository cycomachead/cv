# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'fileutils'

module CV
  # Fetches the BibTeX export for a DBLP author profile and writes/refreshes
  # data/dblp.bib. We keep DBLP entries separate from personal.bib so manual
  # edits in the latter don't get clobbered. Publications.yml can reference
  # keys from either file.
  module DBLP
    DEFAULT_URL = 'https://dblp.org/pid/175/6457.bib'
    OUTPUT      = CV::ROOT.join('dblp.bib')

    module_function

    def fetch(url: DEFAULT_URL, output: OUTPUT)
      uri = URI.parse(url)
      response = Net::HTTP.get_response(uri)
      raise "DBLP fetch failed: #{response.code} #{response.message}" unless response.is_a?(Net::HTTPSuccess)

      FileUtils.mkdir_p(File.dirname(output))
      File.write(output, response.body)
      output
    end
  end
end
